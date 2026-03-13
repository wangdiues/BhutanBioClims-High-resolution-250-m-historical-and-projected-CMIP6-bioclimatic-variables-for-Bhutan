param(
    [string]$ProjectRoot = "",
    [string]$RscriptPath = "C:\Program Files\R\R-4.4.0\bin\Rscript.exe",
    [double]$Memfrac = 0.5,
    [switch]$Overwrite,
    [switch]$CleanOutputs
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$InputRoot = Join-Path $ProjectRoot "01_raw_cmip6_data\01_cmip6_monthly"
$OutputRoot = Join-Path $ProjectRoot "03_bioclim_variables\01_bioclim_by_gcm"
$EnsembleRoot = Join-Path $ProjectRoot "04_ensemble_products"
$McolRoot = Join-Path $ProjectRoot "05_multicollinearity_analysis"
$QcRoot = Join-Path $ProjectRoot "06_quality_control"
$ProcLogRoot = Join-Path $ProjectRoot "07_logs\processing_logs"
$MasterLogRoot = Join-Path $ProcLogRoot "bioclim_master"

$MainScript = Join-Path $ProjectRoot "10_scripts\r\bioclim_master.R"
$EnsembleScript = Join-Path $ProjectRoot "10_scripts\r\build_ensembles.R"
$McolScript = Join-Path $ProjectRoot "10_scripts\r\multicollinearity_screening.R"
$QcScript = Join-Path $ProjectRoot "10_scripts\r\qc_validation.R"
$IntegrityScript = Join-Path $ProjectRoot "10_scripts\ps\03_integrity_check.ps1"

function Assert-Ok($label) {
    if ($LASTEXITCODE -ne 0) {
        throw "$label failed with exit code $LASTEXITCODE"
    }
}

function Assert-NoRootJunk($projectRoot) {
    $junk = @(
        "acces_cm2","cnrm_cm6_1","cnrm_esm2_1","historical","inm_cm4_8","inm_cm5_0",
        "miroc6","miroc_es2l","mpi_esm1_2_lr","mri_esm2_0","noresm2_mm","_ensemble","_logs"
    )
    $found = @()
    foreach ($j in $junk) {
        if (Test-Path (Join-Path $projectRoot $j)) {
            $found += $j
        }
    }
    if ($found.Count -gt 0) {
        throw "Unsafe root artifacts detected: $($found -join ', '). Clean them before running."
    }
}

function Remove-RootJunk($projectRoot) {
    $junk = @(
        "acces_cm2","cnrm_cm6_1","cnrm_esm2_1","historical","inm_cm4_8","inm_cm5_0",
        "miroc6","miroc_es2l","mpi_esm1_2_lr","mri_esm2_0","noresm2_mm","_ensemble","_logs"
    )
    foreach ($j in $junk) {
        $path = Join-Path $projectRoot $j
        if (Test-Path $path) {
            Remove-Item $path -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

function Assert-Canonical03($outputRoot) {
    $forbidden = @("_ensemble", "_logs")
    $bad = @()
    foreach ($f in $forbidden) {
        if (Test-Path (Join-Path $outputRoot $f)) {
            $bad += $f
        }
    }
    if ($bad.Count -gt 0) {
        throw "Non-canonical directories in 03_bioclim_variables: $($bad -join ', ')"
    }
}

if (-not (Test-Path $RscriptPath)) {
    throw "Rscript not found at: $RscriptPath"
}
if (-not (Test-Path $InputRoot)) {
    throw "Input root not found: $InputRoot"
}
if (-not (Test-Path $MainScript)) {
    throw "Main script not found: $MainScript"
}

$overwriteText = if ($Overwrite) { "TRUE" } else { "FALSE" }

if ($CleanOutputs) {
    Remove-RootJunk $ProjectRoot
    Write-Host "Cleaning existing outputs..."
    foreach ($p in @($OutputRoot, $EnsembleRoot, $McolRoot, $QcRoot, $MasterLogRoot)) {
        if (Test-Path $p) {
            Remove-Item (Join-Path $p "*") -Recurse -Force -ErrorAction SilentlyContinue
        } else {
            New-Item -ItemType Directory -Path $p -Force | Out-Null
        }
    }
}

Assert-NoRootJunk $ProjectRoot

Write-Host "Project root: $ProjectRoot"
Write-Host "Input root:   $InputRoot"
Write-Host "Output root:  $OutputRoot"
Write-Host "Log root:     $MasterLogRoot"
Write-Host ""

& $RscriptPath $MainScript `
    --input_root $InputRoot `
    --output_root $OutputRoot `
    --log_root $MasterLogRoot `
    --skip_ensemble TRUE `
    --overwrite $overwriteText `
    --memfrac $Memfrac
Assert-Ok "bioclim_master.R"

& $RscriptPath $EnsembleScript --project_root $ProjectRoot
Assert-Ok "build_ensembles.R"

& $RscriptPath $McolScript --project_root $ProjectRoot --time_slice "1986_2015" --scenario "historical"
Assert-Ok "multicollinearity_screening.R"

& $RscriptPath $QcScript --project_root $ProjectRoot
Assert-Ok "qc_validation.R"

& $IntegrityScript -ProjectRoot $ProjectRoot

Assert-NoRootJunk $ProjectRoot
Assert-Canonical03 $OutputRoot

Write-Host ""
Write-Host "All stages completed successfully."
