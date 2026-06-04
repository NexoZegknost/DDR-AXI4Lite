module axi_slave_interface #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    input wire                    clk,
    input wire                    rst_n,

    // --- AXI4-Lite Write Address Channel ---
    input  wire [ADDR_WIDTH-1:0]  s_axi_awaddr,
    input  wire                   s_axi_awvalid,
    output reg                    s_axi_awready,

    // --- AXI4-Lite Write Data Channel ---
    input  wire [DATA_WIDTH-1:0]  s_axi_wdata,
    input  wire                   s_axi_wvalid,
    output reg                    s_axi_wready,

    // --- AXI4-Lite Write Response Channel ---
    output reg  [1:0]             s_axi_bresp,
    output reg                    s_axi_bvalid,
    input  wire                   s_axi_bready,

    // --- AXI4-Lite Read Address Channel ---
    input  wire [ADDR_WIDTH-1:0]  s_axi_araddr,
    input  wire                   s_axi_arvalid,
    output reg                    s_axi_arready,

    // --- AXI4-Lite Read Data Channel ---
    output reg  [DATA_WIDTH-1:0]  s_axi_rdata,
    output reg  [1:0]             s_axi_rresp,
    output reg                    s_axi_rvalid,
    input  wire                   s_axi_rready,

    // --- Giao tiếp nội bộ (Internal Command Interface) ---
    output reg                    internal_cmd_valid,
    input  wire                   internal_cmd_ready,
    output reg  [ADDR_WIDTH-1:0]  internal_cmd_addr,
    output reg                    internal_cmd_rw,      // 0: Read, 1: Write
    output reg  [DATA_WIDTH-1:0]  internal_wdata,
    input  wire [DATA_WIDTH-1:0]  internal_rdata,
    input  wire                   internal_rdata_valid  // Phản hồi data đọc từ DRAM về
);

    // Định nghĩa các trạng thái FSM điều khiển AXI
    localparam S_IDLE        = 3'd0,
               S_WRITE_DATA  = 3'd1,
               S_INT_CMD     = 3'd2,
               S_WRITE_RESP  = 3'd3,
               S_READ_RESP   = 3'd4;

    reg [2:0] state, next_state;

    // Máy trạng thái điều khiển (FSM)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= S_IDLE;
        else        
            state <= next_state;
    end

    // Logic chuyển trạng thái tiếp theo
    always @(*) begin
        next_state = state;
        case (state)
            S_IDLE: begin
                if (s_axi_awvalid)      next_state = S_WRITE_DATA; // Ưu tiên xử lý Ghi (Write)
                else if (s_axi_arvalid) next_state = S_INT_CMD;    // Xử lý Đọc (Read)
            end
            S_WRITE_DATA: begin
                if (s_axi_wvalid)       next_state = S_INT_CMD;    // Nhận đủ data ghi thì đẩy vào lõi
            end
            S_INT_CMD: begin
                if (internal_cmd_ready) begin
                    if (internal_cmd_rw) next_state = S_WRITE_RESP;
                    else                 next_state = S_READ_RESP;
                end
            end
            S_WRITE_RESP: begin
                if (s_axi_bready)       next_state = S_IDLE;       // Hoàn thành chu kỳ Ghi
            end
            S_READ_RESP: begin
                if (internal_rdata_valid && s_axi_rready) next_state = S_IDLE; // Hoàn thành chu kỳ Đọc
            end
            default: next_state = S_IDLE;
        endcase
    end

    // Logic điều khiển tín hiệu ngõ ra (Output Logic)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready      <= 1'b0;
            s_axi_wready       <= 1'b0;
            s_axi_bvalid       <= 1'b0;
            s_axi_bresp        <= 2'b00;
            s_axi_arready      <= 1'b0;
            s_axi_rvalid       <= 1'b0;
            s_axi_rdata        <= 0;
            s_axi_rresp        <= 2'b00;
            internal_cmd_valid <= 1'b0;
            internal_cmd_addr  <= 0;
            internal_cmd_rw    <= 1'b0;
            internal_wdata     <= 0;
        end else begin
            case (state)
                S_IDLE: begin
                    s_axi_bvalid  <= 1'b0;
                    s_axi_rvalid  <= 1'b0;
                    if (s_axi_awvalid) begin
                        s_axi_awready     <= 1'b1;
                        internal_cmd_addr <= s_axi_awaddr;
                        internal_cmd_rw   <= 1'b1; // Lệnh Ghi
                    end else if (s_axi_arvalid) begin
                        s_axi_arready     <= 1'b1;
                        internal_cmd_addr <= s_axi_araddr;
                        internal_cmd_rw   <= 1'b0; // Lệnh Đọc
                    end
                end

                S_WRITE_DATA: begin
                    s_axi_awready <= 1'b0;
                    s_axi_wready  <= 1'b1;
                    if (s_axi_wvalid) begin
                        internal_wdata <= s_axi_wdata;
                    end
                end

                S_INT_CMD: begin
                    s_axi_wready       <= 1'b0;
                    s_axi_arready      <= 1'b0;
                    internal_cmd_valid <= 1'b1; // Phát lệnh vào hàng đợi / protocol engine
                    if (internal_cmd_ready) begin
                        internal_cmd_valid <= 1'b0;
                    end
                end

                S_WRITE_RESP: begin
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00; // Trả về mã OKAY
                    if (s_axi_bready) s_axi_bvalid <= 1'b0;
                end

                S_READ_RESP: begin
                    if (internal_rdata_valid) begin
                        s_axi_rvalid <= 1'b1;
                        s_axi_rdata  <= internal_rdata;
                        s_axi_rresp  <= 2'b00; // Trả về mã OKAY
                    end
                    if (s_axi_rvalid && s_axi_rready) begin
                        s_axi_rvalid <= 1'b0;
                    end
                end
            endcase
        end
    end

endmodule