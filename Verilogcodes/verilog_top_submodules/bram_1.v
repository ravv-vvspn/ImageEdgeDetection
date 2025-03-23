module bram_1 (
    input wire clka,
    input wire ena,
    input wire wea,
    input wire [12:0] addra,
    input wire [7:0] dina,
    output wire [7:0] douta
);

// Instantiating the VHDL BRAM inside Verilog
blk_mem_gen_0 bram_inst (
    .clka(clka),       // Clock
    .ena(ena),         // Enable
    .wea({wea}),       // Write Enable (Converted to 1-bit vector)
    .addra(addra),     // Address (13-bit)
    .dina(dina),       // Data Input (8-bit)
    .douta(douta)      // Data Output (8-bit)
);

endmodule
