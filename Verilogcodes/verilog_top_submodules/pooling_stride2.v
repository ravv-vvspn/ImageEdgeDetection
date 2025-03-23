module average_pooling_stride2 ( // Produces 31x31 image
  input  wire clk_200mhz,
  input  wire reset_n,
  // Input Interface
  input  wire [11:0] pixel_in,
  input  wire valid_in,
  output wire ready_out,  // To Sobel
  // Output Interface
  output reg  [7:0] pixel_out,
  output reg  valid_out,
  // Serializer Backpressure
  input  wire ready_in    // From Serializer
);

  
  //-----------------------------------------------------------
  // Row Buffers and Window (Stride=2)
  //-----------------------------------------------------------
  reg [11:0] row_buffer[0:1][0:61]; // Stores two full rows (62 columns)
  reg [5:0] col_ptr;                // 0-61 (covers all columns)
  reg [11:0] window[0:1][0:1];      // 2x2 window
  reg windowdata_valid;
  
  // Row Counter: Track valid rows loaded into buffers
  reg [5:0] row_counter; // 0-61 (covers all rows
  
  assign ready_out = ready_in; // Direct backpressure pass-through

  //-----------------------------------------------------------
  // Buffer & Window Update Logic (Stride=2)
  //-----------------------------------------------------------
  integer i, j;
  always @(posedge clk_200mhz or negedge reset_n) begin
  
    if (!reset_n) begin
      col_ptr <= 0;
      row_counter <= 0;
      // Clear buffers and window
      for (i = 0; i < 62; i = i + 1) begin
        row_buffer[0][i] <= 12'd0;
        row_buffer[1][i] <= 12'd0;
      end
      for (i = 0; i < 2; i = i + 1) begin
        for (j = 0; j < 2; j = j + 1) begin
          window[i][j] <= 12'd0;
        end
      end
      windowdata_valid <= 0;
      
      
    end else if (valid_in) begin
    
      // Store pixel in row buffer
      row_buffer[1][col_ptr] <= pixel_in;

      // Update window every 2 columns (stride=2)
      if (col_ptr >= 1 && row_counter >= 1 && col_ptr[0] == 1'b1 && row_counter[0] == 1'b1) begin // Check LSB for odd
        window[1][0] <= row_buffer[1][col_ptr - 1];
        window[1][1] <= row_buffer[1][col_ptr];
        window[0][0] <= row_buffer[0][col_ptr - 1];
        window[0][1] <= row_buffer[0][col_ptr];
        windowdata_valid <= 1;
      end else begin
        windowdata_valid <= 0;
      end

      // Increment column pointer (wrap at 61)
      col_ptr <= (col_ptr == 61) ? 0 : col_ptr + 1;

      // Shift rows after completing a full row
      if (col_ptr == 61) begin
        for (i = 0; i < 62; i = i + 1) begin
          row_buffer[0][i] <= row_buffer[1][i];
        end
        row_counter <= row_counter + 1; 
      end
    end else begin
      windowdata_valid <= 0;
    end
  end

  //-----------------------------------------------------------
  // Pipelined Average Calculation (Same as Before)
  //-----------------------------------------------------------
  reg [12:0] suma, sumb;
  reg sum_ab_valid;
  reg [13:0] sum;
  reg sum_valid;
  wire [11:0] avg = sum[13:2]; // Divide by 4

  always @(posedge clk_200mhz or negedge reset_n) begin
    if (!reset_n) begin
      suma <= 0;
      sumb <= 0;
      sum <= 0;
      pixel_out <= 0;
      sum_ab_valid <= 0;
      sum_valid <= 0;
      valid_out <= 0;
    end else begin
      // Stage 1: Sum rows
      suma <= window[0][0] + window[0][1];
      sumb <= window[1][0] + window[1][1];
      sum_ab_valid <= windowdata_valid;

      // Stage 2: Total sum
      sum <= suma + sumb;
      sum_valid <= sum_ab_valid;

      // Stage 3: Clamp to 8 bits
      pixel_out <= (avg > 255) ? 255 : avg[7:0];
      valid_out <= sum_valid;
    end
  end

endmodule
