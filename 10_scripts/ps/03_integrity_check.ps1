param(
    [string]$ProjectRoot = ""
)

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$VersionedRoot = $ProjectRoot
$HashLog = Join-Path $VersionedRoot "07_logs\migration_logs\hash_verification.csv"
$QcDir = Join-Path $VersionedRoot "06_quality_control"

if (-not (Test-Path $HashLog)) {
    throw "Hash log not found: $HashLog"
}

$hashRows = Import-Csv $HashLog
$failed = $hashRows | Where-Object { $_.integrity_ok -ne "True" -and $_.integrity_ok -ne "true" }

$summary = [PSCustomObject]@{
    total_files = $hashRows.Count
    failed_integrity = $failed.Count
    bioclim_by_gcm_files = ($hashRows | Where-Object migration_type -eq 'bioclim_by_gcm').Count
    ensemble_files = ($hashRows | Where-Object migration_type -eq 'ensemble').Count
    raw_monthly_files = ($hashRows | Where-Object migration_type -eq 'raw_monthly').Count
    generated_utc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
}

New-Item -ItemType Directory -Path $QcDir -Force | Out-Null
$summary | ConvertTo-Json | Set-Content -Path (Join-Path $QcDir "integrity_summary.json") -Encoding UTF8

if ($failed.Count -gt 0) {
    $failed | Export-Csv -Path (Join-Path $QcDir "integrity_failures.csv") -NoTypeInformation -Encoding UTF8
    throw "Integrity check failed. See integrity_failures.csv"
}

Write-Host "Integrity check passed. Summary written to integrity_summary.json"

