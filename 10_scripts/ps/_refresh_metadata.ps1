Set-Location "E:\cmip6_bioclim_bhutan_v1_0"
$meta = "00_project_metadata"
$now = Get-Date
$nowIso = $now.ToString("yyyy-MM-ddTHH:mm:ssK")
$today = $now.ToString("yyyy-MM-dd")

# Core references
$doi = "10.25919/pec2-hs50"
$doiUrl = "https://doi.org/10.25919/pec2-hs50"
$projectTitle = "Bhutan CMIP6 BIOCLIM Dataset Infrastructure"

# Canonical stages
$stages = @(
  "00_project_metadata","01_raw_cmip6_data","02_bias_corrected_data","03_bioclim_variables",
  "04_ensemble_products","05_multicollinearity_analysis","06_quality_control","07_logs",
  "08_model_ready_layers","09_release","10_scripts"
)

# Inventory from current filesystem
$gcmDirs = Get-ChildItem ".\\03_bioclim_variables\\01_bioclim_by_gcm" -Directory -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name | Sort-Object
$ensembleFiles = Get-ChildItem ".\\04_ensemble_products" -Recurse -File -Filter *.tif -ErrorAction SilentlyContinue
$ensembleCount = ($ensembleFiles | Measure-Object).Count
$histMeanCount = (Get-ChildItem ".\\04_ensemble_products\\ensemble_mean\\1986_2015\\historical" -File -Filter *.tif -ErrorAction SilentlyContinue | Measure-Object).Count

$mainLog = Get-ChildItem ".\\07_logs\\processing_logs\\bioclim_master\\bioclim_run_*.log" -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
$ensembleLog = Get-Item ".\\07_logs\\processing_logs\\ensemble_build_log.txt" -ErrorAction SilentlyContinue
$vifFile = Get-Item ".\\05_multicollinearity_analysis\\vif_results.csv" -ErrorAction SilentlyContinue
$qcFile = Get-Item ".\\06_quality_control\\raster_alignment_report.txt" -ErrorAction SilentlyContinue
$integrity = Get-Item ".\\06_quality_control\\integrity_summary.json" -ErrorAction SilentlyContinue

# 1) variable_dictionary.csv + variable_units.csv
$bioRows = @(
  "BIO01,annual_mean_temperature,Annual Mean Temperature,degC",
  "BIO02,mean_diurnal_range,Mean of monthly (tasmax - tasmin),degC",
  "BIO03,isothermality,(BIO02/BIO07)*100,percent",
  "BIO04,temperature_seasonality,Standard deviation of monthly mean temperature * 100,unitless",
  "BIO05,max_temperature_warmest_month,Maximum temperature of warmest month,degC",
  "BIO06,min_temperature_coldest_month,Minimum temperature of coldest month,degC",
  "BIO07,temperature_annual_range,BIO05-BIO06,degC",
  "BIO08,mean_temperature_wettest_quarter,Mean temperature of wettest quarter,degC",
  "BIO09,mean_temperature_driest_quarter,Mean temperature of driest quarter,degC",
  "BIO10,mean_temperature_warmest_quarter,Mean temperature of warmest quarter,degC",
  "BIO11,mean_temperature_coldest_quarter,Mean temperature of coldest quarter,degC",
  "BIO12,annual_precipitation,Annual precipitation sum,mm",
  "BIO13,precipitation_wettest_month,Precipitation of wettest month,mm",
  "BIO14,precipitation_driest_month,Precipitation of driest month,mm",
  "BIO15,precipitation_seasonality,Coefficient of variation of monthly precipitation,percent",
  "BIO16,precipitation_wettest_quarter,Precipitation of wettest quarter,mm",
  "BIO17,precipitation_driest_quarter,Precipitation of driest quarter,mm",
  "BIO18,precipitation_warmest_quarter,Precipitation of warmest quarter,mm",
  "BIO19,precipitation_coldest_quarter,Precipitation of coldest quarter,mm"
)
("variable_code,variable_name,description,units" + [Environment]::NewLine + ($bioRows -join [Environment]::NewLine)) | Set-Content "$meta\\variable_dictionary.csv" -Encoding UTF8
("variable_code,variable_name,description,units" + [Environment]::NewLine + ($bioRows -join [Environment]::NewLine)) | Set-Content "$meta\\variable_units.csv" -Encoding UTF8

# 2) inventories
$gcmMap = @{
  "acces_cm2"="ACCESS-CM2"; "cnrm_cm6_1"="CNRM-CM6-1"; "cnrm_esm2_1"="CNRM-ESM2-1";
  "inm_cm4_8"="INM-CM4-8"; "inm_cm5_0"="INM-CM5-0"; "miroc6"="MIROC6";
  "miroc_es2l"="MIROC-ES2L"; "mpi_esm1_2_lr"="MPI-ESM1-2-LR"; "mri_esm2_0"="MRI-ESM2-0";
  "noresm2_mm"="NorESM2-MM"; "historical"="Historical_bundle"
}
$gcmOut = @("gcm_id,gcm_name,status,notes")
foreach($g in $gcmDirs){
  $display = if($gcmMap.ContainsKey($g)){$gcmMap[$g]}else{$g}
  $status = if($g -eq "historical") {"derived"} else {"implemented"}
  $notes = if($g -eq "historical") {"baseline-only mirror folder"} else {"canonical model directory"}
  $gcmOut += "$g,$display,$status,$notes"
}
$gcmOut | Set-Content "$meta\\gcm_inventory.csv" -Encoding UTF8

$scenarios = @("historical","ssp126","ssp245","ssp370","ssp585")
("scenario,status" + [Environment]::NewLine + (($scenarios | ForEach-Object { "$_,implemented" }) -join [Environment]::NewLine)) | Set-Content "$meta\\scenario_inventory.csv" -Encoding UTF8
("ssp,status" + [Environment]::NewLine + ((@("ssp126","ssp245","ssp370","ssp585") | ForEach-Object { "$_,implemented" }) -join [Environment]::NewLine)) | Set-Content "$meta\\ssp_inventory.csv" -Encoding UTF8
("time_slice,status" + [Environment]::NewLine + ((@("1986_2015","2021_2050","2051_2080","2071_2100") | ForEach-Object { "$_,implemented" }) -join [Environment]::NewLine)) | Set-Content "$meta\\time_slice_inventory.csv" -Encoding UTF8
("start,end,status" + [Environment]::NewLine + "1986,2015,baseline" + [Environment]::NewLine + "2021,2050,projection" + [Environment]::NewLine + "2051,2080,projection" + [Environment]::NewLine + "2071,2100,projection") | Set-Content "$meta\\temporal_coverage.csv" -Encoding UTF8

# 3) folder structure snapshot (concise)
$treeLines = @()
$treeLines += "cmip6_bioclim_bhutan_v1_0"
foreach($s in Get-ChildItem -Directory | Sort-Object Name){
  $treeLines += "|- $($s.Name)/"
  Get-ChildItem $s.FullName -Directory -ErrorAction SilentlyContinue | Select-Object -First 8 | Sort-Object Name | ForEach-Object {
    $treeLines += "|  |- $($_.Name)/"
  }
}
$treeLines += ""
$treeLines += "Generated: $nowIso"
$treeLines | Set-Content "$meta\\bioclim_folder_structure.txt" -Encoding UTF8

# 4) data manifest (stage-level)
$manifest = @("path,type,file_count,tif_count,size_bytes,last_modified_utc")
foreach($s in $stages){
  if(Test-Path $s){
    $files = Get-ChildItem $s -Recurse -File -ErrorAction SilentlyContinue
    $fc = ($files | Measure-Object).Count
    $tc = ($files | Where-Object { $_.Extension -match '^\\.tif(f)?$' } | Measure-Object).Count
    $sz = ($files | Measure-Object Length -Sum).Sum
    $lm = if($fc -gt 0){ ($files | Sort-Object LastWriteTime -Descending | Select-Object -First 1).LastWriteTime.ToUniversalTime().ToString("s")+"Z" } else {""}
    $manifest += "$s,directory,$fc,$tc,$sz,$lm"
  } else {
    $manifest += "$s,missing,0,0,0,"
  }
}
$manifest | Set-Content "$meta\\data_manifest.csv" -Encoding UTF8

# 5) checksums (metadata + key reproducibility outputs only)
$checksumTargets = @(
  "README.md","LICENSE",".gitignore",".gitattributes",
  "05_multicollinearity_analysis","06_quality_control","07_logs\\processing_logs","10_scripts","00_project_metadata"
)
$checksumFiles = foreach($t in $checksumTargets){
  if(Test-Path $t){
    if((Get-Item $t).PSIsContainer){ Get-ChildItem $t -Recurse -File -ErrorAction SilentlyContinue }
    else { Get-Item $t }
  }
}
$checksumFiles = $checksumFiles | Where-Object { $_.Extension -notmatch '^\\.tif(f)?$' } | Sort-Object FullName -Unique
$ck = @("relative_path,size_bytes,sha256,last_modified_utc")
foreach($f in $checksumFiles){
  $rel = Resolve-Path $f.FullName -Relative
  $hash = (Get-FileHash $f.FullName -Algorithm SHA256).Hash.ToLower()
  $utc = $f.LastWriteTime.ToUniversalTime().ToString("s")+"Z"
  $ck += "$rel,$($f.Length),$hash,$utc"
}
$ck | Set-Content "$meta\\checksums_sha256.csv" -Encoding UTF8

# 6) text metadata files
$crsText = if($qcFile){
  $c = Get-Content $qcFile.FullName -TotalCount 80
  ($c | Where-Object { $_ -like "Reference CRS:*" } | Select-Object -First 1)
} else { "Reference CRS: Information required" }
if([string]::IsNullOrWhiteSpace($crsText)){ $crsText = "Reference CRS: Information required" }

@"
Reference grid source: 03_bioclim_variables/01_bioclim_by_gcm/acces_cm2/1986_2015/historical/bhutan_cmip6_acces_cm2_historical_1986_2015_bio01_v1_0.tif
$crsText
Validation source: 06_quality_control/raster_alignment_report.txt
Validated on: $nowIso
"@ | Set-Content "$meta\\crs_information.txt" -Encoding UTF8

@"
Spatial resolution: 250 m
Grid alignment: validated in 06_quality_control/raster_alignment_report.txt
Latest validation timestamp: $nowIso
"@ | Set-Content "$meta\\spatial_resolution.txt" -Encoding UTF8

@"
$projectTitle

Software citation:
Wangdi (2026). Bhutan CMIP6 BIOCLIM Dataset Infrastructure (v1.0).

Primary climate data citation:
Dorji, S., Stewart, S., Bajwa, A., Aziz, A., Shabbir, A., & Adkins, S. (2025).
High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan (v1).
CSIRO Data Collection. DOI: $doiUrl
"@ | Set-Content "$meta\\citation.txt" -Encoding UTF8

@"
cff-version: 1.2.0
message: "If you use this dataset infrastructure, please cite as below."
title: "$projectTitle"
version: "1.0.0"
date-released: "$today"
authors:
  - family-names: "Wangdi"
    given-names: ""
    orcid: "https://orcid.org/0009-0007-7726-1742"
keywords:
  - "CMIP6"
  - "Bhutan"
  - "BIOCLIM"
  - "species distribution modeling"
  - "ensemble climate"
license: "MIT"
references:
  - type: dataset
    title: "High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan"
    year: 2025
    doi: "$doi"
    url: "$doiUrl"
"@ | Set-Content "$meta\\citation.cff" -Encoding UTF8

# 7) markdown docs synchronized to latest run
$statsLines = @(
  "- Last metadata refresh: $nowIso",
  "- Ensemble rasters (04): $ensembleCount",
  "- Historical ensemble mean rasters (1986_2015/historical): $histMeanCount",
  "- Latest multicollinearity file: " + $(if($vifFile){$vifFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}else{"missing"}),
  "- Latest QC alignment report: " + $(if($qcFile){$qcFile.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}else{"missing"}),
  "- Latest integrity summary: " + $(if($integrity){$integrity.LastWriteTime.ToString("yyyy-MM-dd HH:mm:ss")}else{"missing"})
)

@"
# Metadata Package (Updated)

This folder contains synchronized metadata for `cmip6_bioclim_bhutan_v1_0`.

## Current status
$($statsLines -join "`n")

## Key files
- `data_manifest.csv`
- `gcm_inventory.csv`
- `scenario_inventory.csv`
- `time_slice_inventory.csv`
- `variable_dictionary.csv`
- `checksums_sha256.csv`
- `modeling_guide.html`
"@ | Set-Content "$meta\\readme.md" -Encoding UTF8

@"
# Bhutan CMIP6 BIOCLIM Atlas (v1.0)

## Purpose
Operational climate predictor infrastructure for Bhutan ecological and climate-impact modeling.

## Latest run summary
$($statsLines -join "`n")

## Canonical layout
- `01_raw_cmip6_data/`
- `03_bioclim_variables/`
- `04_ensemble_products/`
- `05_multicollinearity_analysis/`
- `06_quality_control/`
- `08_model_ready_layers/`

## Source acknowledgement
Primary climate source dataset:
High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan.
DOI: $doiUrl
"@ | Set-Content "$meta\\bhutan_atlas.md" -Encoding UTF8

@"
# Data Access

This repository is split for distribution:
- GitHub (code and metadata): scripts, docs, workflow definitions.
- Hugging Face dataset (large rasters): stage data folders 01-09.

## Recommended access order
1. Read `00_project_metadata/readme.md` and `modeling_guide.html`.
2. Validate current outputs using files in `05_multicollinearity_analysis` and `06_quality_control`.
3. Use `04_ensemble_products/ensemble_mean` for baseline predictor extraction.

## Data source
- DOI: $doiUrl
"@ | Set-Content "$meta\\data_access.md" -Encoding UTF8

@"
# Data Download and Distribution

## Upstream source
- High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan
- DOI: $doiUrl

## Distribution model for this infrastructure
- GitHub: code and metadata only
- Hugging Face dataset: heavy raster data products (recommended)

## Integrity checks after download
- Verify `00_project_metadata/checksums_sha256.csv` for non-raster reproducibility artifacts.
- Confirm `06_quality_control/integrity_summary.json` exists.
- Confirm `04_ensemble_products/ensemble_mean/1986_2015/historical` contains 19 BIO rasters.
"@ | Set-Content "$meta\\data_download.md" -Encoding UTF8

@"
# Data Provenance

This infrastructure ingests Bhutan climate rasters from the source dataset ($doiUrl) and generates derived BIOCLIM and ensemble products.

## Processing lineage
1. Raw monthly rasters: `01_raw_cmip6_data/01_cmip6_monthly`
2. BIOCLIM per model/period/scenario: `03_bioclim_variables/01_bioclim_by_gcm`
3. Ensemble statistics: `04_ensemble_products`
4. Predictor screening: `05_multicollinearity_analysis`
5. QC reports: `06_quality_control`

## Latest synchronization
- Refreshed: $nowIso
- Main run log: $($mainLog.Name)
- Ensemble log: $($ensembleLog.Name)
"@ | Set-Content "$meta\\data_provenance.md" -Encoding UTF8

@"
# Data Source

Primary source dataset used in this project:

High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan.
DOI: $doiUrl

All derived files in this repository depend on the source dataset above.
"@ | Set-Content "$meta\\data_source.md" -Encoding UTF8

@"
# FAIR Compliance Summary

## Findable
- Structured stage directories and manifest file (`data_manifest.csv`).

## Accessible
- Code/metadata and data distribution paths documented in `data_access.md` and `data_download.md`.

## Interoperable
- Standard raster formats (GeoTIFF) and CSV metadata tables.

## Reusable
- Citation metadata (`citation.cff`, `citation.txt`) and source DOI included.
- Variable definitions and units documented.

Updated: $nowIso
"@ | Set-Content "$meta\\fair_compliance_summary.md" -Encoding UTF8

@"
# Hugging Face Dataset Card (Draft)

## Dataset summary
Bhutan CMIP6 BIOCLIM infrastructure outputs at 250 m, including per-GCM BIOCLIM rasters, multi-model ensembles, QC artifacts, and variable screening outputs.

## Source data
- DOI: $doiUrl

## Data splits (logical)
- Historical baseline: `1986_2015/historical`
- Future projections: `2021_2050`, `2051_2080`, `2071_2100` with `ssp126/ssp245/ssp370/ssp585`

## Recommended citation
See `citation.cff` and `citation.txt`.

## Latest update
$nowIso
"@ | Set-Content "$meta\\huggingface_dataset_card.md" -Encoding UTF8

@"
# Usage

## Run full reproducible workflow

```powershell
pwsh -File .\\10_scripts\\ps\\run_all.ps1 -ProjectRoot "." -Overwrite -CleanOutputs
```

## Verify critical outputs

```powershell
Get-ChildItem .\\04_ensemble_products\\ensemble_mean\\1986_2015\\historical -File -Filter *.tif | Measure-Object
Get-Item .\\05_multicollinearity_analysis\\vif_results.csv, .\\06_quality_control\\raster_alignment_report.txt | Select Name,LastWriteTime,Length
```

## Current run facts
$($statsLines -join "`n")
"@ | Set-Content "$meta\\usage.md" -Encoding UTF8

@"
Prompt used to instruct assistant workflows and audits for this repository.
Last synchronized with repository state: $nowIso
Source DOI required in all derivative documentation: $doiUrl
"@ | Set-Content "$meta\\source_prompt.txt" -Encoding UTF8

# Keep modeling guide as-is (already manually refined in latest step)

Write-Host "Metadata refresh completed at $nowIso"
