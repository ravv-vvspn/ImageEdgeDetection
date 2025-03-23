module sobel_filter (
  input  wire clk_200mhz,
  input  wire reset_n,
  // Input Interface
  input  wire [7:0] pixel_in,
  input  wire valid_in,
  output wire ready_out,
  // Output Interface
  output reg  [11:0] pixel_out,
  output reg  valid_out,
  // Pooling Backpressure
  input  wire ready_in
);

  //-----------------------------------------------------------
  // Line Buffers and Window
  //-----------------------------------------------------------
  reg [7:0] line_buffer[0:2][0:63];
  reg [5:0] col_ptr = 0;
  reg [7:0] window[0:2][0:2];
  reg windowdata_valid;

  // Row Counter: Track valid rows loaded into line buffers
  reg [1:0] row_counter;

  // Backpressure Logic
  assign ready_out = ready_in;

  //-----------------------------------------------------------
  // Window Update & Line Buffers
  //-----------------------------------------------------------
  integer i, j;
  always @(posedge clk_200mhz or negedge reset_n) begin
    if (!reset_n) begin
      col_ptr <= 0;
      row_counter <= 0;
      for (i = 0; i < 64; i = i + 1) begin
        line_buffer[0][i] <= 8'd0;
        line_buffer[1][i] <= 8'd0;
        line_buffer[2][i] <= 8'd0;
      end
      
      for (i = 0; i < 3; i = i + 1)
        for (j = 0; j < 3; j = j + 1)
          window[i][j] <= 8'd0;

      windowdata_valid <= 0;
      
      
    end else if (valid_in && ready_in) begin
      line_buffer[2][col_ptr] <= pixel_in;

      // Update window
      if (col_ptr >= 2) begin
        window[2][0] <= line_buffer[2][col_ptr - 2];
        window[2][1] <= line_buffer[2][col_ptr - 1];
        window[2][2] <= line_buffer[2][col_ptr];
        window[1][0] <= line_buffer[1][col_ptr - 2];
        window[1][1] <= line_buffer[1][col_ptr - 1];
        window[1][2] <= line_buffer[1][col_ptr];
        window[0][0] <= line_buffer[0][col_ptr - 2];
        window[0][1] <= line_buffer[0][col_ptr - 1];
        window[0][2] <= line_buffer[0][col_ptr];
        windowdata_valid <= (row_counter >= 2); // Enable only after 2 valid rows
      end else begin
        windowdata_valid <= 0;
      end

      col_ptr <= (col_ptr == 63) ? 0 : col_ptr + 1;

      // Shift line buffers after a row
      if (col_ptr == 63) begin
        for (i = 0; i < 64; i = i + 1) begin
          line_buffer[0][i] <= line_buffer[1][i];
          line_buffer[1][i] <= line_buffer[2][i];
        end
        // Increment row counter after each full row
        if (row_counter < 3) row_counter <= row_counter + 1;
      end
    end else begin
      windowdata_valid <= 0;
    end
  end

  //-----------------------------------------------------------
  // Pipelined Sobel Calculation
  //-----------------------------------------------------------
   // Stage 1
  reg signed [8:0] stg1_Gxsum1, stg1_Gxsum3;   
  reg signed [9:0] stg1_Gxsum2;                
  reg signed [8:0] stg1_Gysum1, stg1_Gysum3;   
  reg signed [9:0] stg1_Gysum2;               
  reg stg1_valid;

  // Stage 2
  reg signed [9:0] stg2_Gxsum1, stg2_Gxsum2;   
  reg signed [9:0] stg2_Gysum1, stg2_Gysum2;   
  reg stg2_valid;

  // Stage 3
  reg signed [10:0] Gx, Gy;    
  reg GxGyvalid;
  
  // Stage 4
  reg [10:0] absGx, absGy; 
  reg absGxGyvalid;

  always @(posedge clk_200mhz or negedge reset_n) begin
    if (!reset_n) begin
      // Reset all pipeline registers
      {stg1_Gxsum1, stg1_Gxsum2, stg1_Gxsum3} <= 0;
      {stg1_Gysum1, stg1_Gysum2, stg1_Gysum3} <= 0;      
      stg1_valid <= 0;
      
      {stg2_Gxsum1, stg2_Gxsum2} <= 0;
      {stg2_Gysum1, stg2_Gysum2} <= 0;
      stg2_valid <= 0;
      
      {Gx, Gy} <= 0;
      GxGyvalid <= 0;
      
      {absGx, absGy} <= 0;
      absGxGyvalid <= 0;
      
      pixel_out <= 0;
      valid_out <= 0;
    end else begin
      //-------------------------------------------------------
      // Pipeline Stage 1: Partial Differences
      //-------------------------------------------------------
      stg1_Gxsum1 <= $signed(window[0][2]) - $signed(window[0][0]);  // 9-bit
      stg1_Gxsum2 <= ($signed(window[1][2]) - $signed(window[1][0])) << 1; // 10-bit
      stg1_Gxsum3 <= $signed(window[2][2]) - $signed(window[2][0]);  // 9-bit

      stg1_Gysum1 <= $signed(window[2][0]) - $signed(window[0][0]);  // 9-bit
      stg1_Gysum2 <= ($signed(window[2][1]) - $signed(window[0][1])) << 1; // 10-bit
      stg1_Gysum3 <= $signed(window[2][2]) - $signed(window[0][2]);  // 9-bit

      stg1_valid <= windowdata_valid;

      //-------------------------------------------------------
      // Pipeline Stage 2: Intermediate Sums
      //-------------------------------------------------------
      // 9-bit + 9-bit = 10-bit (automatic sign extension)
      stg2_Gxsum1 <= stg1_Gxsum1 + stg1_Gxsum3;
      stg2_Gxsum2 <= stg1_Gxsum2;

      stg2_Gysum1 <= stg1_Gysum1 + stg1_Gysum3;
      stg2_Gysum2 <= stg1_Gysum2;

      stg2_valid <= stg1_valid;

      //-------------------------------------------------------
      // Pipeline Stage 3: Final Gradient Calculation
      //-------------------------------------------------------
      Gx <= stg2_Gxsum1 + stg2_Gxsum2;  // 10-bit + 10-bit = 11-bit
      Gy <= stg2_Gysum1 + stg2_Gysum2;
      GxGyvalid <= stg2_valid;
    
      //-------------------------------------------------------
      // Pipeline Stage 4: Absolute Values
      //-------------------------------------------------------
      absGx <= Gx[10] ? (~Gx + 1) : Gx;
      absGy <= Gy[10] ? (~Gy + 1) : Gy;
      absGxGyvalid <= GxGyvalid;

      //-------------------------------------------------------
      // Pipeline Stage 5: Sum and Output
      //-------------------------------------------------------
      pixel_out <= absGx + absGy;
      valid_out <= absGxGyvalid;
    end
  end

endmodule