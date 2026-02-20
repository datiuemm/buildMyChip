set DUT "EF_WDT32_WB"


if [file exists work] {
    vdel -all
}
vlib work

vlog $DUT.v EF_WDT32.v ef_util_gating_cell_stub.v -sv tb_$DUT.sv

vsim -voptargs=+acc work.tb_$DUT

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
