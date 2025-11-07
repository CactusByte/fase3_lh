@echo off
REM Script para ejecutar el testbench
if not exist cpu_test (
    echo Error: cpu_test no existe. Ejecuta compile.bat primero.
    exit /b 1
)
vvp cpu_test

