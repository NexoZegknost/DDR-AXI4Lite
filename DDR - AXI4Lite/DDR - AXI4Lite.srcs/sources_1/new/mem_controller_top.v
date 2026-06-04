module mem_controller_top #(
    parameter ADDR_WIDTH = 32,
    parameter DATA_WIDTH = 32
)(
    // --- Clock & Reset ---
    input  wire                    clk,
    input  wire                    rst_n,

    // --- AXI4-Lite Slave Interface (Kết nối tới CPU / System Bus) ---
    // Write Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_awaddr,
    input  wire                    s_axi_awvalid,
    output wire                    s_axi_awready,
    // Write Data Channel
    input  wire [DATA_WIDTH-1:0]   s_axi_wdata,
    input  wire                    s_axi_wvalid,
    output wire                    s_axi_wready,
    // Write Response Channel
    output wire [1:0]              s_axi_bresp,
    output wire                    s_axi_bvalid,
    input  wire                    s_axi_bready,
    // Read Address Channel
    input  wire [ADDR_WIDTH-1:0]   s_axi_araddr,
    input  wire                    s_axi_arvalid,
    output wire                    s_axi_arready,
    // Read Data Channel
    output wire [DATA_WIDTH-1:0]   s_axi_rdata,
    output wire [1:0]              s_axi_rresp,
    output wire                    s_axi_rvalid,
    input  wire                    s_axi_rready,

    // --- Memory Interface (Tín hiệu vật lý điều khiển Chip DRAM / SDRAM) ---
    output wire                    mem_cke,
    output wire                    mem_cs_n,
    output wire                    mem_ras_n,
    output wire                    mem_cas_n,
    output wire                    mem_we_n,
    output wire [14:0]             mem_addr, 
    output wire [2:0]              mem_ba,   
    inout  wire [DATA_WIDTH-1:0]   mem_dq
    );

    // =========================================================================
    // KHAI BÁO CÁC ĐƯỜNG DÂY NỘI BỘ (INTERNAL WIRES) ĐỂ KẾT NỐI MODULES
    // =========================================================================
    
    // 1. Giữa AXI Slave Interface và Command Scheduler
    wire                  axi_to_sch_valid;
    wire                  axi_to_sch_ready;
    wire [ADDR_WIDTH-1:0] axi_to_sch_addr;
    wire                  axi_to_sch_rw;
    wire [DATA_WIDTH-1:0] axi_to_sch_wdata;

    // 2. Giữa Command Scheduler và Protocol Engine
    wire                  sch_to_pet_valid;
    wire                  sch_to_pet_ready;
    wire [ADDR_WIDTH-1:0] sch_to_pet_addr;
    wire                  sch_to_pet_rw;
    wire [DATA_WIDTH-1:0] sch_to_pet_wdata;

    // 3. Đường dữ liệu Đọc phản hồi (Từ Protocol Engine ngược về AXI Slave Interface)
    wire [DATA_WIDTH-1:0] pet_to_axi_rdata;
    wire                  pet_to_axi_rdata_valid;

    // 4. Giữa Refresh Timer và Protocol Engine
    wire                  ref_timer_to_pet_req;
    wire                  pet_to_ref_timer_ack;


    // =========================================================================
    // SƠ ĐỒ ĐẤU NỐI PHÂN CẤP (MODULE INSTANTIATIONS)
    // =========================================================================

    // Cố định chân CKE (Clock Enable) luôn ở mức cao để DRAM hoạt động liên tục
    assign mem_cke = rst_n;

    // 1. Khối Giao Tiếp Bus AXI4-Lite
    axi_slave_interface #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH)
    ) u_axi_slave_interface (
        .clk                  (clk),
        .rst_n                (rst_n),
        // Chân ngoại vi kết nối với bên ngoài Top
        .s_axi_awaddr         (s_axi_awaddr),
        .s_axi_awvalid        (s_axi_awvalid),
        .s_axi_awready        (s_axi_awready),
        .s_axi_wdata          (s_axi_wdata),
        .s_axi_wvalid         (s_axi_wvalid),
        .s_axi_wready         (s_axi_wready),
        .s_axi_bresp          (s_axi_bresp),
        .s_axi_bvalid         (s_axi_bvalid),
        .s_axi_bready         (s_axi_bready),
        .s_axi_araddr         (s_axi_araddr),
        .s_axi_arvalid        (s_axi_arvalid),
        .s_axi_arready        (s_axi_arready),
        .s_axi_rdata          (s_axi_rdata),
        .s_axi_rresp          (s_axi_rresp),
        .s_axi_rvalid         (s_axi_rvalid),
        .s_axi_rready         (s_axi_rready),
        // Chân nội bộ nối sang Scheduler
        .internal_cmd_valid   (axi_to_sch_valid),
        .internal_cmd_ready   (axi_to_sch_ready),
        .internal_cmd_addr    (axi_to_sch_addr),
        .internal_cmd_rw      (axi_to_sch_rw),
        .internal_wdata       (axi_to_sch_wdata),
        // Chân nhận dữ liệu đọc từ Protocol Engine
        .internal_rdata       (pet_to_axi_rdata),
        .internal_rdata_valid (pet_to_axi_rdata_valid)
    );


    // 2. Khối Hàng Đợi Điều Phối Lệnh Thông Minh (Tối ưu Bandwidth / Interleaving)
    cmd_scheduler #(
        .ADDR_WIDTH(ADDR_WIDTH),
        .DATA_WIDTH(DATA_WIDTH),
        .BANK_LSB(12),         // Giả định Bit [14:12] quy định Bank ID trong RAM
        .BANK_WIDTH(3)
    ) u_cmd_scheduler (
        .clk                  (clk),
        .rst_n                (rst_n),
        // Đầu vào: Nhận từ AXI Interface
        .in_cmd_valid         (axi_to_sch_valid),
        .in_cmd_ready         (axi_to_sch_ready),
        .in_cmd_addr          (axi_to_sch_addr),
        .in_cmd_rw            (axi_to_sch_rw),
        .in_wdata             (axi_to_sch_wdata),
        // Đầu ra: Đẩy sang Protocol Engine
        .out_cmd_valid        (sch_to_pet_valid),
        .out_cmd_ready        (sch_to_pet_ready),
        .out_cmd_addr         (sch_to_pet_addr),
        .out_cmd_rw           (sch_to_pet_rw),
        .out_wdata            (sch_to_pet_wdata)
    );


    // 3. Khối Đếm Định Thời Kích Hoạt Refresh
    refresh_timer #(
        .REFRESH_LIMIT(16'd780) // Tự động kích hoạt sau mỗi 7.8us với clock 100MHz
    ) u_refresh_timer (
        .clk                  (clk),
        .rst_n                (rst_n),
        .ref_req              (ref_timer_to_pet_req),
        .ref_ack              (pet_to_ref_timer_ack)
    );


    // 4. Khối Máy Trạng Thái Điều Khiển Vật Lý (Trái tim điều khiển định thời DRAM)
    protocol_engine u_protocol_engine (
        .clk                  (clk),
        .rst_n                (rst_n),
        .cmd_valid            (sch_to_pet_valid),
        .cmd_ready            (sch_to_pet_ready),
        .cmd_addr             (sch_to_pet_addr),
        .cmd_rw               (sch_to_pet_rw),
        .cmd_wdata            (sch_to_pet_wdata), // ĐẤU NỐI THÊM ĐƯỜNG NÀY VÀO ĐÂY!
        
        .ref_req              (ref_timer_to_pet_req),
        .ref_ack              (pet_to_ref_timer_ack),
        .read_data_out        (pet_to_axi_rdata),
        .read_data_valid      (pet_to_axi_rdata_valid),
        
        .mem_cs_n             (mem_cs_n),
        .mem_ras_n            (mem_ras_n),
        .mem_cas_n            (mem_cas_n),
        .mem_we_n             (mem_we_n),
        .mem_addr             (mem_addr),
        .mem_ba               (mem_ba),
        .mem_dq               (mem_dq)
    );

endmodule