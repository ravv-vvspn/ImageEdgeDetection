module a_fifo (
    input wire rst,
    input wire wr_clk,
    input wire rd_clk,
    input wire [7:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire [7:0] dout,
    output wire full,
    output wire empty,
    output wire almost_full,
    output wire almost_empty,
    output wire wr_rst_busy,
    output wire rd_rst_busy
);

// Instantiating the VHDL FIFO inside Verilog
fifo_generator_0 fifo_inst (
    .rst(rst),
    .wr_clk(wr_clk),
    .rd_clk(rd_clk),
    .din(din),
    .wr_en(wr_en),
    .rd_en(rd_en),
    .dout(dout),
    .full(full),
    .empty(empty),
    .almost_full(almost_full),
    .almost_empty(almost_empty),
    .wr_rst_busy(wr_rst_busy),
    .rd_rst_busy(rd_rst_busy)
);

endmodule
