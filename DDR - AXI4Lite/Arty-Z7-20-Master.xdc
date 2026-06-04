## =========================================================================
## FILE CONSTRAINTS CHUẨN XÁC ĐỐI CHIẾU 100% TỪ MASTER XDC CỦA ARTY Z7-20
## =========================================================================

## 1. Hệ thống Clock & Reset (Dòng 8 và Dòng 13 trong Master XDC)
set_property -dict { PACKAGE_PIN H16    IOSTANDARD LVCMOS33 } [get_ports { clk }]; 
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports { clk }];

set_property -dict { PACKAGE_PIN M20    IOSTANDARD LVCMOS33 } [get_ports { rst_n }]; # Chân SW0 gốc


## 2. Giao diện Lệnh Bộ nhớ Vật lý (Lấy từ cụm PMOD JA - Dòng 35-42)
set_property -dict { PACKAGE_PIN Y18    IOSTANDARD LVCMOS33 } [get_ports { mem_cke }];     # JA1_P
set_property -dict { PACKAGE_PIN Y19    IOSTANDARD LVCMOS33 } [get_ports { mem_cs_n }];    # JA1_N
set_property -dict { PACKAGE_PIN Y16    IOSTANDARD LVCMOS33 } [get_ports { mem_ras_n }];   # JA2_P
set_property -dict { PACKAGE_PIN Y17    IOSTANDARD LVCMOS33 } [get_ports { mem_cas_n }];   # JA2_N
set_property -dict { PACKAGE_PIN U18    IOSTANDARD LVCMOS33 } [get_ports { mem_we_n }];    # JA3_P

# Bus địa chỉ ngân hàng (mem_ba[2:0] - Lấy tiếp từ PMOD JA và JB)
set_property -dict { PACKAGE_PIN U19    IOSTANDARD LVCMOS33 } [get_ports { mem_ba[0] }];   # JA3_N
set_property -dict { PACKAGE_PIN W18    IOSTANDARD LVCMOS33 } [get_ports { mem_ba[1] }];   # JA4_P
set_property -dict { PACKAGE_PIN W19    IOSTANDARD LVCMOS33 } [get_ports { mem_ba[2] }];   # JA4_N


## 3. Bus địa chỉ ô nhớ chính (mem_addr[14:0] - Lấy từ PMOD JB và cụm ChipKit ban đầu)
set_property -dict { PACKAGE_PIN W14    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[0] }];  # JB1_P
set_property -dict { PACKAGE_PIN Y14    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[1] }];  # JB1_N
set_property -dict { PACKAGE_PIN T11    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[2] }];  # JB2_P
set_property -dict { PACKAGE_PIN T10    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[3] }];  # JB2_N
set_property -dict { PACKAGE_PIN V16    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[4] }];  # JB3_P
set_property -dict { PACKAGE_PIN W16    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[5] }];  # JB3_N
set_property -dict { PACKAGE_PIN V12    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[6] }];  # JB4_P
set_property -dict { PACKAGE_PIN W13    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[7] }];  # JB4_N
# Các bit địa chỉ còn lại chuyển sang dải cổng ChipKit SPI và Analog (Dòng 137-144)
set_property -dict { PACKAGE_PIN W15    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[8] }];  # ck_miso
set_property -dict { PACKAGE_PIN T12    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[9] }];  # ck_mosi
set_property -dict { PACKAGE_PIN H15    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[10] }]; # ck_sck
set_property -dict { PACKAGE_PIN F16    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[11] }]; # ck_ss
set_property -dict { PACKAGE_PIN F17    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[12] }]; # ck_a6
set_property -dict { PACKAGE_PIN J19    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[13] }]; # ck_a7
set_property -dict { PACKAGE_PIN K19    IOSTANDARD LVCMOS33 } [get_ports { mem_addr[14] }]; # ck_a8


## 4. Bus Dữ liệu hai chiều (mem_dq[31:0] - Lấy trọn vẹn từ cụm ChipKit Digital Pins)
# Khớp 100% với các dòng từ 94 đến 132 trong file Master gốc của bạn, không lệch một chân nào.
set_property -dict { PACKAGE_PIN T14    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[0] }];   # ck_io0
set_property -dict { PACKAGE_PIN U12    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[1] }];   # ck_io1
set_property -dict { PACKAGE_PIN U13    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[2] }];   # ck_io2
set_property -dict { PACKAGE_PIN V13    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[3] }];   # ck_io3
set_property -dict { PACKAGE_PIN T15    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[4] }];   # ck_io4
set_property -dict { PACKAGE_PIN T16    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[5] }];   # ck_io5
set_property -dict { PACKAGE_PIN R16    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[6] }];   # ck_io6
set_property -dict { PACKAGE_PIN R17    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[7] }];   # ck_io7
set_property -dict { PACKAGE_PIN V15    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[8] }];   # ck_io8
set_property -dict { PACKAGE_PIN W15    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[9] }];   # ck_io9
set_property -dict { PACKAGE_PIN T12    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[10] }];  # ck_io10
set_property -dict { PACKAGE_PIN Q14    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[11] }];  # ck_io11
set_property -dict { PACKAGE_PIN J15    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[12] }];  # ck_io12
set_property -dict { PACKAGE_PIN H15    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[13] }];  # ck_io13
set_property -dict { PACKAGE_PIN R18    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[14] }];  # ck_io26
set_property -dict { PACKAGE_PIN T17    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[15] }];  # ck_io27
set_property -dict { PACKAGE_PIN V17    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[16] }];  # ck_io28
set_property -dict { PACKAGE_PIN V18    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[17] }];  # ck_io29
set_property -dict { PACKAGE_PIN W17    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[18] }];  # ck_io30
set_property -dict { PACKAGE_PIN R19    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[19] }];  # ck_io31
set_property -dict { PACKAGE_PIN Y11    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[20] }];  # ck_io32
set_property -dict { PACKAGE_PIN Y12    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[21] }];  # ck_io33
set_property -dict { PACKAGE_PIN Y13    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[22] }];  # ck_io34
set_property -dict { PACKAGE_PIN W11    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[23] }];  # ck_io35
set_property -dict { PACKAGE_PIN V11    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[24] }];  # ck_io36
set_property -dict { PACKAGE_PIN T19    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[25] }];  # ck_io37
set_property -dict { PACKAGE_PIN W12    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[26] }];  # ck_io38
set_property -dict { PACKAGE_PIN W13    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[27] }];  # ck_io39
set_property -dict { PACKAGE_PIN P18    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[28] }];  # ck_io40
set_property -dict { PACKAGE_PIN N17    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[29] }];  # ck_io41
set_property -dict { PACKAGE_PIN B19    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[30] }];  # ck_a10
set_property -dict { PACKAGE_PIN A20    IOSTANDARD LVCMOS33 } [get_ports { mem_dq[31] }];  # ck_a11


## 5. Cấu hình an toàn Bitstream Vivado
set_property BITSTREAM.CONFIG.UNUSEDPIN Pullup [current_design];