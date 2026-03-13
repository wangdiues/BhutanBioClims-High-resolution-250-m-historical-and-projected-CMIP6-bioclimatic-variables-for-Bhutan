@echo off
REM Re-run ensemble computation only (after fixing stats bug)
setlocal
for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI\
set RSCRIPT_PATH=C:\Program Files\R\R-4.4.0\bin\Rscript.exe
set SCRIPT_PATH=%REPO_ROOT%10_scripts\r\bioclim_master.R
set INPUT_ROOT=%REPO_ROOT%01_raw_cmip6_data\01_cmip6_monthly
set OUTPUT_ROOT=%REPO_ROOT%03_bioclim_variables\01_bioclim_by_gcm

echo ============================================================
echo BIOCLIM - Ensemble Regeneration
echo ============================================================
echo.

"%RSCRIPT_PATH%" "%SCRIPT_PATH%" ^
  --input_root "%INPUT_ROOT%" ^
  --output_root "%OUTPUT_ROOT%" ^
  --overwrite TRUE ^
  --memfrac 0.5

echo.
echo ============================================================
echo Ensemble regeneration complete
echo ============================================================
pause

