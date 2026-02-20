`timescale 1ns/1ps

`include "EF_WDT32.v"
`default_nettype none


//This test will basic test submodule
module tb_EF_WDT32;
reg clk;
reg rst_i;
reg WDTEN;
reg [31:0] WDTLOAD;
reg WDTTO;
reg [31:0] WDTMR;
reg [31:0] reg_WDTMR;
integer fail;

EF_WDT32 dut
(
    .rst_i (rst_i),
    .clk (clk),
    .WDTEN (WDTEN), 
    .WDTLOAD (WDTLOAD), 
    .WDTTO (WDTTO), 
    .WDTMR (WDTMR) 
);

localparam CLK_PERIOD = 10;
always #(CLK_PERIOD/2) clk=~clk;

initial begin
    $dumpfile("tb_EF_WDT32.vcd");
    $dumpvars(0, tb_EF_WDT32);
end

initial begin
    //init
    fail = 0;
    clk = 1;
    rst_i = 1;
    WDTEN = 0;
    WDTLOAD = 32'h0000_0000;
    #10;
    rst_i = 0;


    //EN first then reload
    WDTEN = 1;
    #10;
    WDTLOAD = 32'hDEAD_BEEF;
    #50;
    reg_WDTMR = WDTMR;
    $display("WDTMR = 0x%h", reg_WDTMR);
    if (reg_WDTMR !== WDTLOAD) begin
        $display("------Test Passed, WDT is running------");
    end 
    else begin
        $display("\nFAILED");
        fail ++;
    end

    #50;


    //EN = 0, WDT will not running
    rst_i = 1;
    WDTEN = 0; //Test submodule, reg will store 1 from the last value, reset value off EN are on wrapper
    #10;
    rst_i = 0;
    //WDTEN = 1;
    #10;
    WDTLOAD = 32'hBABA_CACA;
    #50;
    reg_WDTMR = WDTMR;
    $display("WDTMR = 0x%h", reg_WDTMR);
    if (reg_WDTMR == WDTLOAD) begin
        $display("-----Test Passed, WDT is not running------");
    end 
    else begin
        $display("\nFAILED");
        fail ++;
    end

    #50;

    //Test reset
    rst_i = 1;
    WDTEN = 0; //Test submodule, reg will store 1 from the last value, reset value off EN are on wrapper
    #10;
    rst_i = 0;
    WDTEN = 1;
    #10;
    WDTLOAD = 32'hCABA_CACA;
    #50;
    reg_WDTMR = WDTMR;
    $display("WDTMR = 0x%h", reg_WDTMR);
    if (reg_WDTMR !== WDTLOAD) begin
        $display("-----Test Passed, WDT is running------");
    end 
    else begin
        $display("\nFAILED");
        fail++;
    end

    #50;


    //This test will load value first then enable 
    rst_i = 1;
    WDTEN = 0; //Test submodule, reg will store 1 from the last value, reset value off EN are on wrapper
    #10;
    rst_i = 0;
    WDTLOAD = 32'hCABA_CACA;
    #10;
    WDTEN = 1;
    #50;
    reg_WDTMR = WDTMR;
    $display("WDTMR = 0x%h", reg_WDTMR);
    if (reg_WDTMR !== WDTLOAD) begin
        $display("-----Test Passed, WDT is running------");
    end 
    else begin
        $display("\nFAILED");
        fail++;
    end

    #50;

    if (fail == 0) begin
        $display("\n\n-----All Test Passed------");
    end 
    else begin
        $display("FAILED");
    end

    $finish;
end

endmodule