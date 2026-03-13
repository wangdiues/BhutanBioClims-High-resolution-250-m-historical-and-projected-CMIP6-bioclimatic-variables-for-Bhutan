# Bhutan CMIP6 BIOCLIM Dataset (Canonical Infrastructure)

This repository is organized to the canonical 10-stage climate data infrastructure standard.

## Canonical Structure

```
cmip6_bioclim_bhutan_v1_0/
├── 00_project_metadata/
├── 01_raw_cmip6_data/
├── 02_bias_corrected_data/
├── 03_bioclim_variables/
├── 04_ensemble_products/
├── 05_multicollinearity_analysis/
├── 06_quality_control/
├── 08_model_ready_layers/
└── 10_scripts/
```

## Operational Entry Points

- Main processor: `10_scripts/r/bioclim_master.R`
- Windows runner: `10_scripts/ps/run_production.bat`
- One-command full pipeline: `10_scripts/ps/run_all.ps1` (or `10_scripts/ps/run_all.bat`)
- CI syntax/help/smoke checks: `.github/workflows/R-CMD-check.yaml`
- Smoke test: `.github/scripts/smoke_test.R`

## Run (manual)

```bash
Rscript 10_scripts/r/bioclim_master.R \
  --input_root ./01_raw_cmip6_data/01_cmip6_monthly \
  --output_root ./03_bioclim_variables/01_bioclim_by_gcm
```

```powershell
pwsh -File ./10_scripts/ps/run_all.ps1 -ProjectRoot . -Overwrite -CleanOutputs
```

## Ensemble and SDM Stages

- Ensemble outputs: `04_ensemble_products/ensemble_mean`, `ensemble_standard_deviation`, `ensemble_minimum`, `ensemble_maximum`, `uncertainty_maps`
- Predictor filtering outputs: `05_multicollinearity_analysis/`
- Final model-ready products: `08_model_ready_layers/`

## Metadata Core

Required publication metadata is maintained in `00_project_metadata/`, including:
- `readme.md`
- `data_provenance.md`
- `crs_information.txt`
- `spatial_resolution.txt`
- `variable_units.csv`
- `gcm_inventory.csv`
- `ssp_inventory.csv`
- `temporal_coverage.csv`
- `citation.txt`
- `modeling_guide.html` (detailed HTML guide for future modeling workflows and source acknowledgment)
- `repository_usage_guide.html` (practical file-by-file guide for using this repository safely and reproducibly)

## Publishing

See `PUBLISHING.md` for the recommended publication workflow:
- GitHub for code and metadata
- External hosting for large raster data

