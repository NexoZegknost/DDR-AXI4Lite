`timescale 1ns / 1ps

module mem_controller_tb;

    // --- Các tham số hệ thống ---
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;
    parameter CLK_PERIOD = 10; // 10ns = 100MHz

    // --- Tín hiệu Testbench ---
    reg                    clk;
    reg                    rst_n;

    // AXI Write Address Channel
    reg [ADDR_WIDTH-1:0]   s_axi_awaddr;
    reg                    s_axi_awvalid;
    wire                   s_axi_awready;
    // AXI Write Data Channel
    reg [DATA_WIDTH-1:0]   s_axi_wdata;
    reg                    s_axi_wvalid;
    wire                   s_axi_wready;
    // AXI Write Response Channel
    wire [1:0]             s_axi_bresp;
    wire                   s_axi_bvalid;
    reg                    s_axi_bready;
    // AXI Read Address Channel
    reg [ADDR_WIDTH-1:0]   s_axi_araddr;
    reg                    s_axi_arvalid;
    wire                   s_axi_arready;
    // AXI Read Data Channel
    wire [DATA_WIDTH-1:0]  s_axi_rdata;
    wire [1:0]             s_axi_rresp;
    wire                   s_axi_rvalid;
    reg                    s_axi_rready;

    // Chân ngoại vi DRAM
    wire                   mem_cke;
    wire                   mem_cs_n;
    wire                   mem_ras_n;
    wire                   mem_cas_n;
    wire                   mem_we_n;
    wire [14:0]            mem_addr;
    wire [2:0]             mem_ba;
    wire [DATA_WIDTH-1:0]  mem_dq;

    // Biến tạo dữ liệu giả lập cho bus hai chiều mem_dq lúc ĐỌC
    reg [DATA_WIDTH-1:0]   mem_dq_drive;
    reg                    drive_en;
    assign mem_dq = drive_en ? mem_dq_drive : {DATA_WIDTH{1'bZ}};

    // --- KẾT NỐI VÀO MODULE TOP (UUT) ---
    mem_controller_top #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) uut (
        .clk(clk), .rst_n(rst_n),
        .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid), .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata), .s_axi_wvalid(s_axi_wvalid), .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp), .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid), .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata), .s_axi_rresp(s_axi_rresp), .s_axi_rvalid(s_axi_rvalid), .s_axi_rready(s_axi_rready),
        .mem_cke(mem_cke), .mem_cs_n(mem_cs_n), .mem_ras_n(mem_ras_n), .mem_cas_n(mem_cas_n), .mem_we_n(mem_we_n),
        .mem_addr(mem_addr), .mem_ba(mem_ba), .mem_dq(mem_dq)
    );

    // --- Tạo xung nhịp Clock ---
    always #(CLK_PERIOD/2) clk = ~clk;

    // --- Kịch bản kiểm thử (Test Stimulus) ---
    initial begin
        // Khởi tạo trạng thái ban đầu
        clk = 0;
        rst_n = 0;
        drive_en = 0;
        mem_dq_drive = 0;
        s_axi_awaddr = 0; s_axi_awvalid = 0;
        s_axi_wdata = 0;  s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0; s_axi_arvalid = 0;
        s_axi_rready = 0;

        // Reset hệ thống trong 5 chu kỳ
        #(CLK_PERIOD*5);
        rst_n = 1;
        #(CLK_PERIOD*2);

        $display("[TB] --- BẮT ĐẦU KỊCH BẢN KIỂM THỬ GIAO TIẾP AXI-ILMC ---");

        // =====================================================================
        // KỊCH BẢN 1: GHI DỮ LIỆU ĐỒNG BỘ CHUẨN XUNG NHỊP (BẮT BUỘC QUA SƯỜN DƯƠNG)
        // =====================================================================
        $display("[TB] Chạy Kịch bản 1: Ghi dữ liệu 32'hAAAA_BBBB vào Bank 0");
        
        // Bước 1: Chờ sườn dương clock để thiết lập dữ liệu đầu vào ổn định
        @(posedge clk);
        #1; // Neo dữ liệu sau sườn dương 1ns để tránh xung đột thời gian
        s_axi_awaddr  = 32'h1234_5678;
        s_axi_wdata   = 32'hAAAA_BBBB;
        s_axi_bready  = 1'b1;
        
        // Bước 2: Dựng cờ VALID lên cao
        s_axi_awvalid = 1'b1;
        s_axi_wvalid  = 1'b1;

        // Bước 3: ÉP Testbench giữ VALID bằng 1 trong ít nhất 2 chu kỳ clock đầy đủ.
        // Điều này đảm bảo xung VALID sẽ đi qua ít nhất một sườn dương (posedge clk) 
        // lúc mà READY đang bằng 1.
        wait (s_axi_awready && s_axi_wready);

        // Sau 2 chu kỳ, chắc chắn việc bắt tay đã hoàn tất, hạ VALID xuống
        @(posedge clk);
        #1;
        s_axi_awvalid = 1'b0;
        s_axi_wvalid  = 1'b0;

        $display("[TB] Đã truyền xong lệnh qua cửa ngõ AXI. Chờ Controller xử lý...");

        // Bước 4: Chờ phản hồi hoàn thành chu kỳ ghi (BVALID) từ Controller
        // Tăng thời gian chờ lên để máy trạng thái kịp chạy qua ACTIVATE -> WRITE -> PRECHARGE
        #(CLK_PERIOD * 30); 
        
        s_axi_bready = 1'b0;
        $display("[TB] Kịch bản 1 hoàn thành.");

        #(CLK_PERIOD*20); // Chờ để xem FSM nhảy trạng thái và mem_addr xuất hiện

        // =====================================================================
        // KỊCH BẢN 2: KIỂM TRA THUẬT TOÁN BANK INTERLEAVING (Xếp hàng thông minh)
        // Đẩy liên tục 2 lệnh Đọc vào hàng đợi:
        //   - Lệnh A: Đọc Bank 0 (Trùng với Bank vừa truy cập) -> Địa chỉ: 32'h0000_0000
        //   - Lệnh B: Đọc Bank 2 (Khác Bank)                 -> Địa chỉ: 32'h0000_2000 (Bit 13=1)
        // KỲ VỌNG: Scheduler phải "bốc" Lệnh B đi trước Lệnh A để tối ưu thời gian.
        // =====================================================================
        $display("[TB] Chạy Kịch bản 2: Kiểm thử tính năng tối ưu Bank Interleaving");
        
        // Nạp Lệnh A (Đọc Bank 0)
        @(posedge clk);
        s_axi_araddr  = 32'h0000_0000;
        s_axi_arvalid = 1'b1;
        s_axi_rready  = 1'b1;
        wait(s_axi_arready);
        #(CLK_PERIOD);
        s_axi_arvalid = 1'b0;

        // Nạp liền Lệnh B (Đọc Bank 2)
        @(posedge clk);
        s_axi_araddr  = 32'h0000_2000; 
        s_axi_arvalid = 1'b1;
        wait(s_axi_arready);
        #(CLK_PERIOD);
        s_axi_arvalid = 1'b0;

        // Giả lập chip RAM trả dữ liệu về khi phát hiện trạng thái STATE_READ
        // Bạn sẽ quan sát thấy tín hiệu mem_ba thay đổi sang Bank 2 trước Bank 0 trên đồ thị sóng!
        wait(uut.u_protocol_engine.current_state == 4'd3); // STATE_READ
        drive_en = 1;
        mem_dq_drive = 32'h5555_6666; // Trả về data giả lập
        wait(s_axi_rvalid);
        #(CLK_PERIOD);
        drive_en = 0;

        // =====================================================================
        // KỊCH BẢN 3: CHỜ XEM LỆNH REFRESH TỰ ĐỘNG
        // Chúng ta sẽ cho thời gian chạy tự do để xem bộ đếm refresh_timer 
        // kích hoạt lệnh REFRESH (STATE_REFRESH = 4'd6) lên Protocol Engine.
        // =====================================================================
        $display("[TB] Chạy Kịch bản 3: Theo dõi chu kỳ Tự động Refresh...");
        #(CLK_PERIOD * 800); // Chạy vượt ngưỡng REFRESH_LIMIT (780 chu kỳ)

        $display("[TB] --- MÔ PHỎNG HOÀN TẤT ---");
        $finish;
    end

endmodule