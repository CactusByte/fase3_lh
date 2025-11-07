// imem.v

module I_MEM (

  input  wire [31:0] addr,      // byte address; usaremos addr[31:2]

  output wire [31:0] instr

);

  reg [31:0] rom [0:63]; // espacio pequeño para demo

  initial begin

    // Cargar el segmento EXACTO del PDF (en orden, empezando en 0)

    rom[0]  = 32'b10001010_00000000_00000000_00000000; // add r0,r0,r5

    rom[1]  = 32'b10000110_10100000_11100000_00000001; // subcc r3,1,r3

    rom[2]  = 32'b11000100_00001000_00000000_00000001; // ldub [r0,r1],r2

    rom[3]  = 32'b11001010_00101000_01100000_00000001; // stb r5,[r1,1]

    rom[4]  = 32'b00010010_10111111_11111111_11111110; // bne -2

    rom[5]  = 32'b00001011_00001111_00001111_00000110; // sethi #3F0F06, r5

    rom[6]  = 32'b01000000_00000000_00000000_00000100; // call +4

    rom[7]  = 32'b10000001_11000000_00000000_00001111; // jmpl r0,r15, r0

    rom[8]  = 32'b10001010_00000000_00000000_00000000; // add r0,r0,r5

    rom[9]  = 32'b10000110_10100000_11100000_00000001; // subcc r3,1,r3

    rom[10] = 32'b11000100_00001000_00000000_00000001; // ldub [r0,r1],r2

    rom[11] = 32'b00000000_00000000_00000000_00000000; // nop

    rom[12] = 32'b00010010_10111111_11111111_11111110; // bne -2

    // resto en 0

  end



  assign instr = rom[addr[31:2]]; // word-aligned

endmodule

