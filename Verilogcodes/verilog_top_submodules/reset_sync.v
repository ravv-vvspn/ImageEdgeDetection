module reset_sync (
  input  wire clk,          // Clock 
  input  wire a_reset_n,// Async reset (active-low)
  output wire s_reset_n  // Async Assert, Sync Deassert, reset (active-low)
);
  reg [1:0] sync_reg;

  always @(posedge clk or negedge a_reset_n) begin
    if (!a_reset_n) begin
      sync_reg <= 2'b00;    // Assert reset immediately
    end else begin
      sync_reg <= {sync_reg[0], 1'b1}; // Deassert synchronously
    end
  end

  assign s_reset_n = sync_reg[1]; // Synchronized reset output
endmodule
