@echo off
setlocal enabledelayedexpansion
cd /D "%~dp0"
set "WORKSPACE_DIR=%~dp0"
if "%WORKSPACE_DIR:~-1%"=="\" set "WORKSPACE_DIR=%WORKSPACE_DIR:~0,-1%"

set "BUILD_DIR=%WORKSPACE_DIR%\build"
set "RAYLIB_SRC_DIR=%WORKSPACE_DIR%\raylib"
set "RAYLIB_BUILD_DIR=%BUILD_DIR%\raylib"

set "MODE=debug"

for %%a in (%*) do set "%%~a=1"

if "%debug%"=="1"   set "MODE=debug"
if "%release%"=="1" set "MODE=release"

if not exist "%RAYLIB_BUILD_DIR%" (
    echo [INFO] Raylib build folder not found. Building raylib in RELEASE mode...

    cmake -S "%RAYLIB_SRC_DIR%" -B "%RAYLIB_BUILD_DIR%" ^
          -DPLATFORM=Desktop ^
          -DBUILD_EXAMPLES=OFF ^
          -DCUSTOMIZE_BUILD=ON

    cmake --build "%RAYLIB_BUILD_DIR%" --config Release

    if !errorlevel! neq 0 (
        echo [ERROR] CMake failed to compile Raylib.
        exit /b !errorlevel!
    )
) else (
    echo [INFO] Raylib cache exists. Skipping library compilation.
)


set "CC=clang"
set "INCLUDES=-I"%RAYLIB_SRC_DIR%\src" -I"%RAYLIB_SRC_DIR%\src\external""
set "RAYLIB_STATIC_LIB="%RAYLIB_BUILD_DIR%\raylib\Release\raylib.lib""
set "SYSTEM_LIBS=-luser32 -lgdi32 -lwinmm -lshell32 -lopengl32 -Xlinker /NODEFAULTLIB:MSVCRT"

set "RELEASE_FLAGS=-O3 -DNDEBUG=1"
set "DEBUG_FLAGS=-g -O0 -DDEBUG=1"

set "COMMON_FLAGS=-Wall -std=c23 -DUNICODE -D_UNICODE -D_CRT_SECURE_NO_WARNINGS -MJ compile_commands.raw.json"

if "%MODE%"=="debug" (
    set "OPTIONS=%COMMON_FLAGS% %DEBUG_FLAGS%"
) else (
    set "OPTIONS=%COMMON_FLAGS% %RELEASE_FLAGS%"
)

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"
pushd "%BUILD_DIR%"

    %CC% %OPTIONS% %INCLUDES% "%WORKSPACE_DIR%\main.c" %RAYLIB_STATIC_LIB% %SYSTEM_LIBS% -o visualizer.exe

    if %errorlevel% neq 0 (
        popd
        exit /b %errorlevel%
    )

    if exist "compile_commands.raw.json" (
        powershell -Command "(Get-Content compile_commands.raw.json -Raw).Trim().TrimEnd(',') | ForEach-Object { '[' + $_ + ']' }" > compile_commands.json
        del compile_commands.raw.json
    )

    if "%run%"=="1"     visualizer.exe

popd

endlocal