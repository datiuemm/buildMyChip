module ef_util_gating_cell (
    input  wire clk,
    input  wire clk_en,
    output wire clk_o
);

    reg en_latched;

    always @(posedge clk)
        en_latched <= clk_en;

    assign clk_o = clk & en_latched;

endmodule

