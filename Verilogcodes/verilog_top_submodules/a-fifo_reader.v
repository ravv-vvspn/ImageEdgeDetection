module a_fifo_reader (
  input  wire clk_200mhz,
  input  wire reset_n,
  // Async FIFO Interface
  input  wire [7:0] fifo_dout,
  input  wire fifo_empty,
  output wire fifo_rd_en,
  // Sobel Interface
  //output reg  [7:0] pixel_out,
  //output reg  valid_out,
  output wire  [7:0] pixel_out,
  output wire  valid_out,
  input  wire ready_in  // From Sobel (backpressure)
);

  // Read when FIFO is not empty and Sobel is ready
  assign fifo_rd_en = !fifo_empty && ready_in;

// /*
  assign valid_out = fifo_rd_en; // Assert valid when reading
  assign pixel_out = fifo_dout;
// */

 /*
   always @(posedge clk_200mhz or negedge reset_n) begin
     if (!reset_n) begin
       pixel_out <= 0;
       valid_out <= 0;
     end else begin
       valid_out <= fifo_rd_en; // Assert valid when reading
       pixel_out <= fifo_rd_en ? fifo_dout : 0;
     end
   end
 */

endmodule