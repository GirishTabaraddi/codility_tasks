@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: CONFIGURATION & PATHS (Relative to this script)
:: =========================================================
pushd %~dp0..
set "REPO_ROOT=%CD%"
popd

:: Toolchain Paths
set "TOOLS_DIR=%REPO_ROOT%\build_tools"
set "MINGW_BIN=%TOOLS_DIR%\MinGW\bin"
set "NINJA_EXE=%TOOLS_DIR%\ninja-win\ninja.exe"

:: CMake Settings
set "SOURCE_DIR=%REPO_ROOT%\src"
set "BUILD_ROOT=%REPO_ROOT%\build"

:: Add MinGW to PATH so the generated .exe can find DLLs (libstdc++, etc.)
set "PATH=%MINGW_BIN%;%PATH%"

:: =========================================================
:: ARGUMENT PARSING 
:: =========================================================

:: CHECK Project Name (Argument 1)
if not "%~1"=="" (
    set "PROJECT_NAME=%~1"
    echo [AUTO] Project selected: !PROJECT_NAME!
    goto CHECK_BUILD_TYPE
)

:: If no argument, run the interactive menu
echo.
echo ==========================================
echo      PROJECT BUILDER (Interactive)
echo ==========================================
set index=0
for /d %%D in ("%SOURCE_DIR%\*") do (
    set /a index+=1
    set "PROJ_!index!=%%~nxD"
    echo   !index!. %%~nxD
)
:ASK_PROJECT
set /p "CHOICE=Select a project [1-%index%]: "
if "!PROJ_%CHOICE%!"=="" goto ASK_PROJECT
set "PROJECT_NAME=!PROJ_%CHOICE%!"

:CHECK_BUILD_TYPE
:: CHECK 2: Build Type (Argument 2)
if not "%~2"=="" (
    set "BUILD_TYPE=%~2"
    echo [AUTO] Build Type selected: !BUILD_TYPE!
    goto START_BUILD
)

:: =========================================================
:: BUILD TYPE SELECTION
:: =========================================================
echo.
echo Select Build Type:
echo   1. Debug   (Default: Symbols, No Optimization)
echo   2. Release (Optimized, Small Size)
set /p "TYPE_CHOICE=Enter choice [1-2]: "

if "%TYPE_CHOICE%"=="2" (
    set "BUILD_TYPE=Release"
) else (
    set "BUILD_TYPE=Debug"
)

:: =========================================================
:: CMAKE CONFIGURATION & BUILD
:: =========================================================
:START_BUILD

set "BUILD_DIR=%BUILD_ROOT%\%PROJECT_NAME%\%BUILD_TYPE%"

echo.
echo [INFO] Building '%PROJECT_NAME%' in %BUILD_TYPE% mode...
echo [INFO] Artifacts will be in: %BUILD_DIR%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: This prevents the "Compiler Changed / Variable Lost" error loop
if exist "%BUILD_DIR%\CMakeCache.txt" del "%BUILD_DIR%\CMakeCache.txt"

:: Run CMake
:: We pass the Compiler paths directly to override any system defaults
cmake -S "%REPO_ROOT%" -B "%BUILD_DIR%" -G "Ninja" ^
    -DCMAKE_MAKE_PROGRAM="%NINJA_EXE%" ^
    -DCMAKE_C_COMPILER="%MINGW_BIN%\gcc.exe" ^
    -DCMAKE_CXX_COMPILER="%MINGW_BIN%\g++.exe" ^
    -DSELECTED_PROJECT="%PROJECT_NAME%" ^
    -DCMAKE_BUILD_TYPE=%BUILD_TYPE%

if %errorlevel% neq 0 (
    echo [ERROR] CMake Configuration failed.
    pause
    exit /b %errorlevel%
)

:: Build
cmake --build "%BUILD_DIR%"

if %errorlevel% neq 0 (
    echo [ERROR] Build failed.
    pause
    exit /b %errorlevel%
)

:: =========================================================
:: RUN EXECUTION
:: =========================================================
echo.
echo Build Successful! 
set /p "RUN=Run the program now? (Y/N): "
if /i "%RUN%"=="Y" (
    echo.
    echo ------------------------------------------------
    echo.
    "%BUILD_DIR%\bin\%PROJECT_NAME%.exe"
    echo.
    echo ------------------------------------------------
)

pause
endlocal