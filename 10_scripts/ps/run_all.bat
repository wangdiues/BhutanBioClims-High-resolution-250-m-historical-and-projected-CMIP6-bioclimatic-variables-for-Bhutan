@echo off
setlocal
for %%I in ("%~dp0..\..") do set REPO_ROOT=%%~fI
set POWERSHELL_EXE=C:\Program Files\PowerShell\7\pwsh.exe
set RUN_ALL_PS1=%REPO_ROOT%\10_scripts\ps\run_all.ps1

if not exist "%RUN_ALL_PS1%" (
  echo ERROR: script not found: %RUN_ALL_PS1%
  exit /b 1
)

if not exist "%POWERSHELL_EXE%" (
  echo ERROR: pwsh not found: %POWERSHELL_EXE%
  exit /b 1
)

"%POWERSHELL_EXE%" -NoProfile -ExecutionPolicy Bypass -File "%RUN_ALL_PS1%" -ProjectRoot "%REPO_ROOT%" -Overwrite -CleanOutputs
exit /b %ERRORLEVEL%
