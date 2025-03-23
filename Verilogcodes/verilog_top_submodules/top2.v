module top2 (
  input  wire clk_100mhz,    // 100 MHz clock
  input  wire clk_200mhz,    // 200 MHz clock
  input  wire start,         // Start processing
  input  wire reset_n,       // Global reset
  output wire wr_rst_busy,   // Async FIFO write reset busy
  output wire rd_rst_busy,   // Async FIFO read reset busy
  // Serial Output Interface
  output wire serial_data,
  output wire serial_valid,
  input  wire serial_ready_in
);

  // Synchronized resets for each domain
  wire reset_100mhz_n;
  wire reset_200mhz_n;

  // reset synchronizers
  reset_sync reset_sync_100 (
    .clk(clk_100mhz),
    .a_reset_n(reset_n),
    .s_reset_n(reset_100mhz_n)
  );

  reset_sync reset_sync_200 (
    .clk(clk_200mhz),
    .a_reset_n(reset_n),
    .s_reset_n(reset_200mhz_n)
  );


  // BRAM Signals
  wire [12:0] bram_addr;
  wire [7:0] bram_data;
  wire bram_en;

  // Async FIFO Signals
  wire [7:0] fifo_dout, fifo_din;
  wire fifo_rd_en;
  wire fifo_wr_en;  
  wire fifo_full;   
  wire fifo_empty;
  
  wire fifo_afull;   
  wire fifo_aempty;

  // Pooling Output Interface
  wire [7:0] pooled_data;
  wire pooled_valid;
  wire pooled_ready;

  // BRAM Instance
  bram_1 bram (
    .clka(clk_100mhz),
    .ena(bram_en),
    .wea(1'b0),
    .addra(bram_addr),
    .dina(8'h00),
    .douta(bram_data)
  );

  // Async FIFO Instance  
  a_fifo async_fifo (
    .rst(!reset_n),     // has internal reset synchronizers as part of IP
    .wr_clk(clk_100mhz),
    .rd_clk(clk_200mhz),
    .din(fifo_din),
    .wr_en(fifo_wr_en),
    .rd_en(fifo_rd_en),
    .dout(fifo_dout),
    .full(fifo_full),
    .empty(fifo_empty),
    .almost_full(fifo_afull),
    .almost_empty(fifo_aempty),
    .wr_rst_busy(wr_rst_busy),
    .rd_rst_busy(rd_rst_busy)
  );

  // BRAM Controller
  bram_fifo_controller controller (
    .clk_100mhz(clk_100mhz),
    .reset_n(reset_100mhz_n),
    .start(start),
    .bram_en(bram_en),
    .bram_addr(bram_addr),
    .bram_data(bram_data),
    .fifo_din(fifo_din),
    .fifo_wr_en(fifo_wr_en),
    .fifo_full(fifo_full),
    .fifo_afull(fifo_afull)
  );

  // Image Processing Pipeline
  image_processing img_proc (
    .clk_100mhz(clk_100mhz),
    .clk_200mhz(clk_200mhz),
    .reset_n(reset_200mhz_n),
    .fifo_dout(fifo_dout),
    .fifo_empty(fifo_empty),
    .fifo_rd_en(fifo_rd_en),
    .pooled_data(pooled_data),
    .pooled_valid(pooled_valid),
    .pooled_ready_in(pooled_ready)
  );

  // Parallel-to-Serial Converter
  parallel2serial p2s (
    .clk(clk_200mhz),
    .reset_n(reset_200mhz_n),
    .parallel_data(pooled_data),
    .parallel_valid(pooled_valid),
    .parallel_ready_out(pooled_ready),
    .serial_data(serial_data),
    .serial_valid(serial_valid),
    .serial_ready_in(serial_ready_in)
  );

endmodule
