// tb.v

`timescale 1ns/1ns

module TB;

  reg clk;

  reg reset;

  reg S;     // select del MUX



  CPU dut (.clk(clk), .reset(reset), .S(S));



  // Clock: cambia cada 2 unidades de tiempo (ns)

  initial begin

    clk = 1'b0;

    forever #2 clk = ~clk;

  end



  // Reset = 1 en t=0, cambia a 0 en t=3

  initial begin

    reset = 1'b1;

    #3 reset = 1'b0;

  end



  // S = 0 en t=0, cambia a 1 en t=40

  initial begin

    S = 1'b0;

    #40 S = 1'b1;

  end



  // Terminar en t=48

  initial begin

    // opcional: volcado VCD

    $dumpfile("wave.vcd");

    $dumpvars(0, TB);

    #48 $finish;

  end

endmodule

