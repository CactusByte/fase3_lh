@echo off
REM Script de compilación para el procesador
iverilog -o cpu_test src/cpu.v src/control.v src/alu.v src/regfile.v src/dmem.v src/imem.v src/mux2.v src/pc.v src/npc.v src/pipe_reg.v tb.v
if %errorlevel% == 0 (
    echo Compilación exitosa. Ejecuta: vvp cpu_test
) else (
    echo Error en la compilación
)

