#-----Config------

set PRJ_NAME "wb_wdt"
set PRJ_ROOT ".."
set SRC "$PRJ_ROOT/src/$PRJ_NAME"
set TB "$PRJ_ROOT/tb/$PRJ_NAME"
set DUT "EF_WDT32_WB"

set BUILD_DIR "./output/$DUT/build"
set LOG_DIR   "./output/$DUT/logs"

file mkdir $BUILD_DIR
file mkdir $LOG_DIR

#-----Default mode is REGRESSION
if {![info exists mode]} { set mode "regression" }

# Xử lý thư viện
if [file exists $BUILD_DIR/work] {
    vdel -all -lib $BUILD_DIR/work
}
vlib $BUILD_DIR/work
vmap work $BUILD_DIR/work

vlog -work work \
	$SRC/EF_WDT32_WB/$DUT.v \
	$SRC/EF_WDT32/EF_WDT32.v \
	$SRC/EF_WDT32_WB/ef_util_gating_cell_stub.v \
		-sv $TB/EF_WDT32_WB/tb_$DUT.sv


if { $mode == "debug" } {
echo "--- RUNNING $DUT IN DEBUG MODE ---"
vsim -voptargs=+acc \
     -l "$LOG_DIR/$DUT.log" \
     work.tb_$DUT 

#add wave -r /*

add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/clk_i \
sim:/tb_EF_WDT32_WB/rst_i \
sim:/tb_EF_WDT32_WB/adr_i \
sim:/tb_EF_WDT32_WB/dat_i

add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/dut/WDTMR \
sim:/tb_EF_WDT32_WB/dut/WDTLOAD \
sim:/tb_EF_WDT32_WB/dut/WDTTO \
sim:/tb_EF_WDT32_WB/dut/WDTEN \
sim:/tb_EF_WDT32_WB/dut/timer_WIRE \
sim:/tb_EF_WDT32_WB/dut/load_REG \
sim:/tb_EF_WDT32_WB/dut/control_REG

add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/dut/instance_to_wrap/clk \
sim:/tb_EF_WDT32_WB/dut/instance_to_wrap/rst_n

add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/IM_REG_OFFSET \
sim:/tb_EF_WDT32_WB/MIS_REG_OFFSET \
sim:/tb_EF_WDT32_WB/RIS_REG_OFFSET \
sim:/tb_EF_WDT32_WB/IC_REG_OFFSET \
sim:/tb_EF_WDT32_WB/GCLK_REG_OFFSET
add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/IRQ
add wave -position insertpoint  \
sim:/tb_EF_WDT32_WB/dut/WDTTO

run -all
} else {
echo "--- RUNNING $DUT IN REGRESSION MODE ---"
vsim -c -voptargs=+acc \
     -l "$LOG_DIR/$DUT.log" \
     work.tb_$DUT 

run -all
quit -f
}
