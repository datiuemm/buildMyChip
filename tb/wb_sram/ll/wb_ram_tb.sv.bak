`timescale 1ns / 1ps

module wb_ram_tb;
    parameter DW = 32;
    parameter AW = 32;
    parameter DEPTH = 16384; 

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
    wire         wb_err_o;
    wire [DW-1:0] wb_dat_o;

    // Biến điều khiển
    integer i; 
    integer error_count;
    integer log_idx;
    reg [AW-1:0] error_log [0:511];

    always #5 wb_clk_i = ~wb_clk_i;

    wb_ram #(.dw(DW), .depth(DEPTH)) dut (
        .wb_clk_i(wb_clk_i), .wb_rst_i(wb_rst_i),
        .wb_adr_i(wb_adr_i), .wb_dat_i(wb_dat_i),
        .wb_sel_i(wb_sel_i), .wb_we_i(wb_we_i),
        .wb_bte_i(wb_bte_i), .wb_cti_i(wb_cti_i),
        .wb_cyc_i(wb_cyc_i), .wb_stb_i(wb_stb_i),
        .wb_ack_o(wb_ack_o), .wb_err_o(wb_err_o),
        .wb_dat_o(wb_dat_o)
    );

    // Task Write
    task wb_write(input [AW-1:0] addr, input [DW-1:0] data);
    begin
        @(posedge wb_clk_i);
        wb_adr_i <= addr; wb_dat_i <= data;
        wb_sel_i <= 4'b1111; wb_we_i  <= 1'b1;
        wb_cyc_i <= 1'b1;    wb_stb_i <= 1'b1;
        wb_cti_i <= 3'b000;
        wait(wb_ack_o);
        @(posedge wb_clk_i);
        wb_cyc_i <= 1'b0;    wb_stb_i <= 1'b0;
        wb_we_i  <= 1'b0;
    end
    endtask

    // Task Read
    task wb_read(input [AW-1:0] addr);
    begin
        @(posedge wb_clk_i);
        wb_adr_i <= addr; wb_sel_i <= 4'b1111;
        wb_we_i  <= 1'b0; wb_cyc_i <= 1'b1;
        wb_stb_i <= 1'b1;
        wb_cti_i <= 3'b000;
        wait(wb_ack_o);
        @(posedge wb_clk_i);
        wb_cyc_i <= 1'b0;    wb_stb_i <= 1'b0;
    end
    endtask

    initial begin
        wb_rst_i = 1; error_count = 0; log_idx = 0;
        wb_adr_i = 0; wb_dat_i = 0; wb_sel_i = 0;
        wb_we_i = 0; wb_cyc_i = 0; wb_stb_i = 0;
        
        #20 wb_rst_i = 0;
        #20;

        $display("--- BAT DAU KIEM TRA (0x0 -> 0xFFFF) ---");

        // GIAI DOAN 1: GHI
        // i chạy từ 0 đến 16383 (tổng cộng 16384 words)
        for (i = 0; i < DEPTH; i = i + 1) begin
            wb_write(i * 4, 32'h10000000 + i);
        end

        // GIAI DOAN 2: DOC & CHECK
        for (i = 0; i < DEPTH; i = i + 1) begin
            wb_read(i * 4);
            
            if (wb_dat_o !== (32'h10000000 + i)) begin
                if (log_idx < 512) begin
                    error_log[log_idx] = i * 4;
                    log_idx = log_idx + 1;
                end
                error_count = error_count + 1;
                $display("[LOI] Tai 0x%h | Ky vong: 0x%h | Thuc te: 0x%h", i*4, (32'h10000000 + i), wb_dat_o);
            end
        end

        $display("\n========================================");
        $display("TONG SO LOI: %d", error_count);
        if (error_count > 0) begin
            $display("DANH SACH DIA CHI LOI CAN TRACE:");
            for (i = 0; i < log_idx; i = i + 1) begin
                $display("  - 0x%h", error_log[i]);
            end
        end else begin
            $display("KET QUA: PASS!");
        end
        $display("========================================");
        
        $stop;
    end
endmodule
