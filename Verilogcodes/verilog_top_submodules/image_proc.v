module image_processing (
  input  wire clk_100mhz,
  input  wire clk_200mhz,
  input  wire reset_n,
  // Async FIFO Interface (from BRAM)
  input  wire [7:0] fifo_dout,
  input  wire fifo_empty,
  output wire fifo_rd_en,
  // Pooling Output Interface (to parallel2serial)
  output wire [7:0] pooled_data,
  output wire pooled_valid,
  input  wire pooled_ready_in  // Backpressure from parallel2serial
);

  // Sobel Input Interface (a-fifo_reader <-> Sobel)
  wire [7:0] sobel_pixel;
  wire sobel_valid, sobel_ready_out;
  wire pooled_ready_out;
  
  a_fifo_reader reader (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .fifo_dout(fifo_dout),
    .fifo_empty(fifo_empty),
    .fifo_rd_en(fifo_rd_en),
    .pixel_out(sobel_pixel),
    .valid_out(sobel_valid),
    .ready_in(sobel_ready_out)
  );

  // Sobel Filter Output
  wire [11:0] pooled_pixel;
  wire pooled_valid_internal;

 // /*
  sobel_filter sobel (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .pixel_in(sobel_pixel),
    .valid_in(sobel_valid),
    .ready_out(sobel_ready_out),
    .pixel_out(pooled_pixel),
    .valid_out(pooled_valid_internal),
    .ready_in(pooled_ready_out) 
  );

  // Average Pooling
  average_pooling pool (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .pixel_in(pooled_pixel),
    .valid_in(pooled_valid_internal),
    .ready_out(pooled_ready_out), 
    .ready_in(pooled_ready_in),
    .pixel_out(pooled_data),
    .valid_out(pooled_valid)
  );
  
// */

 /*  
  ///////// 

  sobel_filter sobel (
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_n),
    .pixel_in(sobel_pixel),
    .valid_in(sobel_valid),
    .ready_out(sobel_ready_out),
    .pixel_out(pooled_pixel),
    .valid_out(pooled_valid),
    .ready_in(pooled_ready_in) 
  );
  
  assign pooled_data = (pooled_pixel > 255)? 255 : pooled_pixel[7:0];
  */

endmodule
