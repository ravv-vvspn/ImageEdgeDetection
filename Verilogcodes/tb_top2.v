`timescale 1ns / 1ps

// Define pixel count as a macro

//`define PxelCnt 3844  // 62x62 sobel output
//`define PxelCnt 3721  // 61x61 pooling output stride1

`define PxelCnt 961  // 31x31 pooling output stride2
//`define PxelCnt 957  // 31x31 pooling output stride2 4 pixels missing


`define Timelimit 0.85  //total time to simulate in 100 us

module tb_top2();

  // Clocks
  reg clk_100mhz = 0;
  reg clk_200mhz = 0;
  reg reset_n = 0;
  reg start = 0;
  reg serial_ready = 0; // Always ready to receive data
  // DUT Outputs
  wire serial_data, serial_valid;
  wire wr_rst_busy, rd_rst_busy;
  wire or_busy = wr_rst_busy || rd_rst_busy;
  // Pixel Storage
  reg [7:0] pixel_ram [0:`PxelCnt-1]; // 31x31 = `PxelCnt pixels
  
  //$clog2(MAX_COUNT+1)-1:0
  //reg [9:0] pixel_counter = 0;
  reg [$clog2(`PxelCnt+1)-1:0] pixel_counter = 0;
  
  reg [7:0] received_byte = 0;
  reg [2:0] bit_counter = 0;
  // File Handling
  integer file;
  // Timeout flag
  reg timeout = 0;
  
  // Clock Generation
  always #5 clk_100mhz = ~clk_100mhz; // 100 MHz
  always #2.5 clk_200mhz = ~clk_200mhz; // 200 MHz
  
  // Instantiate DUT
  top2 uut (
    .clk_100mhz(clk_100mhz),
    .clk_200mhz(clk_200mhz),
    .start(start),
    .reset_n(reset_n),
    .wr_rst_busy(wr_rst_busy),
    .rd_rst_busy(rd_rst_busy),
    .serial_data(serial_data),
    .serial_valid(serial_valid),
    .serial_ready_in(serial_ready)
  );
  
  // Serial Data Capture
  always @(posedge clk_200mhz) begin
    if (serial_valid && serial_ready) begin
      received_byte <= {received_byte[6:0], serial_data};
      bit_counter <= bit_counter + 1;
      
      if (bit_counter == 7) begin
        if (pixel_counter < `PxelCnt) begin
          pixel_ram[pixel_counter] <= {received_byte[6:0], serial_data};
          pixel_counter <= pixel_counter + 1;
        end
        bit_counter <= 0;
      end
    end
  end
  
  // Timeout process - replaced fork join_any with separate process
  initial begin
    #(100 * 1000 * `Timelimit); // 100 us * timelimit
    if (pixel_counter < `PxelCnt) begin
      timeout = 1;
      $display("Timeout occurred");
    end
  end
  
  // Test Sequence
  integer i;
  initial begin
    // Initialize memory
    for (i = 0; i < `PxelCnt; i = i + 1) 
      pixel_ram[i] = 8'h00; 
    
    // Reset sequence
    //file = $fopen("output_pixels.txt", "w");
    file = $fopen("output_pixels.txt", "w");
    reset_n = 0;
    serial_ready = 0;
    #100;
    reset_n = 1;
    wait (or_busy == 0); // Wait for FIFO reset
    #2000;
    start = 1; // Start processing    
    serial_ready = 1;
    
    // Wait for all pixels or timeout
    wait((pixel_counter == `PxelCnt) || timeout);
    
    if (pixel_counter == `PxelCnt)
      $display("All pixels received");
    
    #(20 * 1000); //wait for 20 us to see waves settle
    
    // Write to file
    $display("Writing %0d pixels to file", pixel_counter);
    for (i = 0; i < pixel_counter; i = i + 1) begin
      $fwrite(file, "%h\n", pixel_ram[i]);
    end
    $fclose(file);
    $finish;
  end
endmodule 