# BIOCLIM Master Processor - Usage Examples

> **Note**: For complete documentation, see [README.md](README.md)

## Quick Start

## Example CLI Commands

### 1. Run All Models, All Periods, All Scenarios (Auto-detect)

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM"
```

### 2. Run Specific Models and Periods

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM" ^
  --models "ACCES_CM2,CNRM_CM6_1,MIROC6" ^
  --periods "1986-2015,2021-2050,2051-2080" ^
  --scenarios "SSP126,SSP245,SSP370,SSP585"
```

### 3. Run Single Model, Single Period (Historical)

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM" ^
  --models "ACCES_CM2" ^
  --periods "1986-2015"
```

### 4. Run Single Model, Single Period, Single Scenario (Future)

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM" ^
  --models "ACCES_CM2" ^
  --periods "2021-2050" ^
  --scenarios "SSP245"
```

### 5. Recompute with Overwrite Enabled

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM" ^
  --overwrite TRUE ^
  --memfrac 0.5
```

### 6. Custom Temp Directory and Memory Settings

```bash
Rscript bioclim_master.R ^
  --input_root "E:\cmip6_bioclim_rasters\CMIP6 climate rasters" ^
  --output_root "E:\cmip6_bioclim_rasters\BIOCLIM" ^
  --tempdir "E:\temp\terra_scratch" ^
  --memfrac 0.4 ^
  --ensemble_stats "mean,median,sd"
```

---

## Expected Input Folder Structure

```
E:\cmip6_bioclim_rasters\CMIP6 climate rasters\
├── ACCES_CM2\
│   └── data\
│       └── ACCESS-CM2\
│           ├── 1986-2015\                        # Historical (no SSP folder)
│           │   ├── ACCESS-CM2_1986-2015_01Jan_pr.tif
│           │   ├── ACCESS-CM2_1986-2015_01Jan_tasmax.tif
│           │   ├── ACCESS-CM2_1986-2015_01Jan_tasmin.tif
│           │   └── ... (all 12 months)
│           ├── 2021-2050\
│           │   ├── SSP126\
│           │   │   ├── ACCESS-CM2_2021-2050_SSP126_01Jan_pr.tif
│           │   │   └── ... (all variables, all months)
│           │   ├── SSP245\
│           │   ├── SSP370\
│           │   └── SSP585\
│           ├── 2051-2080\
│           │   └── (same SSP structure)
│           └── 2071-2100\
│               └── (same SSP structure)
├── CNRM_CM6_1\
│   └── data\
│       └── CNRM-CM6-1\
│           └── (same structure)
├── MIROC6\
│   └── data\
│       └── MIROC6\
│           └── (same structure)
└── ... (other models)
```

---

## Example Output Folder Tree

```
E:\cmip6_bioclim_rasters\BIOCLIM\
│
├── _logs\
│   ├── bioclim_run_20260220_143022.log
│   └── bioclim_summary_20260220_143022.csv
│
├── ACCES_CM2\
│   ├── 1986-2015\
│   │   └── historical\
│   │       ├── BIO01.tif
│   │       ├── BIO02.tif
│   │       ├── BIO03.tif
│   │       ├── BIO04.tif
│   │       ├── BIO05.tif
│   │       ├── BIO06.tif
│   │       ├── BIO07.tif
│   │       ├── BIO08.tif
│   │       ├── BIO09.tif
│   │       ├── BIO10.tif
│   │       ├── BIO11.tif
│   │       ├── BIO12.tif
│   │       ├── BIO13.tif
│   │       ├── BIO14.tif
│   │       ├── BIO15.tif
│   │       ├── BIO16.tif
│   │       ├── BIO17.tif
│   │       ├── BIO18.tif
│   │       └── BIO19.tif
│   │
│   ├── 2021-2050\
│   │   ├── SSP126\
│   │   │   ├── BIO01.tif
│   │   │   ├── BIO02.tif
│   │   │   └── ... (BIO03-BIO19)
│   │   ├── SSP245\
│   │   │   ├── BIO01.tif
│   │   │   └── ... (BIO02-BIO19)
│   │   ├── SSP370\
│   │   │   └── ... (BIO01-BIO19)
│   │   └── SSP585\
│   │       └── ... (BIO01-BIO19)
│   │
│   ├── 2051-2080\
│   │   ├── SSP126\
│   │   │   └── ... (BIO01-BIO19)
│   │   ├── SSP245\
│   │   │   └── ... (BIO01-BIO19)
│   │   ├── SSP370\
│   │   │   └── ... (BIO01-BIO19)
│   │   └── SSP585\
│   │       └── ... (BIO01-BIO19)
│   │
│   └── 2071-2100\
│       ├── SSP126\
│       │   └── ... (BIO01-BIO19)
│       ├── SSP245\
│       │   └── ... (BIO01-BIO19)
│       ├── SSP370\
│       │   └── ... (BIO01-BIO19)
│       └── SSP585\
│           └── ... (BIO01-BIO19)
│
├── CNRM_CM6_1\
│   ├── 1986-2015\
│   │   └── historical\
│   │       └── ... (BIO01-BIO19)
│   └── 2021-2050\
│       └── ... (same structure as ACCES_CM2)
│
├── MIROC6\
│   └── ... (same structure)
│
└── _ensemble\
    ├── 1986-2015\
    │   └── historical\
    │       ├── BIO01_mean.tif
    │       ├── BIO01_median.tif
    │       ├── BIO01_min.tif
    │       ├── BIO01_max.tif
    │       ├── BIO01_sd.tif
    │       ├── BIO02_mean.tif
    │       ├── ... (all BIO variables with all stats)
    │       └── models_included.csv
    │
    ├── 2021-2050\
    │   ├── SSP126\
    │   │   ├── BIO01_mean.tif
    │   │   ├── BIO01_median.tif
    │   │   ├── BIO01_min.tif
    │   │   ├── BIO01_max.tif
    │   │   ├── BIO01_sd.tif
    │   │   ├── ... (all BIO variables)
    │   │   └── models_included.csv
    │   ├── SSP245\
    │   │   └── ... (same structure)
    │   ├── SSP370\
    │   │   └── ... (same structure)
    │   └── SSP585\
    │       └── ... (same structure)
    │
    ├── 2051-2080\
    │   └── ... (same structure)
    │
    └── 2071-2100\
        └── ... (same structure)
```

---

## Example Summary CSV Format

```csv
model,period,scenario,bio_var,n_na,n_nan,n_inf,min_val,max_val,mean_val,status
ACCES_CM2,1986-2015,historical,BIO01,0,0,0,12.3,28.7,21.4,OK
ACCES_CM2,1986-2015,historical,BIO02,0,0,0,5.2,15.8,9.6,OK
ACCES_CM2,1986-2015,historical,BIO03,0,0,0,25.1,89.3,52.7,OK
...
CNRM_CM6_1,2021-2050,SSP245,BIO12,12,0,0,45.2,892.1,312.5,WARNING
```

---

## Example Log File Excerpt

```
[2026-02-20 14:30:22] [INFO] === BIOCLIM Master Processor v1.0.0 ===
[2026-02-20 14:30:22] [INFO] Started: 2026-02-20 14:30:22
[2026-02-20 14:30:22] [INFO] Output root: E:\cmip6_bioclim_rasters\BIOCLIM
[2026-02-20 14:30:22] [INFO] terraOptions: tempdir = C:\Users\DELL\AppData\Local\Temp, memfrac = 0.3
[2026-02-20 14:30:23] [INFO] Auto-detected models: ACCES_CM2, CNRM_CM6_1, MIROC6, MPI-ESM1-2-LR
[2026-02-20 14:30:23] [INFO] === Processing model: ACCES_CM2 ===
[2026-02-20 14:30:24] [INFO] Auto-detected periods for ACCES_CM2 : 1986-2015, 2021-2050, 2051-2080, 2071-2100
[2026-02-20 14:30:24] [INFO] Processing period: 1986-2015
[2026-02-20 14:30:25] [INFO] Processing scenario: historical
[2026-02-20 14:30:26] [INFO] Found 12 files for tasmin
[2026-02-20 14:30:27] [INFO] Found 12 files for tasmax
[2026-02-20 14:30:28] [INFO] Found 12 files for pr
[2026-02-20 14:30:29] [INFO] Detecting units for ACCESS-CM2_1986-2015_01Jan_tasmin.tif
[2026-02-20 14:30:29] [INFO] Temperature in Kelvin (max: 298.45), converting to Celsius
[2026-02-20 14:30:30] [INFO] Detecting units for ACCESS-CM2_1986-2015_01Jan_pr.tif
[2026-02-20 14:30:30] [INFO] Precipitation in kg m-2 s-1 (max: 0.000123), converting to mm/month
[2026-02-20 14:30:35] [INFO] Computing bioclimatic variables...
[2026-02-20 14:30:45] [INFO] Written: E:\cmip6_bioclim_rasters\BIOCLIM\ACCES_CM2\1986-2015\historical\BIO01.tif
[2026-02-20 14:30:46] [INFO] Written: E:\cmip6_bioclim_rasters\BIOCLIM\ACCES_CM2\1986-2015\historical\BIO02.tif
...
[2026-02-20 14:31:20] [INFO] Validating bioclim variables for ACCES_CM2 1986-2015 historical
[2026-02-20 14:31:22] [INFO] Completed ACCES_CM2 1986-2015 historical - 19 files written
[2026-02-20 14:31:23] [INFO] Processing period: 2021-2050
[2026-02-20 14:31:24] [INFO] Auto-detected scenarios for ACCES_CM2 2021-2050 : SSP126, SSP245, SSP370, SSP585
[2026-02-20 14:31:25] [INFO] Processing scenario: SSP126
...
[2026-02-20 14:35:00] [INFO] === Computing Ensembles ===
[2026-02-20 14:35:01] [INFO] Periods for ensemble: 1986-2015, 2021-2050, 2051-2080, 2071-2100
[2026-02-20 14:35:01] [INFO] Scenarios for ensemble: historical, SSP126, SSP245, SSP370, SSP585
[2026-02-20 14:35:02] [INFO] Computing ensemble for 1986-2015 historical
[2026-02-20 14:35:05] [INFO] Ensemble BIO01 - models: ACCES_CM2, CNRM_CM6_1, MIROC6
[2026-02-20 14:35:10] [INFO] Written ensemble: E:\cmip6_bioclim_rasters\BIOCLIM\_ensemble\1986-2015\historical\BIO01_mean.tif
...
[2026-02-20 14:40:00] [INFO] Summary CSV written: E:\cmip6_bioclim_rasters\BIOCLIM\_logs\bioclim_summary_20260220_143022.csv
[2026-02-20 14:40:00] [INFO] Completed: 2026-02-20 14:40:00
```

---

## Notes

### GeoTIFF Specifications
- **Compression**: DEFLATE
- **Predictor**: 2 (horizontal differencing)
- **Tiling**: YES
- **NA Flag**: -9999

### Memory Management
- Uses disk-backed `terra` operations exclusively
- Processes model-by-model, period-by-period, scenario-by-scenario
- Never loads entire dataset into RAM
- Configurable `memfrac` (default: 0.3 = 30% of available memory)

### Unit Detection
- **Temperature**: If max > 150 → Kelvin (subtract 273.15); else Celsius
- **Precipitation**: If max < 5 → kg m⁻² s⁻¹ (multiply by 2,628,000); else mm/month

### Ensemble Requirements
- Minimum 2 models required for ensemble computation
- Stats computed: mean, median, min, max, sd (configurable)
- `models_included.csv` lists which models contributed to each BIO variable

### Filename Pattern Recognition
The script recognizes CMIP6-style filenames:
- `MODEL_PERIOD_01Jan_variable.tif` (historical, no SSP)
- `MODEL_PERIOD_SSP126_01Jan_variable.tif` (future scenarios)

Month extraction uses patterns like `01Jan`, `02Feb`, etc.

