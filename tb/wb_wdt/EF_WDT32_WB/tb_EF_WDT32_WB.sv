`timescale 1ns/1ps

//`include "EF_WDT32_WB.v"
`default_nettype none

module tb_EF_WDT32_WB;
    reg         clk_i;
    reg         rst_i;
    reg  [31:0] adr_i;
    reg  [31:0] dat_i;
    reg  [ 3:0] sel_i;
    reg         cyc_i;
    reg         stb_i;
    reg         we_i;
    
    wire [31:0] dat_o;
    wire        ack_o; 
    wire        IRQ;

EF_WDT32_WB dut
(
        .clk_i (clk_i),
        .rst_i (rst_i),
        .adr_i (adr_i),
        .dat_i (dat_i),
        .dat_o (dat_o),
        .sel_i (sel_i),
        .cyc_i (cyc_i),
        .stb_i (stb_i),
        .ack_o (ack_o),
        .we_i  (we_i),
        .IRQ   (IRQ)
);

localparam CLK_PERIOD = 10;
localparam BASE_ADDRESS = 32'h2001_0000;
localparam timer_REG_OFFSET = 8'h00;
localparam load_REG_OFFSET = 8'h04;
localparam control_REG_OFFSET = 8'h08;
localparam IM_REG_OFFSET = 8'hc;
localparam MIS_REG_OFFSET = 8'h10;
localparam RIS_REG_OFFSET = 8'h14;
localparam IC_REG_OFFSET = 8'h18;
localparam GCLK_REG_OFFSET = 8'h1c;
integer error_cnt = 0;

//clock
always #(CLK_PERIOD/2) clk_i=~clk_i;
reg [31:0] reg_addr;
reg [31:0] reg_data;

//Func
task wb_write(input [31:0] addr, input [31:0] data);
begin
    @(posedge clk_i);
    adr_i = addr;
    dat_i = data;
    we_i  = 1;
    sel_i = 4'hF ;
    cyc_i = 1;
    stb_i = 1;

    // chờ ACK
    wait (ack_o == 1);

    @(posedge clk_i);
    cyc_i = 0;
    stb_i = 0;
    we_i  = 0;

    $display("WB WRITE: addr=%h data=%h ", addr, data);
end
endtask


task wb_read(input [31:0] addr, output [31:0] data);
begin
    @(posedge clk_i);
    adr_i = addr;
    we_i  = 0;
    sel_i = 4'hF;
    cyc_i = 1;
    stb_i = 1;

    wait (ack_o == 1);

    data = dat_o;

    @(posedge clk_i);
    cyc_i = 0;
    stb_i = 0;

    $display("WB READ: addr=%h data=%h", addr, data);
end
endtask

task check_rs_value();
    #10;
    if (dut.instance_to_wrap.WDTEN == 0 && dut.instance_to_wrap.WDTLOAD == 32'h0000_0000 && dut.instance_to_wrap.WDTTO == 0  && dut.instance_to_wrap.rst_n == 1 && dut.instance_to_wrap.WDTMR == 32'h0000_0000) begin
        $display("Right reset value");
    end else begin
        $display("SOS! WRONG reset value");
        error_cnt ++;
    end
endtask


initial begin
    $dumpfile("tb_EF_WDT32_WB.vcd");
    $dumpvars(0, tb_EF_WDT32_WB);
end

/*initial begin
    clk_i = 0;
    rst_i = 1;
    #20 rst_i = 0;
end*/

initial begin
    reg_addr = 32'h0;
    reg_data = 32'h0;
end

initial begin
    // --- Khởi tạo trạng thái ban đầu ---
    clk_i = 0;
    rst_i = 1;
    adr_i = 0;
    dat_i = 0;
    sel_i = 4'h0;
    we_i  = 0;
    cyc_i = 0;
    stb_i = 0;

    //wb_write(32'h2001_0008, 32'hDEAD_BEEF); //Enable
    //wb_write(32'h2001_0004, 32'h0000_0000); //Reload

    #50 rst_i = 0; // if (dut.GCLK_REG == 1) begin

    //Check reset value
    check_rs_value();


    $display("-----Test 1: Check offset of WDT & Enable & Is Running------");
    wb_write(BASE_ADDRESS + GCLK_REG_OFFSET, 32'h1); //Gate clock off will have clock on sub-dut
    #10;
    if (dut.GCLK_REG == 1) begin
        $display("[GCLK] OK");
    end else begin
        $display("[GCLK] FAIL");
        error_cnt ++;
    end
    
    #10
    wb_write(BASE_ADDRESS + load_REG_OFFSET, 32'hBACA_FFFF); //Reload
    if (dut.instance_to_wrap.WDTLOAD == 32'hBACA_FFFF) begin
        $display("[RELOAD] OK");
    end else begin
        $display("[RELOAD] FAIL");
        error_cnt ++;
    end


    #10;
    wb_write(BASE_ADDRESS + control_REG_OFFSET, 32'hDEAD_BEEF); //Enable
    if (dut.instance_to_wrap.WDTEN == 1) begin
        $display("[ENABLE] OK");
    end else begin
        $display("[RELOAD] FAIL");
        error_cnt ++;
    end
    
    #60
    wb_read(BASE_ADDRESS + timer_REG_OFFSET, reg_data); //Real time value

    if (reg_data == dut.instance_to_wrap.WDTMR) begin
        $display("[TIMER] OK AND IS RUNNING 0X%h", dut.instance_to_wrap.WDTMR);
    end
    else begin
        $display("[TIMER] FAIL Timer Value 0x%h | 0X%h", reg_data, dut.instance_to_wrap.WDTMR);
        error_cnt ++;
    end

    #50;
    if (error_cnt == 0) begin
        $display("\n\n-------[ALL] OK----------");
    end else begin
        $display("\n\n-------[ALL] FAIL LAM ROI %d----------", error_cnt);
    end

    #50;
    $finish;

end

//$display("-----Test 1: Check offset of WDT Enable------");



endmodule
