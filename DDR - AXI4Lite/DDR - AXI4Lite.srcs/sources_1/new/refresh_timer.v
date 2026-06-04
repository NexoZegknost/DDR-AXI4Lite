module refresh_timer #(
    // Giả sử tần số Clock hệ thống cấp cho Controller là 100MHz (Chu kỳ 10ns)
    // Để đạt được khoảng thời gian refresh 7.8us: 7800ns / 10ns = 780 chu kỳ xung nhịp.
    parameter REFRESH_LIMIT = 16'd780 
)(
    input wire  clk,
    input wire  rst_n,
    output reg  ref_req,   // Gửi yêu cầu Refresh tới Protocol Engine
    input wire  ref_ack    // Phản hồi từ Protocol Engine báo đã thực hiện xong lệnh Refresh
);

    reg [15:0] count_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count_reg <= 16'd0;
            ref_req   <= 1'b0;
        end else begin
            
            // 1. Bộ đếm chu kỳ thời gian chạy liên tục độc lập
            if (count_reg >= REFRESH_LIMIT - 1) begin
                count_reg <= 16'd0;
            end else begin
                count_reg <= count_reg + 1'b1;
            end

            // 2. Logic tạo và giữ cờ yêu cầu (Request Flags)
            if (count_reg >= REFRESH_LIMIT - 1) begin
                ref_req <= 1'b1; // Đạt ngưỡng thời gian, bật yêu cầu Refresh lên
            end else if (ref_ack) begin
                ref_req <= 1'b0; // Khi Protocol Engine bắt đầu xử lý, hạ cờ yêu cầu xuống
            end
            
        end
    end

endmodule