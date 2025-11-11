module I_MEM (

  input  wire [31:0] addr,

  output wire [31:0] instr

);

  reg [31:0] rom [0:127];

  integer file, i;
  reg [255:0] line;
  reg [7:0] byte0, byte1, byte2, byte3;

  initial begin

    for (i = 0; i < 128; i = i + 1) begin
      rom[i] = 32'd0;
    end

    file = $fopen("preload/phaseIII_code_SPARC.txt", "r");
    
    if (file) begin
      i = 0;
      while (!$feof(file) && i < 128) begin
        if ($fgets(line, file)) begin
          if ($sscanf(line, "%8b %8b %8b %8b", byte0, byte1, byte2, byte3) == 4) begin
            rom[i] = {byte0, byte1, byte2, byte3};
            i = i + 1;
          end
        end
      end
      $fclose(file);
      $display("Cargadas %0d instrucciones desde preload/phaseIII_code_SPARC.txt", i);
      if (i == 0) begin
        $display("ERROR: El archivo preload/phaseIII_code_SPARC.txt está vacío o no contiene instrucciones válidas");
        $display("La simulación continuará con la ROM inicializada a 0");
      end
    end else begin
      $display("ERROR CRÍTICO: No se pudo abrir el archivo preload/phaseIII_code_SPARC.txt");
      $display("El archivo es OBLIGATORIO. Verifica que existe en la ruta correcta.");
      $display("La simulación continuará con la ROM inicializada a 0 (instrucciones nop)");
      $display("Esto puede causar comportamiento inesperado.");
    end

  end



  assign instr = rom[addr[31:2]];

endmodule
