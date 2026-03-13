@echo off
REM Test script for bioclim_master.R
REM Test 1: Single model, historical period
setlocal
for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI\
set RSCRIPT_PATH=C:\Program Files\R\R-4.4.0\bin\Rscript.exe
set SCRIPT_PATH=%REPO_ROOT%10_scripts\r\bioclim_master.R
set INPUT_ROOT=%REPO_ROOT%01_raw_cmip6_data\01_cmip6_monthly
set OUTPUT_ROOT=%REPO_ROOT%08_model_ready_layers\99_test_run

echo === Test 1: ACCES_CM2, 1986-2015 (historical) ===
"%RSCRIPT_PATH%" "%SCRIPT_PATH%" ^
  --input_root "%INPUT_ROOT%" ^
  --output_root "%OUTPUT_ROOT%" ^
  --models "ACCES_CM2" ^
  --periods "1986-2015" ^
  --overwrite TRUE

echo === Test complete ===
pause

