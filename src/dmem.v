// dmem.v

module D_MEM (

  input  wire        clk,

  input  wire        mem_read,

  input  wire        mem_write,

  input  wire [31:0] addr,

  input  wire [31:0] wdata,

  output wire [31:0] rdata

);

  reg [7:0] ram [0:255]; // bytes

  // lectura de 32 bits little-endian

  assign rdata = mem_read ? { ram[addr+3], ram[addr+2], ram[addr+1], ram[addr+0] } : 32'd0;



  always @(posedge clk) begin

    if (mem_write) begin

      ram[addr+0] <= wdata[7:0];

      ram[addr+1] <= wdata[15:8];

      ram[addr+2] <= wdata[23:16];

      ram[addr+3] <= wdata[31:24];

    end

  end

endmodule

