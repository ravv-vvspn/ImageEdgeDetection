module s_fifo (
    input wire clk,
    input wire rst,
    input wire [7:0] din,
    input wire wr_en,
    input wire rd_en,
    output wire [7:0] dout,
    output wire [6:0] data_count,
    output wire full,
    output wire empty
);

// Instantiating the VHDL FIFO inside Verilog
s_fifo_generator_1 fifo_inst (
    .clk(clk),       // Clock
    .rst(rst),       // Reset
    .din(din),       // Data Input (8-bit)
    .wr_en(wr_en),   // Write Enable
    .rd_en(rd_en),   // Read Enable
    .dout(dout),     // Data Output (8-bit)
    .data_count(data_count),     // Full flag
    .full(full),     // Full flag
    .empty(empty)    // Empty flag
);

endmodule
