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
    we_i  = 1;#50 rst_i = 0;
    sel_i = 4'hF ;
    cyc_i = 1;
    stb_i = 1;

    // chờ ACK
    wait (ack_o == 1);

    @(posedge clk_i);
    cyc_i = 0;
    stb_i = 0;
    we_i  = 0;

    $display("[WB WRITE] addr=%h data=%h ", addr, data);
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

    $display("[WB READ] addr=%h data=%h", addr, data);
end
endtask

task check_rs_value();
    #10;
    if (dut.instance_to_wrap.WDTEN == 0 && dut.instance_to_wrap.WDTLOAD == 32'h0000_0000 && dut.instance_to_wrap.WDTTO == 0  && dut.instance_to_wrap.rst_n == 1 && dut.instance_to_wrap.WDTMR == 32'h0000_0000 && dut.GCLK_REG == 1 && dut.IM_REG == 0 && dut.IC_REG == 0 && dut.RIS_REG == 0) begin
        $display("Right reset value");
    end else begin
        $display("SOS! WRONG reset value");
        error_cnt ++;
    end
endtask

task rs_then_check_rs_value();
    $display("Reseting...");
    rst_i = 1;
    #50 
    rst_i = 0;
    #10;
    check_rs_value();
endtask

task WDT_is_running(input [31:0] expt_value, output integer result);
    wb_read(BASE_ADDRESS + timer_REG_OFFSET, reg_data); //Real time value
    if (reg_data == expt_value || reg_data == 32'h0000_0000) begin
        $display("[TIMER] WDT is not running real Value 0x%h | Input value: 0x%h", reg_data, expt_value);
        result = 0;
    end
    else begin
        $display("[TIMER] OK AND IS RUNNING 0X%h", reg_data);
        result = 1;
    end
endtask

task automatic test_readonly_reg(input [31:0] addr, input string reg_name);
    logic [31:0] original_val;
    logic [31:0] read_back_val;
    logic [31:0] junk_data = 32'hAAAA_5555; // Giá trị rác dùng để ghi thử

    // 1. Đọc giá trị ban đầu
    wb_read(addr, original_val);
    $display("[%s] Original value: %h", reg_name, original_val);

    // 2. Cố gắng ghi đè vào thanh ghi RO
    $display("[%s] Attempting to write junk data: %h", reg_name, junk_data);
    wb_write(addr, junk_data);

    // 3. Đọc lại để kiểm tra
    wb_read(addr, read_back_val);
    
    // 4. So sánh
    if (read_back_val === junk_data && junk_data !== original_val) begin
        $display("[FAIL] %s is WRITABLE! It should be Read-Only.", reg_name);
        error_cnt++;
    end else begin
        $display("[PASS] %s is Read-Only. Value remained: %h", reg_name, read_back_val);
    end
endtask

task task_1_check_offset ();
    $display("-----Test 1: Check offset of WDT & Enable & Is Running------");
    //wb_write(BASE_ADDRESS + GCLK_REG_OFFSET, 32'h1); //Gate clock off will have clock on sub-dut
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
    wb_write(BASE_ADDRESS + control_REG_OFFSET, 32'hDEAD_BEEF); //Enable:
    if (dut.instance_to_wrap.WDTEN == 1) begin
        $display("[ENABLE] OK");
    end else begin
        $display("[RELOAD] FAIL");
        error_cnt ++;
    end
    
    #60
    wb_read(BASE_ADDRESS + timer_REG_OFFSET, reg_data); //Real time value
    if (reg_data == dut.instance_to_wrap.WDTMR && reg_data !== 32'hBACA_FFFF) begin
        $display("[TIMER] OK AND IS RUNNING 0X%h", dut.instance_to_wrap.WDTMR);
    end
    else begin
        $display("[TIMER] FAIL Timer Value 0x%h | 0X%h", reg_data, dut.instance_to_wrap.WDTMR);
        error_cnt ++;
    end

endtask

task task2_TO_mask_offset();
    $display("\n----- Test 2: Check Interrupt Registers (IM, RIS, MIS, IC) -----");

    //wb_write(BASE_ADDRESS + GCLK_REG_OFFSET, 32'h1); //Gate clock off will have clock on sub-dut
    //#10;
    #10;
    if (dut.GCLK_REG == 1) begin
        $display("[GCLK] OFFSET OK");
    end else begin
        $display("[GCLK] OFFSET FAIL");
        error_cnt ++;
    end

    $display("[IM] Enable IM");
    wb_write(BASE_ADDRESS + IM_REG_OFFSET, 32'h1);
    #10;
    if (dut.IM_REG == 1) begin
        $display("[IM] OFFSET OK");
    end else begin
        $display("[IM] OFFSET FAIL");
        error_cnt ++;
    end
    $display("Setting to TO, EN = 1, REALOAD = 0x0000_0005");
    wb_write(BASE_ADDRESS + load_REG_OFFSET, 32'h0000_0005); 
    wb_write(BASE_ADDRESS + control_REG_OFFSET, 32'h1); // Enable WDT

    $display("Waiting for WDT Timeout...");
    
    wait(dut.RIS_REG == 1'b1);
    $display("[RIS] Triggered: OK");

    wb_read(BASE_ADDRESS + MIS_REG_OFFSET, reg_data);
    if (reg_data[0] == 1'b1 && IRQ == 1'b1) begin
        $display("[MIS & IRQ] Active: OK");
    end else begin
        $display("[MIS & IRQ] FAIL: reg_data=%h, IRQ=%b", reg_data, IRQ);
        error_cnt++;
    end

    wb_write(BASE_ADDRESS + IC_REG_OFFSET, 32'h1);
    #20; 
    
    wb_read(BASE_ADDRESS + RIS_REG_OFFSET, reg_data);
    if (reg_data[0] == 1'b0) begin
        $display("[IC & RIS] Clear SUCCESS: OK");
    end else begin
        $display("[IC & RIS] Clear FAIL: RIS still %h", reg_data);
        error_cnt++;
    end        
endtask

task automatic test_3_test_another_application();
    integer result = 1;
    $display("\n----- Test 3: Check other applications (IM off, GCLK off) -----");
    wb_write(BASE_ADDRESS + GCLK_REG_OFFSET, 32'h0); //Gate clock off will have clock on sub-dut
    //#10;
    #10;
    if (dut.GCLK_REG == 1) begin
        $display("[GCLK] NOW CLOCK IS RUNNING");
    end else begin
        $display("[GCLK] NOT RUNNING");
    end

    #10
    wb_write(BASE_ADDRESS + load_REG_OFFSET, 32'hCAFE_BABE); //Reload
    if (dut.instance_to_wrap.WDTLOAD == 32'hCAFE_BABE) begin
        $display("[RELOAD] OK");
    end else begin
        $display("[RELOAD] FAIL");
        error_cnt ++;
    end

    #10;
    wb_write(BASE_ADDRESS + control_REG_OFFSET, 32'hDEAD_BEEF); //Enable:
    if (dut.instance_to_wrap.WDTEN == 1) begin
        $display("[ENABLE] OK");
    end else begin
        $display("[RELOAD] FAIL");
        error_cnt ++;
    end

    #60;
    wb_read(BASE_ADDRESS + timer_REG_OFFSET, reg_data);
    WDT_is_running (32'hCAFE_BABE, result);

    if (result == 0) begin
        $display("[GCLK] This test passed, GLCK = 0, WDT not running");
    end else begin
        $display("[GCLK] This test failed, WDT is running");
        error_cnt ++;
    end

    rs_then_check_rs_value();

    $display("Still on test 3...");//Test MASK IRQ

    if (dut.GCLK_REG == 1) begin
        $display("[GCLK] NOW CLOCK IS RUNNING");
    end else begin
        $display("[GCLK] NOT RUNNING");
    end

    $display("[IM] Disable IM"); //Just for sure...
    wb_write(BASE_ADDRESS + IM_REG_OFFSET, 32'h0);
    #10;
    if (dut.IM_REG == 0) begin
        $display("[IM] OFF");
    end else begin
        $display("[IM] ON");
        error_cnt ++;
    end
    $display("Setting to TO, EN = 1, REALOAD = 0x0000_0005");
    wb_write(BASE_ADDRESS + load_REG_OFFSET, 32'h0000_0005); 
    wb_write(BASE_ADDRESS + control_REG_OFFSET, 32'h1); // Enable WDT

    $display("Waiting for WDT Timeout...");
    
    wait(dut.RIS_REG == 1'b1);
    $display("[RIS] Triggered: OK");

    if (dut.RIS_REG == 1'b1) begin //Just to make sure...
        $display("[RIS] Triggered");
    end else begin
        $display("[RIS] Not Triggered");
        error_cnt ++;
    end

    wb_read(BASE_ADDRESS + MIS_REG_OFFSET, reg_data);
    if (reg_data[0] == 1'b0 && IRQ == 1'b0) begin
        $display("[MIS & IRQ] NOT ACTIVATE: OK");
    end else begin
        $display("[MIS & IRQ] ACTIVATE - FAIL: reg_data=%h, IRQ=%b", reg_data, IRQ);
        error_cnt++;
    end
endtask

task test_4_readonly();
    rs_then_check_rs_value ();
    #10;

    $display("\n--- Checking Read-Only Registers ---");
    
    // Test thanh ghi Timer (Cực kỳ quan trọng vì nó thay đổi liên tục)
    test_readonly_reg(BASE_ADDRESS + timer_REG_OFFSET, "TIMER_REG");

    // Test thanh ghi RIS (Raw Interrupt Status)
    test_readonly_reg(BASE_ADDRESS + RIS_REG_OFFSET, "RIS_REG");

    // Test thanh ghi MIS (Masked Interrupt Status)
    test_readonly_reg(BASE_ADDRESS + MIS_REG_OFFSET, "MIS_REG");
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

    task_1_check_offset();//Check another offset and WDT running?

    rs_then_check_rs_value();//Reset
    
    task2_TO_mask_offset();//Check TO, IRQ, IM, MIS,RIS, IC OFFSET

    rs_then_check_rs_value();//Reset

    test_3_test_another_application();

    rs_then_check_rs_value();

    test_4_readonly ();
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
