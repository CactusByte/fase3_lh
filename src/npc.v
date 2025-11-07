// npc.v

module NPC (

  input  wire        clk,

  input  wire        reset,   // sincrónico

  input  wire        le,

  input  wire [31:0] next_npc,

  output reg  [31:0] npc

);

  always @(posedge clk) begin

    if (reset) npc <= 32'd4;     // requisito: nPC = 4 en reset

    else if (le) npc <= next_npc;

  end

endmodule

