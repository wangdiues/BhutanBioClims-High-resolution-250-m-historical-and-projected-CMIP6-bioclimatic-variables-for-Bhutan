param(
    [string]$ProjectRoot = "",
    [switch]$IncludeRawMonthly,
    [switch]$ArchiveLegacyAfterVerify
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($ProjectRoot)) {
    $ProjectRoot = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path
}

$VersionedRoot = $ProjectRoot
$SourceBioclim = Join-Path $ProjectRoot "03_bioclim_variables\01_bioclim_by_gcm"
$SourceRaw = Join-Path $ProjectRoot "01_raw_cmip6_data\01_cmip6_monthly"
$TargetProcessed = Join-Path $VersionedRoot "03_bioclim_variables\\01_bioclim_by_gcm"
$TargetEnsemble = Join-Path $VersionedRoot "04_ensemble_products"
$TargetRaw = Join-Path $VersionedRoot "01_raw_cmip6_data\\01_cmip6_monthly"
$LegacyArchive = Join-Path $VersionedRoot "01_raw_cmip6_data\02_original_bioclim_exports"
$LogDir = Join-Path $VersionedRoot "07_logs\migration_logs"
$MapLog = Join-Path $LogDir "migration_map.csv"
$HashLog = Join-Path $LogDir "hash_verification.csv"

New-Item -ItemType Directory -Path $LogDir -Force | Out-Null

function Normalize-Token([string]$x) {
    return (($x.ToLower() -replace '[^a-z0-9]+','_') -replace '^_+|_+$','')
}

function Copy-With-Hash {
    param(
        [string]$SourcePath,
        [string]$TargetPath,
        [string]$Type
    )

    New-Item -ItemType Directory -Path (Split-Path $TargetPath -Parent) -Force | Out-Null
    Copy-Item -Path $SourcePath -Destination $TargetPath -Force

    $h1 = (Get-FileHash -Algorithm SHA256 -Path $SourcePath).Hash.ToLower()
    $h2 = (Get-FileHash -Algorithm SHA256 -Path $TargetPath).Hash.ToLower()
    $ok = ($h1 -eq $h2)

    [PSCustomObject]@{
        migration_type = $Type
        source_path = $SourcePath
        target_path = $TargetPath
        source_sha256 = $h1
        target_sha256 = $h2
        integrity_ok = $ok
        migrated_utc = (Get-Date).ToUniversalTime().ToString("s") + "Z"
    }
}

$rows = @()

# A) Migrate per-GCM BIOCLIM rasters
Get-ChildItem $SourceBioclim -Recurse -File -Filter "BIO*.tif" |
    Where-Object { $_.FullName -notlike "*\_ensemble\*" -and $_.FullName -notlike "*\_logs\*" } |
    ForEach-Object {
        $relative = $_.FullName.Substring($SourceBioclim.Length + 1)
        $parts = $relative -split '[\\/]'
        if ($parts.Count -lt 4) { return }

        $gcm = Normalize-Token $parts[0]
        $timeSlice = Normalize-Token $parts[1]
        $ssp = Normalize-Token $parts[2]
        $bio = Normalize-Token ([System.IO.Path]::GetFileNameWithoutExtension($parts[3]))

        $newName = "bhutan_cmip6_{0}_{1}_{2}_{3}_v1_0.tif" -f $gcm, $ssp, $timeSlice, $bio
        $target = Join-Path $TargetProcessed ("{0}\{1}\{2}\{3}" -f $gcm, $timeSlice, $ssp, $newName)

        $rows += Copy-With-Hash -SourcePath $_.FullName -TargetPath $target -Type "bioclim_by_gcm"
    }

# B) Migrate existing ensemble rasters
$sourceEnsemble = Join-Path $SourceBioclim "_ensemble"
if (Test-Path $sourceEnsemble) {
    Get-ChildItem $sourceEnsemble -Recurse -File -Filter "BIO*_*.tif" | ForEach-Object {
        $relative = $_.FullName.Substring($sourceEnsemble.Length + 1)
        $parts = $relative -split '[\\/]'
        if ($parts.Count -lt 3) { return }

        $timeSlice = Normalize-Token $parts[0]
        $ssp = Normalize-Token $parts[1]

        $base = [System.IO.Path]::GetFileNameWithoutExtension($parts[2]).ToLower()
        $seg = $base -split '_'
        if ($seg.Count -lt 2) { return }

        $bio = Normalize-Token $seg[0]
        $stat = Normalize-Token $seg[1]
        if ($stat -notin @('mean','sd','min','max')) { return }
        $canonicalStat = switch ($stat) {
            'sd' { 'standard_deviation' }
            'min' { 'minimum' }
            'max' { 'maximum' }
            default { 'mean' }
        }

        $newName = "bhutan_cmip6_ensemble_{0}_{1}_{2}_{3}_v1_0.tif" -f $canonicalStat, $ssp, $timeSlice, $bio
        $target = Join-Path $TargetEnsemble ("ensemble_{0}\{1}\{2}\{3}" -f $canonicalStat, $timeSlice, $ssp, $newName)

        $rows += Copy-With-Hash -SourcePath $_.FullName -TargetPath $target -Type "ensemble"
    }
}

# C) Optional raw monthly copy
if ($IncludeRawMonthly -and (Test-Path $SourceRaw)) {
    Get-ChildItem $SourceRaw -Recurse -File -Filter "*.tif" | ForEach-Object {
        $relative = $_.FullName.Substring($SourceRaw.Length + 1)
        $target = Join-Path $TargetRaw $relative
        $rows += Copy-With-Hash -SourcePath $_.FullName -TargetPath $target -Type "raw_monthly"
    }
}

$rows | Export-Csv -Path $HashLog -NoTypeInformation -Encoding UTF8
$rows |
    Select-Object migration_type, source_path, target_path, integrity_ok, migrated_utc |
    Export-Csv -Path $MapLog -NoTypeInformation -Encoding UTF8

$failed = $rows | Where-Object { -not $_.integrity_ok }
if ($failed.Count -gt 0) {
    throw "Integrity verification failed for $($failed.Count) files. See $HashLog"
}

if ($ArchiveLegacyAfterVerify) {
    $timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
    $archiveBioclim = Join-Path $LegacyArchive ("BIOCLIM_legacy_{0}" -f $timestamp)
    New-Item -ItemType Directory -Path $archiveBioclim -Force | Out-Null
    Move-Item -Path $SourceBioclim -Destination $archiveBioclim -Force
}

Write-Host "Migration completed successfully."
Write-Host "Map log: $MapLog"
Write-Host "Hash log: $HashLog"


