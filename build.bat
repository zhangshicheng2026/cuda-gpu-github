@echo off
setlocal

set "VSWHERE=%ProgramFiles(x86)%\Microsoft Visual Studio\Installer\vswhere.exe"
set "VS="

if exist "%VSWHERE%" (
    for /f "usebackq tokens=*" %%i in (`"%VSWHERE%" -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath`) do set "VS=%%i"
)

if not defined VS (
    echo [ERROR] Visual Studio 2022 with C++ tools not found.
    exit /b 1
)

call "%VS%\VC\Auxiliary\Build\vcvars64.bat"
if errorlevel 1 exit /b 1

if exist "C:\Windows\Temp" (
    set "TEMP=C:\Windows\Temp"
    set "TMP=C:\Windows\Temp"
)

if not exist build mkdir build
nvcc -O3 -arch=sm_120 -o build\matrix_mul.exe matrix_mul.cu
if errorlevel 1 exit /b 1

echo.
echo Build OK: build\matrix_mul.exe
