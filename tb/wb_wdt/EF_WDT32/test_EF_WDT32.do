set DUT "EF_WDT32"


if [file exists work] {
    vdel -all
}
vlib work

vlog $DUT.v -sv tb_$DUT.sv

vsim -voptargs=+acc work.tb_$DUT

add wave -r /*

run -all
