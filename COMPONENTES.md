# Documentación de Componentes del Procesador SPARC Pipeline

Este documento describe detalladamente la funcionalidad de cada componente del procesador pipeline implementado en la carpeta `src/`.

---

## Índice

1. [cpu.v](#cpuv) - Módulo principal del procesador
2. [control.v](#controlv) - Unidad de control
3. [alu.v](#aluv) - Unidad Aritmético-Lógica
4. [regfile.v](#regfilev) - Banco de registros
5. [imem.v](#imemv) - Memoria de instrucciones
6. [dmem.v](#dmemv) - Memoria de datos
7. [pc.v](#pcv) - Contador de programa
8. [npc.v](#npcv) - Siguiente contador de programa
9. [pipe_reg.v](#pipe_regv) - Registro de pipeline genérico
10. [mux2.v](#mux2v) - Multiplexor 2 a 1

---

## cpu.v

### Descripción
Módulo principal que integra todos los componentes del procesador pipeline de 5 etapas (IF, ID, EX, MEM, WB). Implementa la arquitectura SPARC simplificada con soporte para instrucciones básicas.

### Funcionalidad Principal

#### Etapas del Pipeline

1. **IF (Instruction Fetch)**
   - Obtiene la instrucción desde `I_MEM` usando `pc_cur`
   - Guarda `npc_cur` e `instr_IF` en el registro IF/ID

2. **ID (Instruction Decode)**
   - Decodifica la instrucción usando el módulo `Control`
   - Lee operandos del banco de registros (`RegFile`)
   - Calcula targets para branches, calls y jmpl
   - Calcula `branch_taken` comparando `rdata1` y `rdata2`
   - Propaga señales y datos al registro ID/EX

3. **EX (Execute)**
   - Selecciona el próximo PC con prioridades: `jmpl > call > branch_taken > pc+4`
   - Ejecuta operaciones aritméticas en la ALU
   - Propaga resultados al registro ID/EX

4. **MEM (Memory)**
   - Accede a la memoria de datos (`D_MEM`) para load/store
   - Propaga datos al registro EX/MEM

5. **WB (Write Back)**
   - Selecciona entre resultado de ALU o memoria
   - Escribe en el banco de registros

### Señales Importantes

- **pc_target**: Calcula el próximo PC basado en prioridades
  - `jmpl_EX`: Salto indirecto (rs1 + imm)
  - `call_EX`: Llamada a subrutina (npc + imm<<2)
  - `branch_taken_ID`: Branch condicional tomado (npc + imm<<2)
  - `pc_plus4`: Secuencial (pc + 4)

- **Pipeline Registers**:
  - `IF_ID`: 64 bits (npc[31:0], instr[31:0])
  - `ID_EX`: ~280 bits (señales de control, operandos, targets, etc.)
  - `EX_MEM`: 71 bits (alu_y, señales MEM, rd, datos para store)
  - `MEM_WB`: 71 bits (alu_y, mem_rdata, señales WB, rd)

### Características Especiales

- Soporte para instrucciones: `add`, `subcc`, `ldub`, `stb`, `bne`, `sethi`, `call`, `jmpl`, `nop`
- Cálculo de targets en etapa ID para timing correcto
- Comparación de branches en ID (simplificada)
- Impresión de estado del pipeline en cada ciclo de reloj

---

## control.v

### Descripción
Unidad de control que decodifica las instrucciones y genera todas las señales de control necesarias para cada etapa del pipeline.

### Entradas
- `instr[31:0]`: Instrucción de 32 bits a decodificar

### Salidas

#### Señales para etapa EX:
- `alu_op_EX[3:0]`: Operación de la ALU (0=ADD, 1=SUB, 2=AND, 3=OR, 4=XOR, 5=PASSB)
- `alu_src_EX`: Selector de fuente ALU (0=registro, 1=inmediato)
- `branch_EX`: Señal de branch (bne)
- `call_EX`: Señal de call
- `jmpl_EX`: Señal de jmpl

#### Señales para etapa MEM:
- `mem_read_MEM`: Lectura de memoria
- `mem_write_MEM`: Escritura de memoria

#### Señales para etapa WB:
- `reg_write_WB`: Escritura en banco de registros
- `mem_to_reg_WB`: Selector de fuente para WB (0=ALU, 1=MEM)

#### Otros:
- `imm_ext[31:0]`: Inmediato extendido con signo (16 bits → 32 bits)
- `rs1[4:0]`, `rs2[4:0]`, `rd[4:0]`: Direcciones de registros fuente y destino
- `keyword[79:0]`: Nombre de la instrucción para impresión

### Instrucciones Soportadas

| Opcode (bits 31:24) | Instrucción | Descripción |
|---------------------|-------------|-------------|
| `10001010` | `add` | Suma de registros |
| `10000110` | `subcc` | Resta con flags (usa inmediato) |
| `11000100` | `ldub` | Load byte sin signo |
| `11001010` | `stb` | Store byte |
| `00010010` | `bne` | Branch si no es igual |
| `00001011` | `sethi` | Set high bits |
| `01000000` | `call` | Llamada a subrutina |
| `10000001` | `jmpl` | Jump and link |
| `00000000` | `nop` | No operation |

### Funcionamiento

1. Extrae el opcode de los bits [31:24] de la instrucción
2. Usa un `case` statement para decodificar cada instrucción
3. Genera las señales de control apropiadas para cada etapa
4. Extrae campos de la instrucción (rs1, rs2, rd, inmediato)
5. Extiende el inmediato con signo desde 16 a 32 bits

---

## alu.v

### Descripción
Unidad Aritmético-Lógica que ejecuta operaciones aritméticas y lógicas.

### Entradas
- `alu_op[3:0]`: Código de operación
- `a[31:0]`: Operando A
- `b[31:0]`: Operando B

### Salidas
- `y[31:0]`: Resultado de la operación
- `zf`: Zero flag (1 si resultado es cero, 0 en caso contrario)

### Operaciones Soportadas

| Código | Operación | Descripción |
|--------|-----------|-------------|
| `0000` | ADD | `y = a + b` |
| `0001` | SUB | `y = a - b` |
| `0010` | AND | `y = a & b` |
| `0011` | OR | `y = a \| b` |
| `0100` | XOR | `y = a ^ b` |
| `0101` | PASSB | `y = b` (passthrough, usado en sethi) |
| Otros | - | `y = 0` |

### Características

- **Combinacional**: Todas las operaciones son combinacionales (sin reloj)
- **Zero Flag**: Se calcula automáticamente como `(y == 0)`
- **Ancho**: 32 bits para todos los operandos y resultados

---

## regfile.v

### Descripción
Banco de registros de 32 registros de 32 bits. Implementa el comportamiento especial de SPARC donde el registro r0 (g0) siempre es cero.

### Entradas
- `clk`: Reloj del sistema
- `we`: Write enable (habilitación de escritura)
- `waddr[4:0]`: Dirección del registro destino
- `wdata[31:0]`: Dato a escribir
- `raddr1[4:0]`: Dirección del primer registro fuente
- `raddr2[4:0]`: Dirección del segundo registro fuente

### Salidas
- `rdata1[31:0]`: Dato del primer registro fuente
- `rdata2[31:0]`: Dato del segundo registro fuente

### Funcionamiento

1. **Inicialización**: Todos los registros se inicializan a 0
2. **Lectura**: Las lecturas son combinacionales (sin reloj)
3. **Escritura**: Sincrónica en flanco positivo de reloj
4. **Registro r0 (g0)**: 
   - Siempre lee 0 (incluso si se intenta escribir)
   - Las escrituras a r0 se ignoran

### Características Especiales

- **Dual-port read**: Permite leer dos registros simultáneamente
- **Single-port write**: Una escritura por ciclo
- **r0 hardwired to zero**: Comportamiento estándar de SPARC

---

## imem.v

### Descripción
Memoria de instrucciones (ROM) que almacena el programa a ejecutar. Carga las instrucciones desde un archivo de texto al inicializar.

### Entradas
- `addr[31:0]`: Dirección de byte (se usa `addr[31:2]` para direccionamiento word-aligned)

### Salidas
- `instr[31:0]`: Instrucción de 32 bits en la dirección especificada

### Funcionamiento

1. **Inicialización**:
   - Inicializa toda la ROM a 0
   - Abre el archivo `preload/phaseIII_code_SPARC.txt`
   - Lee línea por línea el archivo
   - Parsea cada línea con formato: `"10001010 00000000 00000000 00000000"` (4 grupos de 8 bits)
   - Carga las instrucciones en la ROM
   - Muestra mensaje de confirmación con el número de instrucciones cargadas

2. **Lectura**:
   - Acceso combinacional (sin reloj)
   - Direccionamiento word-aligned: `instr = rom[addr[31:2]]`

### Formato del Archivo

Cada línea del archivo debe tener el formato:
```
10001010 00000000 00000000 00000000
```
Donde cada grupo de 8 bits representa un byte de la instrucción de 32 bits.

### Fallback

Si no se puede abrir el archivo, carga valores por defecto hardcodeados.

---

## dmem.v

### Descripción
Memoria de datos (RAM) para almacenar y recuperar datos. Implementa acceso byte-addressable con lectura de 32 bits.

### Entradas
- `clk`: Reloj del sistema
- `mem_read`: Señal de lectura
- `mem_write`: Señal de escritura
- `addr[31:0]`: Dirección de byte
- `wdata[31:0]`: Dato a escribir

### Salidas
- `rdata[31:0]`: Dato leído

### Funcionamiento

1. **Lectura** (combinacional):
   - Si `mem_read = 1`, lee 4 bytes consecutivos
   - Formato little-endian: `rdata = {ram[addr+3], ram[addr+2], ram[addr+1], ram[addr+0]}`
   - Si `mem_read = 0`, retorna 0

2. **Escritura** (sincrónica):
   - En flanco positivo de reloj, si `mem_write = 1`
   - Escribe los 4 bytes en formato little-endian:
     - `ram[addr+0] = wdata[7:0]`
     - `ram[addr+1] = wdata[15:8]`
     - `ram[addr+2] = wdata[23:16]`
     - `ram[addr+3] = wdata[31:24]`

### Características

- **Tamaño**: 256 bytes (0-255)
- **Byte-addressable**: Cada dirección apunta a un byte
- **Little-endian**: El byte menos significativo está en la dirección más baja

---

## pc.v

### Descripción
Registro del Contador de Programa (Program Counter). Almacena la dirección de la instrucción actual.

### Entradas
- `clk`: Reloj del sistema
- `reset`: Reset sincrónico
- `le`: Load enable (habilitación de carga)
- `next_pc[31:0]`: Próximo valor del PC

### Salidas
- `pc[31:0]`: Valor actual del PC

### Funcionamiento

- **Reset**: Si `reset = 1`, `pc = 0`
- **Carga**: Si `reset = 0` y `le = 1`, `pc = next_pc`
- **Mantiene**: Si `reset = 0` y `le = 0`, mantiene el valor actual

### Características

- Sincrónico (actualiza en flanco positivo de reloj)
- En este diseño, `le` está siempre en 1 (sin stalls)

---

## npc.v

### Descripción
Registro del Siguiente Contador de Programa (Next Program Counter). Almacena la dirección de la siguiente instrucción secuencial.

### Entradas
- `clk`: Reloj del sistema
- `reset`: Reset sincrónico
- `le`: Load enable
- `next_npc[31:0]`: Próximo valor del nPC

### Salidas
- `npc[31:0]`: Valor actual del nPC

### Funcionamiento

- **Reset**: Si `reset = 1`, `npc = 4` (requisito de SPARC)
- **Carga**: Si `reset = 0` y `le = 1`, `npc = next_npc`
- **Mantiene**: Si `reset = 0` y `le = 0`, mantiene el valor actual

### Diferencia con PC

- En reset, `npc = 4` mientras que `pc = 0`
- Esto permite que después del reset, la primera instrucción tenga `npc = 4` disponible para cálculos de branches/calls

---

## pipe_reg.v

### Descripción
Registro de pipeline genérico parametrizable. Usado para almacenar datos entre etapas del pipeline.

### Parámetros
- `W`: Ancho del registro en bits (default: 32)

### Entradas
- `clk`: Reloj del sistema
- `reset`: Reset sincrónico
- `din[W-1:0]`: Dato de entrada

### Salidas
- `dout[W-1:0]`: Dato de salida

### Funcionamiento

- **Reset**: Si `reset = 1`, `dout = 0` (todos los bits en 0)
- **Carga**: Si `reset = 0`, `dout = din` en cada flanco positivo de reloj

### Uso en el Pipeline

Este módulo se instancia múltiples veces con diferentes anchos:
- `IF_ID`: W=64 (npc + instrucción)
- `ID_EX`: W=~280 (todas las señales y datos de ID)
- `EX_MEM`: W=71 (resultado ALU + señales MEM + datos)
- `MEM_WB`: W=71 (resultado ALU + dato MEM + señales WB)

### Características

- Parametrizable: Permite diferentes anchos según la etapa
- Sincrónico: Actualiza en flanco positivo de reloj
- Reset: Limpia el registro a 0

---

## mux2.v

### Descripción
Multiplexor 2 a 1 parametrizable. Selecciona entre dos entradas según una señal de control.

### Parámetros
- `W`: Ancho de los datos en bits (default: 32)

### Entradas
- `a[W-1:0]`: Entrada A
- `b[W-1:0]`: Entrada B
- `s`: Señal de selección

### Salidas
- `y[W-1:0]`: Salida seleccionada

### Funcionamiento

- **Combinacional**: `y = s ? b : a`
- Si `s = 0`, selecciona `a`
- Si `s = 1`, selecciona `b`

### Uso en el Diseño

Se usa principalmente para:
- Selección del próximo PC (con override manual mediante señal `S`)
- Selección de fuente ALU (registro vs inmediato)
- Selección de fuente para Write Back (ALU vs memoria)

### Características

- Parametrizable: Permite diferentes anchos de datos
- Combinacional: Sin reloj, respuesta inmediata
- Simple y eficiente

---

## Flujo de Datos General

```
┌─────┐
│ PC  │───┐
└─────┘   │
          ▼
      ┌──────┐
      │ I_MEM│───► IF/ID ──► Control ──► RegFile
      └──────┘              │
                            ▼
                         ID/EX ──► ALU ──► EX/MEM ──► D_MEM ──► MEM/WB ──► RegFile
                            │                                    │
                            └────────── PC Selection ───────────┘
```

---

## Notas de Implementación

1. **Pipeline sin stalls**: Este diseño no implementa detección de hazards ni stalls. Asume que no hay dependencias de datos problemáticas.

2. **Timing**: Los targets de branches/calls/jmpl se calculan en ID para que el PC se actualice correctamente en el siguiente ciclo.

3. **Comparación de branches**: Se hace una comparación simple en ID (`rdata1 == rdata2`) para determinar si un branch se toma.

4. **Prioridad de PC**: El próximo PC se selecciona con prioridad: `jmpl > call > branch_taken > pc+4`.

5. **Registro r0**: Siempre retorna 0 y las escrituras se ignoran, siguiendo el estándar SPARC.

---

## Referencias

- Arquitectura SPARC simplificada
- Pipeline de 5 etapas estándar
- Formato de instrucciones personalizado para este proyecto

