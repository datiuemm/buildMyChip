#-----Config------

set PRJ_NAME "wb_wdt"
set PRJ_ROOT "../.."
set SRC "$PRJ_ROOT/src/$PRJ_NAME"
set TB "$PRJ_ROOT/tb/$PRJ_NAME"
set DUT "EF_WDT32"

set BUILD_DIR "./output/$DUT/build"
set LOG_DIR   "./output/$DUT/logs"

file mkdir $BUILD_DIR
file mkdir $LOG_DIR

#-----Default mode is REGRESSION--------
if {![info exists mode]} { set mode "regression" }

#-----LIB-------
if [file exists $BUILD_DIR/work] {
    vdel -all -lib $BUILD_DIR/work
}
vlib $BUILD_DIR/work
vmap work $BUILD_DIR/work

vlog -work work \
	$SRC/$DUT/$DUT.v \
	-sv $TB/$DUT/tb_$DUT.sv


if { $mode == "debug" } {
echo "--- RUNNING $DUT IN DEBUG MODE ---"
vsim -voptargs=+acc \
     -l "$LOG_DIR/$DUT.log" \
     work.tb_$DUT 

add wave -position insertpoint  \
sim:/tb_EF_WDT32/dut/clk \
sim:/tb_EF_WDT32/dut/rst_i \
sim:/tb_EF_WDT32/dut/WDTEN \
sim:/tb_EF_WDT32/dut/WDTLOAD \
sim:/tb_EF_WDT32/dut/WDTFEED \
sim:/tb_EF_WDT32/dut/WDTTO \
sim:/tb_EF_WDT32/dut/WDTMR \
sim:/tb_EF_WDT32/dut/rst_n

#add wave -r /*

run -all
} else {
echo "--- RUNNING $DUT IN REGRESSION MODE ---"
vsim -c -voptargs=+acc \
     -l "$LOG_DIR/$DUT.log" \
     work.tb_$DUT 

run -all
quit -f
}
