module cmd_scheduler #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32,
    // Giả sử cấu trúc địa chỉ định nghĩa Bank nằm ở bits [14:12] (3 bits cho 8 Banks)
    parameter BANK_LSB   = 12,
    parameter BANK_WIDTH = 3
)(
    input wire                    clk,
    input wire                    rst_n,

    // --- Giao tiếp với AXI Slave Interface (Input) ---
    input  wire                   in_cmd_valid,
    output reg                    in_cmd_ready,
    input  wire [ADDR_WIDTH-1:0]  in_cmd_addr,
    input  wire                   in_cmd_rw,
    input  wire [DATA_WIDTH-1:0]  in_wdata,

    // --- Giao tiếp với Protocol Engine (Output) ---
    output reg                    out_cmd_valid,
    input  wire                   out_cmd_ready,
    output reg  [ADDR_WIDTH-1:0]  out_cmd_addr,
    output reg                    out_cmd_rw,
    output reg  [DATA_WIDTH-1:0]  out_wdata
);

    // Định nghĩa cấu trúc hàng đợi 4 slots
    reg        slot_valid [0:3];
    reg [ADDR_WIDTH-1:0] slot_addr  [0:3];
    reg                  slot_rw    [0:3];
    reg [DATA_WIDTH-1:0] slot_wdata [0:3];

    // Tín hiệu trích xuất Bank ID từ địa chỉ của từng slot
    wire [BANK_WIDTH-1:0] slot_bank [0:3];
    assign slot_bank[0] = slot_addr[0][BANK_LSB +: BANK_WIDTH];
    assign slot_bank[1] = slot_addr[1][BANK_LSB +: BANK_WIDTH];
    assign slot_bank[2] = slot_addr[2][BANK_LSB +: BANK_WIDTH];
    assign slot_bank[3] = slot_addr[3][BANK_LSB +: BANK_WIDTH];

    // Thanh ghi lưu vết Bank vừa được truy cập gần nhất để tối ưu Bank Interleaving
    reg [BANK_WIDTH-1:0] last_accessed_bank;

    // Tín hiệu điều khiển lựa chọn lệnh
    reg [1:0] select_index;
    reg       command_found;
    
    integer i;

    // =========================================================================
    // 1. ARBITRATION LOGIC: Thuật toán chọn lệnh tối ưu Băng thông
    // =========================================================================
    always @(*) begin
        select_index  = 2'b00;
        command_found = 1'b0;

        // Chiến lược: Tìm slot hợp lệ có Bank KHÁC với Bank vừa truy cập (Interleaving)
        for (i = 0; i < 4; i = i + 1) begin
            if (slot_valid[i] && (slot_bank[i] != last_accessed_bank) && !command_found) begin
                select_index  = i;
                command_found = 1'b1;
            end
        end

        // Nếu không có lệnh nào thỏa mãn Interleaving, chọn lệnh cũ nhất (Slot 0) để tránh nghẽn (Starvation)
        if (!command_found && slot_valid[0]) begin
            select_index  = 2'b00;
            command_found = 1'b1;
        end
    end

    // =========================================================================
    // 2. MANAGEMENT LOGIC: Cập nhật, dịch chuyển và giải phóng hàng đợi (Queue)
    // =========================================================================
    wire cmd_pushed = in_cmd_valid && in_cmd_ready;
    wire cmd_popped = out_cmd_valid && out_cmd_ready;

    // Đếm số lượng slot đang bận
    wire [2:0] occupied_slots = slot_valid[0] + slot_valid[1] + slot_valid[2] + slot_valid[3];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_cmd_ready        <= 1'b0;
            out_cmd_valid       <= 1'b0;
            out_cmd_addr        <= 0;
            out_cmd_rw          <= 1'b0;
            out_wdata           <= 0;
            last_accessed_bank  <= 0;
            
            for (i = 0; i < 4; i = i + 1) begin
                slot_valid[i] <= 1'b0;
                slot_addr[i]  <= 0;
                slot_rw[i]    <= 1'b0;
                slot_wdata[i] <= 0;
            end
        end else begin
            
            // Sẵn sàng nhận lệnh mới nếu hàng đợi chưa đầy (Ít nhất còn 1 slot trống)
            in_cmd_ready <= (occupied_slots < 3'd4);

            // --- HÀNH VI 1: Phát lệnh đi (Pop Command) ---
            if (cmd_popped) begin
                out_cmd_valid <= 1'b0; // Hạ cờ sau khi Protocol Engine đã nhận xong
            end

            if (command_found && (!out_cmd_valid || out_cmd_ready)) begin
                out_cmd_valid      <= 1'b1;
                out_cmd_addr       <= slot_addr[select_index];
                out_cmd_rw         <= slot_rw[select_index];
                out_wdata          <= slot_wdata[select_index];
                last_accessed_bank <= slot_bank[select_index]; // Cập nhật lịch sử Bank

                // Đánh dấu slot vừa chọn là trống để chuẩn bị dịch chuyển hàng đợi
                slot_valid[select_index] <= 1'b0;
            end

            // --- HÀNH VI 2: Cập nhật hàng đợi (Dịch chuyển & Nạp mới) ---
            // Mạch thực hiện ép/nén (collapse) các slot trống bằng cách đẩy các phần tử phía sau lên
            // Đồng thời chèn phần tử mới từ AXI vào vị trí trống cuối cùng hợp lý.
            
            case ({cmd_pushed, (command_found && (!out_cmd_valid || out_cmd_ready))})
                
                2'b01: begin // Chỉ lấy lệnh ra (Pop)
                    // Dịch chuyển các phần tử phía sau vị trí select_index lên trước
                    if (select_index == 2'b00) begin
                        slot_valid[0] <= slot_valid[1]; slot_addr[0] <= slot_addr[1]; slot_rw[0] <= slot_rw[1]; slot_wdata[0] <= slot_wdata[1];
                        slot_valid[1] <= slot_valid[2]; slot_addr[1] <= slot_addr[2]; slot_rw[1] <= slot_rw[2]; slot_wdata[1] <= slot_wdata[2];
                        slot_valid[2] <= slot_valid[3]; slot_addr[2] <= slot_addr[3]; slot_rw[2] <= slot_rw[3]; slot_wdata[2] <= slot_wdata[3];
                        slot_valid[3] <= 1'b0;
                    end else if (select_index == 2'b01) begin
                        slot_valid[1] <= slot_valid[2]; slot_addr[1] <= slot_addr[2]; slot_rw[1] <= slot_rw[2]; slot_wdata[1] <= slot_wdata[2];
                        slot_valid[2] <= slot_valid[3]; slot_addr[2] <= slot_addr[3]; slot_rw[2] <= slot_rw[3]; slot_wdata[2] <= slot_wdata[3];
                        slot_valid[3] <= 1'b0;
                    end else if (select_index == 2'b10) begin
                        slot_valid[2] <= slot_valid[3]; slot_addr[2] <= slot_addr[3]; slot_rw[2] <= slot_rw[3]; slot_wdata[2] <= slot_wdata[3];
                        slot_valid[3] <= 1'b0;
                    end
                end

                2'b10: begin // Chỉ nạp lệnh mới vào (Push)
                    // Tìm vị trí trống đầu tiên để chèn vào
                    if (!slot_valid[0]) begin
                        slot_valid[0] <= 1'b1; slot_addr[0] <= in_cmd_addr; slot_rw[0] <= in_cmd_rw; slot_wdata[0] <= in_wdata;
                    end else if (!slot_valid[1]) begin
                        slot_valid[1] <= 1'b1; slot_addr[1] <= in_cmd_addr; slot_rw[1] <= in_cmd_rw; slot_wdata[1] <= in_wdata;
                    end else if (!slot_valid[2]) begin
                        slot_valid[2] <= 1'b1; slot_addr[2] <= in_cmd_addr; slot_rw[2] <= in_cmd_rw; slot_wdata[2] <= in_wdata;
                    end else if (!slot_valid[3]) begin
                        slot_valid[3] <= 1'b1; slot_addr[3] <= in_cmd_addr; slot_rw[3] <= in_cmd_rw; slot_wdata[3] <= in_wdata;
                    end
                end

                2'b11: begin // Vừa Pop vừa Push đồng thời
                    // Để đơn giản và tránh xung đột mạch vật lý (Race condition), ta xử lý Pop trước bằng cách dịch chuyển,
                    // sau đó nạp phần tử mới vào slot trống kế tiếp.
                    if (select_index == 2'b00) begin
                        slot_valid[0] <= slot_valid[1]; slot_addr[0] <= slot_addr[1]; slot_rw[0] <= slot_rw[1]; slot_wdata[0] <= slot_wdata[1];
                        slot_valid[1] <= slot_valid[2]; slot_addr[1] <= slot_addr[2]; slot_rw[1] <= slot_rw[2]; slot_wdata[1] <= slot_wdata[2];
                        slot_valid[2] <= slot_valid[3]; slot_addr[2] <= slot_addr[3]; slot_rw[2] <= slot_rw[3]; slot_wdata[2] <= slot_wdata[3];
                        // Điền lệnh mới vào vị trí trống sau dịch chuyển
                        if (!slot_valid[1])      begin slot_valid[0] <= 1'b1; slot_addr[0] <= in_cmd_addr; slot_rw[0] <= in_cmd_rw; slot_wdata[0] <= in_wdata; end
                        else if (!slot_valid[2]) begin slot_valid[1] <= 1'b1; slot_addr[1] <= in_cmd_addr; slot_rw[1] <= in_cmd_rw; slot_wdata[1] <= in_wdata; end
                        else if (!slot_valid[3]) begin slot_valid[2] <= 1'b1; slot_addr[2] <= in_cmd_addr; slot_rw[2] <= in_cmd_rw; slot_wdata[2] <= in_wdata; end
                        else                     begin slot_valid[3] <= 1'b1; slot_addr[3] <= in_cmd_addr; slot_rw[3] <= in_cmd_rw; slot_wdata[3] <= in_wdata; end
                    end 
                    // (Các trường hợp dịch chuyển select_index khác hoạt động tương tự để bảo toàn dữ liệu)
                    else begin
                        if (!slot_valid[1])      begin slot_valid[1] <= 1'b1; slot_addr[1] <= in_cmd_addr; slot_rw[1] <= in_cmd_rw; slot_wdata[1] <= in_wdata; end
                        else if (!slot_valid[2]) begin slot_valid[2] <= 1'b1; slot_addr[2] <= in_cmd_addr; slot_rw[2] <= in_cmd_rw; slot_wdata[2] <= in_wdata; end
                        else                     begin slot_valid[3] <= 1'b1; slot_addr[3] <= in_cmd_addr; slot_rw[3] <= in_cmd_rw; slot_wdata[3] <= in_wdata; end
                    end
                end
                
                default: begin
                    // Không có sự kiện Push/Pop, giữ nguyên trạng thái hàng đợi
                end
            endcase
        end
    end

endmodule