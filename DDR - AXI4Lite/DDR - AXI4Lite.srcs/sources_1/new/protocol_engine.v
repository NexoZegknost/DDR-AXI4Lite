module protocol_engine (
    input wire clk, 
    input wire rst_n,
    
    // Giao tiếp nội bộ với Scheduler
    input wire        cmd_valid, 
    output reg        cmd_ready,
    input wire [31:0] cmd_addr, 
    input wire        cmd_rw,
    input wire [31:0] cmd_wdata, // THÊM CỔNG NÀY ĐỂ NHẬN DATA GHI TỪ SCHEDULER
    
    // Xử lý Refresh
    input wire        ref_req, 
    output reg        ref_ack,
    
    // Giao tiếp phản hồi Data đọc về AXI Slave Interface
    output reg [31:0] read_data_out,
    output reg        read_data_valid,
    
    // Giao tiếp DRAM
    output reg        mem_cs_n, 
    output reg        mem_ras_n, 
    output reg        mem_cas_n, 
    output reg        mem_we_n,
    output reg [14:0] mem_addr, 
    output reg [2:0]  mem_ba,
    inout  wire [31:0] mem_dq
);

    // Định nghĩa các trạng thái FSM
    localparam STATE_INIT      = 4'd0,
               STATE_IDLE      = 4'd1,
               STATE_ACTIVATE  = 4'd2,
               STATE_READ      = 4'd3,
               STATE_WRITE     = 4'd4,
               STATE_PRECHARGE = 4'd5,
               STATE_REFRESH   = 4'd6;

    reg [3:0] current_state, next_state;
    reg [7:0] timer_reg; 
    reg [7:0] next_timer;

    // Khai báo các lệnh mã hóa của SDRAM/DDR
    localparam CMD_ACT  = 4'b0011,
               CMD_READ = 4'b0101,
               CMD_WRIT = 4'b0100,
               CMD_PRE  = 4'b0010,
               CMD_REF  = 4'b0001,
               CMD_NOP  = 4'b0111;

    // Phân rã địa chỉ
    wire [2:0]  req_bank = cmd_addr[14:12];
    wire [14:0] req_row  = cmd_addr[29:15];
    wire [14:0] req_col  = {3'b000, cmd_addr[11:0]};

    // Cập nhật trạng thái và bộ đếm
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state <= STATE_INIT;
            timer_reg     <= 8'd0;
        end else begin
            current_state <= next_state;
            timer_reg     <= next_timer;
        end
    end

    // Combinational Logic: Tính toán Next State & Timer
    always @(*) begin
        next_state = current_state;
        if (timer_reg > 0) begin
            next_timer = timer_reg - 1'b1;
        end else begin
            next_timer = 8'd0;
        end

        case (current_state)
            STATE_INIT: begin
                next_state = STATE_IDLE;
                next_timer = 8'd0;
            end
            STATE_IDLE: begin
                if (ref_req) begin
                    next_state = STATE_REFRESH;
                    next_timer = 8'd5;
                end else if (cmd_valid) begin
                    next_state = STATE_ACTIVATE;
                    next_timer = 8'd3;
                end
            end
            STATE_ACTIVATE: begin
                if (timer_reg == 8'd0) begin
                    next_state = (cmd_rw) ? STATE_WRITE : STATE_READ;
                    next_timer = 8'd4;
                end
            end
            STATE_READ, STATE_WRITE: begin
                if (timer_reg == 8'd0) begin
                    next_state = STATE_PRECHARGE;
                    next_timer = 8'd3;
                end
            end
            STATE_PRECHARGE: begin
                if (timer_reg == 8'd0) begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_REFRESH: begin
                if (timer_reg == 8'd0) begin
                    next_state = STATE_IDLE;
                end
            end
            default: begin
                next_state = STATE_IDLE;
                next_timer = 8'd0;
            end
        endcase
    end

    // Output Control Logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_NOP;
            mem_addr        <= 15'd0;
            mem_ba          <= 3'd0;
            cmd_ready       <= 1'b0;
            ref_ack         <= 1'b0;
            read_data_out   <= 32'd0;
            read_data_valid <= 1'b0;
        end else begin
            cmd_ready       <= 1'b0;
            ref_ack         <= 1'b0;
            read_data_valid <= 1'b0;
            {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_NOP;

            case (current_state)
                STATE_IDLE: begin
                    if (!ref_req && cmd_valid) cmd_ready <= 1'b1;
                end
                STATE_ACTIVATE: begin
                    if (timer_reg == 8'd3) begin
                        {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_ACT;
                        mem_ba   <= req_bank;
                        mem_addr <= req_row;
                    end
                end
                STATE_READ: begin
                    if (timer_reg == 8'd4) begin
                        {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_READ;
                        mem_ba   <= req_bank;
                        mem_addr <= req_col;
                    end
                    if (timer_reg == 8'd1) begin
                        read_data_out   <= mem_dq; 
                        read_data_valid <= 1'b1;
                    end
                end
                STATE_WRITE: begin
                    if (timer_reg == 8'd4) begin
                        {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_WRIT;
                        mem_ba   <= req_bank;
                        mem_addr <= req_col;
                    end
                end
                STATE_REFRESH: begin
                    if (timer_reg == 8'd5) begin
                        {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_REF;
                        ref_ack <= 1'b1;
                    end
                end
                default: begin
                    {mem_cs_n, mem_ras_n, mem_cas_n, mem_we_n} <= CMD_NOP;
                end
            endcase
        end
    end

   assign mem_dq = (current_state == STATE_WRITE) ? 
                    (cmd_wdata | {32{(^cmd_addr[31:30] & 1'b0)}}) : 32'hZ;

endmodule