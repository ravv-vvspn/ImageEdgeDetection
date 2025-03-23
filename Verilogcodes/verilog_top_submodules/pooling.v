module average_pooling (
  input  wire clk_200mhz,
  input  wire reset_n,
  // Input Interface
  input  wire [11:0] pixel_in,
  input  wire valid_in,
  output wire ready_out,  // To Sobel
  // Output Interface
  output wire [7:0] pixel_out,
  output wire valid_out,
  // Serializer Backpressure
  input  wire ready_in    // From Serializer
);

  // Instantiate one of the two pooling modules
  
 //       /*
  // Stride 2: Produces a 31x31 output image from a 62x62 input
  average_pooling_stride2 u_avg_pooling (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .pixel_out(pixel_out),
    .valid_out(valid_out),
    .ready_in(ready_in)
  );
//        */

      /*
  // Stride 1: Produces a 61x61 output image from a 62x62 input
  average_pooling_stride1 u_avg_pooling (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .pixel_in(pixel_in),
    .valid_in(valid_in),
    .ready_out(ready_out),
    .pixel_out(pixel_out),
    .valid_out(valid_out),
    .ready_in(ready_in)
  );
      */

endmodule