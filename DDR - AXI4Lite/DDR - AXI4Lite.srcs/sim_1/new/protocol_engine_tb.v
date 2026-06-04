`timescale 1ns / 1ps

module protocol_engine_tb;

    // --- Khai báo Parameter ---
    parameter ADDR_WIDTH = 32;
    parameter DATA_WIDTH = 32;

    // --- Các tín hiệu Input (Được kích thích bởi Testbench) ---
    reg                    clk;
    reg                    rst_n;
    reg                    cmd_valid;
    reg  [ADDR_WIDTH-1:0]  cmd_addr;
    reg                    cmd_rw;
    reg  [DATA_WIDTH-1:0]  cmd_wdata;
    reg                    ref_req;

    // --- Các tín hiệu Output (Quan sát từ Module) ---
    wire                   cmd_ready;
    wire                   ref_ack;
    wire [DATA_WIDTH-1:0]  read_data_out;
    wire                   read_data_valid;
    
    // Tín hiệu Memory Interface
    wire                   mem_cs_n;
    wire                   mem_ras_n;
    wire                   mem_cas_n;
    wire                   mem_we_n;
    wire [14:0]            mem_addr;
    wire [2:0]             mem_ba;
    wire [DATA_WIDTH-1:0]  mem_dq;

    // --- Khởi tạo Module cần Test (UUT) ---
    protocol_engine uut (
        .clk              (clk),
        .rst_n            (rst_n),
        .cmd_valid        (cmd_valid),
        .cmd_ready        (cmd_ready),
        .cmd_addr         (cmd_addr),
        .cmd_rw           (cmd_rw),
        .cmd_wdata        (cmd_wdata),
        .ref_req          (ref_req),
        .ref_ack          (ref_ack),
        .read_data_out    (read_data_out),
        .read_data_valid  (read_data_valid),
        .mem_cs_n         (mem_cs_n),
        .mem_ras_n        (mem_ras_n),
        .mem_cas_n        (mem_cas_n),
        .mem_we_n         (mem_we_n),
        .mem_addr         (mem_addr),
        .mem_ba           (mem_ba),
        .mem_dq           (mem_dq)
    );

    // --- Tạo xung Clock (Tần số 100MHz -> Chu kỳ 10ns) ---
    always begin
        #5 clk = ~clk;
    end

    // --- Kịch bản kiểm thử (Stimulus Process) ---
    initial begin
        // 1. Khởi tạo trạng thái ban đầu
        clk       = 0;
        rst_n     = 0;
        cmd_valid = 0;
        cmd_rw    = 0;
        cmd_addr  = 0;
        cmd_wdata = 0;
        ref_req   = 0;

        // 2. Kích hoạt Reset hệ thống
        #20;
        rst_n = 1; // Nhấc reset để mạch bắt đầu chạy
        #20;

        // =====================================================================
        // KỊCH BẢN 1: TEST LỆNH GHI (WRITE TRANSACTION)
        // =====================================================================
        $display("[TB] Bat dau kiem tra Lenh Ghi...");
        @(posedge clk);
        #1;
        cmd_addr  = 32'h1234_5678; // Địa chỉ lớn để bẻ bit Row/Bank rõ ràng
        cmd_wdata = 32'hAAAA_BBBB; // Dữ liệu ghi thử
        cmd_rw    = 1'b1;          // 1 đại diện cho lệnh Ghi (Write)
        cmd_valid = 1'b1;          // Bật valid thông báo có lệnh mới

        // Chờ module phản hồi bắt tay thành công (cmd_ready lên 1)
        wait(cmd_ready);
        @(posedge clk);
        #1;
        cmd_valid = 1'b0;          // Hạ valid sau khi đã bắt tay thành công
        
        // Để FSM chạy hết chu kỳ ghi (Activate -> Write -> Precharge -> Idle)
        #100;

        // =====================================================================
        // KỊCH BẢN 2: TEST LỆNH ĐỌC (READ TRANSACTION)
        // =====================================================================
        $display("[TB] Bat dau kiem tra Lenh Doc...");
        @(posedge clk);
        #1;
        cmd_addr  = 32'h1234_5678; 
        cmd_rw    = 1'b0;          // 0 đại diện cho lệnh Đọc (Read)
        cmd_valid = 1'b1;

        wait(cmd_ready);
        @(posedge clk);
        #1;
        cmd_valid = 1'b0;

        // Chờ cho đến khi có dữ liệu đọc hợp lệ phản hồi về
        wait(read_data_valid);
        #100;

        // =====================================================================
        // KỊCH BẢN 3: TEST LỆNH REFRESH TỰ ĐỘNG
        // =====================================================================
        $display("[TB] Bat dau kiem tra Lenh Refresh...");
        @(posedge clk);
        #1;
        ref_req = 1'b1;            // Giả lập Refresh Timer kích hoạt yêu cầu

        // Chờ máy trạng thái xử lý xong lệnh Refresh và báo Ack
        wait(ref_ack);
        @(posedge clk);
        #1;
        ref_req = 1'b0;            // Hạ yêu cầu sau khi được đáp ứng

        #100;
        $display("[TB] Ket thuc mo phong!");
        $finish;
    end

endmodule