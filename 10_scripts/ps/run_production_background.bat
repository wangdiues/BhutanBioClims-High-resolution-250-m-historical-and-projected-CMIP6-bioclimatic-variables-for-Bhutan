@echo off
REM Production run of bioclim_master.R - BACKGROUND MODE
REM Process ALL models, ALL periods, ALL scenarios
setlocal
for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI\
set RSCRIPT_PATH=C:\Program Files\R\R-4.4.0\bin\Rscript.exe
set SCRIPT_PATH=%REPO_ROOT%10_scripts\r\bioclim_master.R
set INPUT_ROOT=%REPO_ROOT%01_raw_cmip6_data\01_cmip6_monthly
set OUTPUT_ROOT=%REPO_ROOT%03_bioclim_variables\01_bioclim_by_gcm

echo ============================================================
echo BIOCLIM Master Processor - Background Production Run
echo ============================================================
echo.
echo Input:  %INPUT_ROOT%
echo Output: %OUTPUT_ROOT%
echo.
echo Starting at: %date% %time%
echo.
echo The script will run in background. Check the log file for progress.
echo Log: %OUTPUT_ROOT%\_logs\bioclim_run_*.log
echo.

start /B /WAIT "BIOCLIM_Processor" "%RSCRIPT_PATH%" "%SCRIPT_PATH%" ^
  --input_root "%INPUT_ROOT%" ^
  --output_root "%OUTPUT_ROOT%" ^
  --overwrite FALSE ^
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

