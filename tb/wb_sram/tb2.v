`timescale 1ns / 1ps

module tb2;

    parameter DW = 32;
    parameter DEPTH = 1024; // 1KB
    parameter AW = 32;
    localparam WORDS = DEPTH/4; // 256 Words

    reg wb_clk_i = 0;
    reg wb_rst_i;
    reg [AW-1:0] wb_adr_i;
    reg [DW-1:0] wb_dat_i;
    reg [3:0]    wb_sel_i;
    reg          wb_we_i;
    reg [1:0]    wb_bte_i;
    reg [2:0]    wb_cti_i;
    reg          wb_cyc_i;
    reg          wb_stb_i;

    wire         wb_ack_o;
    wire [DW-1:0] wb_dat_o;
    
    wire          wb_err_o;
    
    integer i, j;
    integer error_count = 0;
    
    // Khai báo biến cho Stress Test ở đây để tránh lỗi Verilog
    integer addr_rand;
    integer data_rand;

    // Clock 100MHz
    always #5 wb_clk_i = ~wb_clk_i;

    // DUT Instance
    wb_ram #(.dw(DW), .depth(DEPTH)) dut (
        .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
        .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i),
        .wb_sel_i(wb_sel_i), .wb_we_i(wb_we_i),
        .wb_bte_i(wb_bte_i), .wb_cti_i(wb_cti_i),
        .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i),
        .wb_err_o(wb_err_o),
        .wb_ack_o(wb_ack_o), .wb_dat_o(wb_dat_o)
    );

    // --- TASKS ---
    task wb_write;
        input [AW-1:0] addr;
        input [DW-1:0] data;
        input [3:0] sel;
    begin
        @(posedge wb_clk_i);
        wb_adr_i <= addr; wb_dat_i <= data; wb_sel_i <= sel;
        wb_we_i <= 1'b1; wb_cyc_i <= 1'b1; wb_stb_i <= 1'b1;
        wait(wb_ack_o);
        @(posedge wb_clk_i);
        wb_cyc_i <= 1'b0; wb_stb_i <= 1'b0;
    end
    endtask

    task wb_read;
        input [AW-1:0] addr;
        output [DW-1:0] data;
    begin
        @(posedge wb_clk_i);
        wb_adr_i <= addr; wb_sel_i <= 4'b1111;
        wb_we_i <= 1'b0; wb_cyc_i <= 1'b1; wb_stb_i <= 1'b1;
        wait(wb_ack_o);
        @(posedge wb_clk_i);
        data = wb_dat_o;
        wb_cyc_i <= 1'b0; wb_stb_i <= 1'b0;
    end
    endtask

    task reset_dut;
    begin
        $display("--- Resetting System ---");
        wb_rst_i = 1;
        wb_cyc_i = 0; wb_stb_i = 0; wb_we_i = 0;
        wb_cti_i = 0; wb_bte_i = 0;
        #20;
        @(posedge wb_clk_i);
        wb_rst_i = 0;
        @(posedge wb_clk_i);
    end
    endtask

    // --- MAIN STIMULUS ---
    initial begin
        // Init signals
        wb_rst_i = 1; wb_adr_i = 0; wb_dat_i = 0; wb_sel_i = 0;
        wb_we_i = 0; wb_cyc_i = 0; wb_stb_i = 0; wb_cti_i = 0; wb_bte_i = 0;
        #100 wb_rst_i = 0;

        // 1. SINGLE R/W TEST
        wb_rst_i = 1; #20 wb_rst_i = 0;
        $display("TEST 1: Single R/W");
        wb_write(32'h0, 32'hA5A5_5A5A, 4'b1111);
        wb_read(32'h0, j);
        if (j !== 32'hA5A5_5A5A) begin 
            $display("FAIL T1"); 
            error_count = error_count + 1; 
        end

        // 2. BYTE SELECTION TEST
        wb_rst_i = 1; #20 wb_rst_i = 0;
        $display("TEST 2: Byte Selection");
        wb_write(32'h4, 32'h0000_0000, 4'b1111); 
        wb_write(32'h4, 32'hFF00_0000, 4'b1000); 
        wb_write(32'h4, 32'h0000_00EE, 4'b0001); 
        wb_read(32'h4, j);
        if (j !== 32'hFF00_00EE) begin 
            $display("FAIL T2: Got %h", j); 
            error_count = error_count + 1; 
        end

        // 3. FULL SWEEP TEST
        wb_rst_i = 1; #20 wb_rst_i = 0;
        $display("TEST 3: Full Sweep 1KB");
        for (i=0; i<WORDS; i=i+1) begin
            wb_write(i*4, i*13 + 7, 4'b1111);
        end
        for (i=0; i<WORDS; i=i+1) begin
            wb_read(i*4, j);
            if (j !== i*13 + 7) error_count = error_count + 1;
        end
        
        
        wb_rst_i = 1; #20 wb_rst_i = 0;
        $display("TEST 6: Stress Test (500 iterations)");
        for (i=0; i<500; i=i+1) begin
            // Đảm bảo địa chỉ dương và nằm trong dải WORDS (0-255)
            addr_rand = ($unsigned($random) % WORDS) * 4;
            
            // Ép kiểu unsigned cho data để so sánh chính xác
            data_rand = $unsigned($random); 
            
            wb_write(addr_rand, data_rand, 4'b1111);
            
            // Thêm 1 nhịp nghỉ giữa Write và Read để Bus ổn định
            @(posedge wb_clk_i); 
            
            wb_read(addr_rand, j);
            
            if (j !== data_rand) begin
                error_count = error_count + 1;
                // In ra vài lỗi đầu để debug
                if (error_count < 5) 
                    $display("[STRESS FAIL] Addr: %h | Sent: %h | Got: %h", addr_rand, data_rand, j);
            end
        end
	
	wb_rst_i = 1; #20 wb_rst_i = 0;
	        // 4. ADDRESS WRAP TEST
        $display("TEST 4: Address Wrap (1024 -> 0)");
        wb_write(32'h0, 32'h1111_1111, 4'b1111);
        wb_write(32'd1024, 32'h9999_9999, 4'b1111);
        wb_read(32'h0, j);
        if (j === 32'h9999_9999) 
            $display("PASS: Wrap detected at 1024");
        else 
            $display("FAIL: No Wrap detected");

	wb_rst_i = 1; #20 wb_rst_i = 0;
 // 5. BURST MODE
 
 	reset_dut();
        $display("TEST 5: Burst Simulation with Checker");
        @(posedge wb_clk_i);
        
        // --- PHẦN 1: GHI BURST ---
        wb_cyc_i <= 1; wb_stb_i <= 1; wb_we_i <= 1; wb_sel_i <= 4'b1111;
        
        for (i=0; i<4; i=i+1) begin
            wb_cti_i <= (i == 3) ? 3'b111 : 3'b010; 
            wb_adr_i <= 32'h100 + (i*4);
            wb_dat_i <= 32'hB005_0000 + i;
            
            // Thay thế do-while bằng vòng lặp while thuần Verilog
            // Chờ cho đến khi cạnh clock tới VÀ wb_ack_o đang cao
            @(posedge wb_clk_i);
            while (!wb_ack_o) begin
                @(posedge wb_clk_i);
            end
            
            $display("[WRITE] Addr: %h, Data: %h - ACK OK", wb_adr_i, wb_dat_i);
        end
        
        // Kết thúc burst: Tắt stb và cyc ngay sau nhịp cuối
        wb_cyc_i <= 0; wb_stb_i <= 0; wb_we_i <= 0;
        wb_cti_i <= 3'b000;
        #20;

        // --- PHẦN 2: ĐỌC LẠI ĐỂ CHECK ---
        $display("Checking Burst Results...");
        wb_cyc_i <= 1; wb_stb_i <= 1; wb_we_i <= 0;

        for (i=0; i<4; i=i+1) begin
            wb_adr_i <= 32'h100 + (i*4);
            
            @(posedge wb_clk_i);
            while (!wb_ack_o) begin
                @(posedge wb_clk_i);
            end
            
            #1; // Trễ nhỏ để dữ liệu từ RAM ổn định sau cạnh clock
            if (wb_dat_o === (32'hB005_0000 + i)) begin
                $display("[CHECK PASS] Addr: %h, Read: %h", wb_adr_i, wb_dat_o);
            end else begin
                $display("[CHECK FAIL] Addr: %h, Expected: %h, Got: %h", 
                          wb_adr_i, (32'hB005_0000 + i), wb_dat_o);
            end
        end

        wb_cyc_i <= 0; wb_stb_i <= 0;
        $display("TEST 5 Finished.");


        $display("--- KET QUA ---");
        if (error_count == 0) $display("ALL TESTS PASSED!");
        else $display("TOTAL ERRORS: %d", error_count);
        $stop;
    end
endmodule
