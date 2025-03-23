module bram_fifo_controller (
  input  wire clk_100mhz,    // BRAM clock (100 MHz)
  input  wire reset_n,       // Active-low reset
  input  wire start,       // Start reading from BRAM
  // BRAM Interface
  output wire bram_en,       // BRAM enable
  output wire [12:0] bram_addr, // BRAM address (13-bit)
  input  wire [7:0] bram_data, // BRAM read data
  // Async FIFO Interface
  output wire [7:0] fifo_din, // Data to FIFO
  
  //output wire fifo_wr_en,     // FIFO write enable
  output reg fifo_wr_en,     // FIFO write enable
  
  input  wire fifo_full,       // FIFO full signal
  input  wire fifo_afull       // FIFO almost full signal
);

  reg [12:0] addr_counter;   // Address counter (0 to 4095)
  reg [1:0] state;           // State machine states

  // States
  localparam IDLE  = 2'b00;
  localparam READ  = 2'b01;
  localparam PAUSE = 2'b10;
  localparam DONE = 2'b11;

  always @(posedge clk_100mhz or negedge reset_n) begin
    if (!reset_n) begin
      state <= IDLE;
      addr_counter <= 0;
      fifo_wr_en  <= 0;
    end else begin
    
      fifo_wr_en <= (state == READ) && !fifo_afull;
      
      case (state)
        IDLE: begin          
          addr_counter <= 0;
          if (start) state <= READ; // Start reading immediately
          else state <= IDLE;
        end

        READ: begin
          //if (fifo_full) begin
          if (fifo_afull) begin
          //if (fifo_afull || fifo_full) begin
            state <= PAUSE; // Pause if FIFO is full
          end
          //else if (addr_counter < 4095 && !fifo_full) begin
          else if (addr_counter < 4095 && !fifo_afull) begin
          //else if (addr_counter < 4095 && !fifo_full && !fifo_afull) begin
            addr_counter <= addr_counter + 1; // Increment address
          end           
          else if (addr_counter == 4095) begin
            //addr_counter <= 0; // Wrap around after 4095
            state <= DONE; // Complete after reading BRAM all 4095 locations 
          end
        end

        PAUSE: begin
          //if (!fifo_full) state <= READ; // Resume when FIFO has space
          if (!fifo_afull) state <= READ; // Resume when FIFO has space
          //if (!fifo_full && !fifo_afull) state <= READ; // Resume when FIFO has space
        end
        
        DONE: begin
           state <= DONE;
        end
      endcase
    end
  end

  // Assign outputs
  //assign bram_en = (state == READ); // Enable BRAM during READ state
  assign bram_en = (state == READ) || (state == PAUSE); // Enable BRAM during READ state and PAUSE
  assign bram_addr = addr_counter;
  assign fifo_din = bram_data;
  
  
  //assign fifo_wr_en = (state == READ) && !fifo_full; // Write when not full
  //assign fifo_wr_en = (state == READ) && !fifo_afull; // Write when not full
  //assign fifo_wr_en = (state == READ); // Write when not full
  
endmodule