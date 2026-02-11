@echo off
setlocal EnableDelayedExpansion

:: =========================================================
:: 1. CONFIGURATION & PATHS (Relative to this script)
:: =========================================================
:: Get the root directory (assuming script is in root or build_scripts)
:: Adjust '..' if this script is inside a subfolder
pushd %~dp0..
set "ROOT_DIR=%CD%"
popd

:: Toolchain Paths (From your submodule)
set "TOOLS_DIR=%ROOT_DIR%\build_tools"
set "MINGW_BIN=%TOOLS_DIR%\MinGW\bin"
set "NINJA_EXE=%TOOLS_DIR%\ninja-win\ninja.exe"

:: CMake Settings
set "SOURCE_DIR=%ROOT_DIR%\src"
set "BUILD_ROOT=%ROOT_DIR%\build"

:: Add MinGW to PATH so the generated .exe can find DLLs (libstdc++, etc.)
set "PATH=%MINGW_BIN%;%PATH%"

:: =========================================================
:: 2. PROJECT DISCOVERY (Auto-scan source folder)
:: =========================================================
echo.
echo ==========================================
echo      PROJECT BUILDER (MinGW + Ninja)
echo ==========================================
echo.

set index=0
echo Available Projects:
echo ------------------

:: Loop through subdirectories in 'src'
for /d %%D in ("%SOURCE_DIR%\*") do (
    set /a index+=1
    set "PROJ_!index!=%%~nxD"
    echo   !index!. %%~nxD
)

if %index%==0 (
    echo [ERROR] No projects found in %SOURCE_DIR%
    pause
    exit /b
)

echo.
:ASK_PROJECT
set /p "CHOICE=Select a project [1-%index%]: "
if "!PROJ_%CHOICE%!"=="" goto ASK_PROJECT
set "PROJECT_NAME=!PROJ_%CHOICE%!"

:: =========================================================
:: 3. BUILD TYPE SELECTION
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
:: 4. CMAKE CONFIGURATION & BUILD
:: =========================================================
set "BUILD_DIR=%BUILD_ROOT%\%PROJECT_NAME%\%BUILD_TYPE%"

echo.
echo [INFO] Building '%PROJECT_NAME%' in %BUILD_TYPE% mode...
echo [INFO] Artifacts will be in: %BUILD_DIR%

if not exist "%BUILD_DIR%" mkdir "%BUILD_DIR%"

:: This prevents the "Compiler Changed / Variable Lost" error loop
if exist "%BUILD_DIR%\CMakeCache.txt" del "%BUILD_DIR%\CMakeCache.txt"

:: Run CMake
:: We pass the Compiler paths directly to override any system defaults
cmake -S "%ROOT_DIR%" -B "%BUILD_DIR%" -G "Ninja" ^
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
:: 5. RUN EXECUTION (Optional)
:: =========================================================
echo.
echo Build Successful! 
set /p "RUN=Run the program now? (Y/N): "
if /i "%RUN%"=="Y" (
    echo.
    echo ------------------------------------------------
    "%BUILD_DIR%\bin\%PROJECT_NAME%.exe"
    echo.
    echo ------------------------------------------------
)

pause
endlocal