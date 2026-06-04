module axi_slave_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire                    clk,
    input wire                    rst_n,

    // --- AXI4-Lite Write Address Channel ---
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready, // Đổi sang wire để gán liên tục

    // --- AXI4-Lite Write Data Channel ---
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready, // Đổi sang wire để gán liên tục

    // --- AXI4-Lite Write Response Channel ---
    output reg  [1:0]              s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                    s_axi_bready,

    // --- AXI4-Lite Read Address Channel ---
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready, // Đổi sang wire để gán liên tục

    // --- AXI4-Lite Read Data Channel ---
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]              s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                    s_axi_rready,

    // --- Giao tiếp nội bộ (Internal Command Interface) ---
    output reg                    internal_cmd_valid,
    input  wire                    internal_cmd_ready,
    output reg  [ADDR_WIDTH-1:0]  internal_cmd_addr,
    output reg                    internal_cmd_rw,      // 0: Read, 1: Write
    output reg  [DATA_WIDTH-1:0]  internal_wdata,
    input  wire [DATA_WIDTH-1:0]  internal_rdata,
    input  wire                    internal_rdata_valid  
);

    // Thu gọn FSM để xử lý mượt mà hơn
    localparam S_IDLE        = 3'd0,
               S_INT_CMD     = 3'd1,
               S_WRITE_RESP  = 3'd2,
               S_READ_RESP   = 3'd3;

    reg [2:0] state, next_state;

    // Bộ đệm thanh ghi nội bộ để chốt dữ liệu khi bắt tay thành công
    reg [ADDR_WIDTH-1:0] reg_awaddr;
    reg [DATA_WIDTH-1:0] reg_wdata;
    reg                  reg_rw;

    // Gán mạch tổ hợp READY: Sẵn sàng nhận lệnh ngay tại trạng thái IDLE nếu tầng dưới (Scheduler) chưa đầy
    assign s_axi_awready = (state == S_IDLE) && internal_cmd_ready;
    assign s_axi_wready  = (state == S_IDLE) && internal_cmd_ready;
    assign s_axi_arready = (state == S_IDLE) && internal_cmd_ready;

    // Máy trạng thái điều khiển (FSM)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) state <= S_IDLE;
        else        state <= next_state;
    end

    // Logic chuyển trạng thái (Next State Logic)
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                // Chu kỳ ghi hợp lệ khi có ĐỒNG THỜI cả Địa chỉ và Data hợp lệ
                if (s_axi_awvalid && s_axi_wvalid && internal_cmd_ready)
                    next_state = S_INT_CMD;
                // Chu kỳ đọc hợp lệ
                else if (s_axi_arvalid && internal_cmd_ready)
                    next_state = S_INT_CMD;
            end
            
            S_INT_CMD: begin
                // Giữ ở trạng thái này cho đến khi Scheduler nhận lệnh (internal_cmd_ready = 1)
                if (internal_cmd_ready) begin
                    if (reg_rw) next_state = S_WRITE_RESP;
                    else        next_state = S_READ_RESP;
                end
            end
            
            S_WRITE_RESP: begin
                if (s_axi_bready && s_axi_bvalid) next_state = S_IDLE;
            end
            
            S_READ_RESP: begin
                if (s_axi_rready && s_axi_rvalid) next_state = S_IDLE;
            end
            
            default: next_state = S_IDLE;
        endcase
    end

    // Ghi nhận dữ liệu từ các kênh bus AXI và điều khiển ngõ ra lõi
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_bvalid       <= 1'b0;
            s_axi_bresp        <= 2'b00;
            s_axi_rvalid       <= 1'b0;
            s_axi_rdata        <= 0;
            s_axi_rresp        <= 2'b00;
            internal_cmd_valid <= 1'b0;
            internal_cmd_addr  <= 0;
            internal_cmd_rw    <= 1'b0;
            internal_wdata     <= 0;
            reg_awaddr         <= 0;
            reg_wdata          <= 0;
            reg_rw             <= 1'b0;
        end else begin
            case (state)
                S_IDLE: begin
                    // Chốt dữ liệu ngay chu kỳ bắt tay thành công (READY & VALID cùng bằng 1)
                    if (s_axi_awvalid && s_axi_wvalid && s_axi_awready) begin
                        reg_awaddr <= s_axi_awaddr;
                        reg_wdata  <= s_axi_wdata;
                        reg_rw     <= 1'b1; // Đánh dấu lệnh ghi
                    end else if (s_axi_arvalid && s_axi_arready) begin
                        reg_awaddr <= s_axi_araddr;
                        reg_rw     <= 1'b0; // Đánh dấu lệnh đọc
                    end
                end

                S_INT_CMD: begin
                    // Đẩy dữ liệu đã chốt sang tầng Scheduler/Engine
                    internal_cmd_valid <= 1'b1;
                    internal_cmd_addr  <= reg_awaddr;
                    internal_cmd_rw    <= reg_rw;
                    internal_wdata     <= reg_wdata;
                    
                    if (internal_cmd_ready) begin
                        internal_cmd_valid <= 1'b0;
                    end
                end

                S_WRITE_RESP: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00;
                    if (s_axi_bready) s_axi_bvalid <= 1'b0;
                end

                S_READ_RESP: begin
                    if (internal_rdata_valid) begin
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= internal_rdata;
                        s_axi_rresp  <= 2'b00;
                    end
                    if (s_axi_rready && s_axi_rvalid) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule