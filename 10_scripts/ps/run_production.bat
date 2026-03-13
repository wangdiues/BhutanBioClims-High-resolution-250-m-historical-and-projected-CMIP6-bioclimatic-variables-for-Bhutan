@echo off
REM Production run of bioclim_master.R
REM Process ALL models, ALL periods, ALL scenarios
setlocal

echo ============================================================
echo BIOCLIM Master Processor - Full Production Run
echo ============================================================
echo.
echo NOTE: Edit this file to update paths for your system
echo.

REM ============================================
REM STEP 1: CONFIGURE PATHS FOR YOUR SYSTEM
REM ============================================
for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI\

REM Set INPUT_ROOT to your CMIP6 data location
set INPUT_ROOT=%REPO_ROOT%01_raw_cmip6_data\01_cmip6_monthly

REM Set OUTPUT_ROOT to your desired output location
set OUTPUT_ROOT=%REPO_ROOT%03_bioclim_variables\01_bioclim_by_gcm

REM Set RSCRIPT_PATH to your R installation
set RSCRIPT_PATH=C:\Program Files\R\R-4.4.0\bin\Rscript.exe
set SCRIPT_PATH=%REPO_ROOT%10_scripts\r\bioclim_master.R
REM ============================================

echo Using configuration:
echo   Input:  %INPUT_ROOT%
echo   Output: %OUTPUT_ROOT%
echo   Script: %SCRIPT_PATH%
echo   R:      %RSCRIPT_PATH%
echo.
echo Starting at: %date% %time%
echo.

REM Check if R exists
if not exist "%RSCRIPT_PATH%" (
    echo ERROR: Rscript not found at %RSCRIPT_PATH%
    echo Please edit this file and update RSCRIPT_PATH
    pause
    exit /b 1
)

REM Check if input exists
if not exist "%INPUT_ROOT%" (
    echo ERROR: Input directory not found: %INPUT_ROOT%
    echo Please populate 01_raw_cmip6_data\01_cmip6_monthly
    pause
    exit /b 1
)

REM Check if script exists
if not exist "%SCRIPT_PATH%" (
    echo ERROR: Script not found: %SCRIPT_PATH%
    pause
    exit /b 1
)

"%RSCRIPT_PATH%" "%SCRIPT_PATH%" ^
  --input_root "%INPUT_ROOT%" ^
  --output_root "%OUTPUT_ROOT%" ^
  --overwrite TRUE ^
  --memfrac 0.5

echo.
echo ============================================================
echo Run completed at: %date% %time%
echo ============================================================
echo.
echo Check output in: %OUTPUT_ROOT%
echo Check logs in:   %OUTPUT_ROOT%\_logs
echo.
pause

