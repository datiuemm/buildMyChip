# Tạo thư viện làm việc (nếu chưa có)
if [file exists work] {
    vdel -all
}
vlib work

# 1. Compile các file nguồn
# Lưu ý: wb_ram.v sẽ tự `include wb_common.v
vlog wb_ram.v wb_ram_generic.v wb_ram_tb.v

# 2. Khởi chạy mô phỏng
# -voptargs=+acc giúp giữ lại các tín hiệu để quan sát Waveform
vsim -voptargs=+acc work.wb_ram_tb

# Thêm tất cả tín hiệu vào cửa sổ Wave để quan sát
add wave -r /*

# 3. Chạy toàn bộ thời gian mô phỏng
run -all

# Tự động zoom toàn màn hình Waveform cho dễ nhìn
wave zoom full
