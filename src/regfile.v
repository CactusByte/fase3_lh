module RegFile (

  input  wire        clk,

  input  wire        we,

  input  wire [4:0]  waddr,

  input  wire [31:0] wdata,

  input  wire [4:0]  raddr1,

  input  wire [4:0]  raddr2,

  output wire [31:0] rdata1,

  output wire [31:0] rdata2

);

  reg [31:0] regs [31:0];

  integer i;



  initial begin

    for (i=0;i<32;i=i+1) regs[i] = 32'd0;

  end



  always @(posedge clk) begin

    if (we && (waddr != 5'd0))

      regs[waddr] <= wdata;

  end



  assign rdata1 = (raddr1 == 5'd0) ? 32'd0 : regs[raddr1];

  assign rdata2 = (raddr2 == 5'd0) ? 32'd0 : regs[raddr2];

endmodule
