# Usage

## Run full reproducible workflow

`powershell
pwsh -File .\\10_scripts\\ps\\run_all.ps1 -ProjectRoot "." -Overwrite -CleanOutputs
`

## Verify critical outputs

`powershell
Get-ChildItem .\\04_ensemble_products\\ensemble_mean\\1986_2015\\historical -File -Filter *.tif | Measure-Object
Get-Item .\\05_multicollinearity_analysis\\vif_results.csv, .\\06_quality_control\\raster_alignment_report.txt | Select Name,LastWriteTime,Length
`

## Current run facts
- Last metadata refresh: 2026-02-22T17:14:58+06:00
- Ensemble rasters (04): 988
- Historical ensemble mean rasters (1986_2015/historical): 19
- Latest multicollinearity file: 
2026-02-22 16:46:03
- Latest QC alignment report: 
2026-02-22 16:43:36
- Latest integrity summary: 
2026-02-22 16:07:30
