# BhutanBioClims: High-Resolution (250 m) Historical and Future Bioclimatic Variables for Bhutan

## Contents

1. [Disclaimer and Licence](#01-disclaimer-and-licence)
2. [Data Description and Lineage](#02-data-description-and-lineage)
3. [File Naming Conventions](#03-file-naming-conventions)
4. [Data Format and Geographical Coverage](#04-data-format-and-geographical-coverage)
5. [References](#05-references)

---

## 01) Disclaimer and Licence

**Use of these data is subject to the Legal Notice and Disclaimer at:**  
http://www.csiro.au/org/LegalNoticeAndDisclaimer.html

**These data are made available under the conditions of the Creative Commons Attribution 4.0 International Licence:**  
http://creativecommons.org/licenses/by/4.0/

---

## 02) Data Description and Lineage

This collection provides **121 sets of 19 bioclimatic variables** (see Booth et al. 2014 for details and historical context) describing the historical and projected future (CMIP6) climates of Bhutan with a spatial resolution of **250 m**. 

The future 19 bioclimatic variables include:
- **Four Shared Socio-economic Pathways (SSPs):** SSP1-2.6, SSP2-4.5, SSP3-7.0 and SSP5-8.5 (O'Neill et al., 2016; Riahi et al., 2017)
- **Three climatological time-periods:** 2021–2050, 2051–2080, and 2071–2100
- **Ten Global Climate Models (GCMs)**

These data can be used for many applications in environmental and agricultural science.

### Processing Methodology

Each of the 19 bioclimatic variables were generated in R using the `biovars` function from the **dismo** package (Hijmans et al. 2017). This function requires monthly climatologies for maximum temperature, minimum temperature, and precipitation. 

**CMIP6 GCM outputs** were acquired from the Copernicus Climate Change Service (C3S):  
https://cds.climate.copernicus.eu/

The CMIP6 GCM outputs are downscaled against historical data, developed with the national weather station network (Stewart et al. 2017, Stewart et al. 2021), using the **delta change method**. Anomalies were interpolated using **bivariate thin plate splines** (i.e., a function of easting and northing).

### Bioclimatic Variables

A brief description of each bioclimatic variable is provided below:

| Code | Variable Name | Description |
|------|---------------|-------------|
| `bio1` | Mean Annual Temperature | Average of monthly mean temperatures |
| `bio2` | Mean Diurnal Range | Mean of (max temp - min temp) |
| `bio3` | Isothermality | (bio2 / bio7) × 100 |
| `bio4` | Temperature Seasonality | Standard deviation × 100 |
| `bio5` | Max Temperature of Warmest Month | Maximum temperature of the warmest month |
| `bio6` | Min Temperature of Coldest Month | Minimum temperature of the coldest month |
| `bio7` | Temperature Annual Range | bio5 - bio6 |
| `bio8` | Mean Temperature of Wettest Quarter | Mean temperature during the wettest quarter |
| `bio9` | Mean Temperature of Driest Quarter | Mean temperature during the driest quarter |
| `bio10` | Mean Temperature of Warmest Quarter | Mean temperature during the warmest quarter |
| `bio11` | Mean Temperature of Coldest Quarter | Mean temperature during the coldest quarter |
| `bio12` | Annual Precipitation | Total (annual) precipitation |
| `bio13` | Precipitation of Wettest Month | Precipitation in the wettest month |
| `bio14` | Precipitation of Driest Month | Precipitation in the driest month |
| `bio15` | Precipitation Seasonality | Coefficient of variation |
| `bio16` | Precipitation of Wettest Quarter | Precipitation during the wettest quarter |
| `bio17` | Precipitation of Driest Quarter | Precipitation during the driest quarter |
| `bio18` | Precipitation of Warmest Quarter | Precipitation during the warmest quarter |
| `bio19` | Precipitation of Coldest Quarter | Precipitation during the coldest quarter |

### Climate Change Projections

Each of the 19 bioclimatic variables were developed for future climates using the following configurations:

#### 10 Global Climate Models (GCMs)
1. ACCESS-CM2
2. CNRM-CM6-1
3. CNRM-ESM2-1
4. INM-CM4-8
5. INM-CM5-0
6. MIROC-ES2L
7. MIROC6
8. MPI-ESM1-2-LR
9. MRI-ESM2-0
10. NorESM2-MM

#### Three Climatological Time-Periods
- **2021–2050** (near-term future)
- **2051–2080** (mid-century future)
- **2071–2100** (late-century future)

#### Four Shared Socio-economic Pathways (SSPs)
- **SSP1-2.6** (sustainability, low emissions)
- **SSP2-4.5** (middle of the road, intermediate emissions)
- **SSP3-7.0** (regional rivalry, high emissions)
- **SSP5-8.5** (fossil-fueled development, very high emissions)

The SSPs cover conservative (i.e., SSP1-2.6) through to fossil fuel intensive (i.e., SSP5-8.5) scenarios. Please refer to O'Neill et al. (2016) and Riahi et al. (2017) for further details.

---

## 03) File Naming Conventions

The file and folder naming conventions are detailed below.

### Folder Structure

```
<GCM>/<Time period>/<SSP>/
```

**Historical data:**
```
Historical/1986-2015/
```

**Future projections:**
```
<GCM>/2021-2050/<SSP>/
<GCM>/2051-2080/<SSP>/
<GCM>/2071-2100/<SSP>/
```

### File Names

**Future projections:**
```
<GCM>_<Time period>_<SSP>_bio<x>.tif
```

**Historical data:**
```
Historical_1986-2015_bio<x>.tif
```

Where `x` is the bioclimatic variable number (01–19).

### Examples

```
ACCESS-CM2_2021-2050_SSP126_bio01.tif
ACCESS-CM2_2021-2050_SSP245_bio12.tif
Historical_1986-2015_bio01.tif
```

---

## 04) Data Format and Geographical Coverage

### Data Format

| Property | Value |
|----------|-------|
| **Format** | Cloud Optimised GeoTiff (COG) |
| **Spatial Resolution** | 250 m |
| **Coordinate Reference System** | EPSG:5266 (DRUKREF 03 / Bhutan National Grid) |
| **Data Type** | Float32 |
| **NoData Value** | -9999 |
| **Units** | °C (temperature variables), mm (precipitation variables) |

### Geographical Coverage

**Geographic Extent (WGS84):**
- **Latitude:** 26°42′N – 28°12′N
- **Longitude:** 88°42′E – 92°9′E
- **Coverage:** Bhutan National Boundary

**Projected Extent (EPSG:5266 - DRUKREF 03 / Bhutan National Grid):**

| Parameter | Value (meters) |
|-----------|----------------|
| **xmin** | 125,694.5 |
| **xmax** | 460,694.5 |
| **ymin** | 2,954,438.0 |
| **ymax** | 3,125,938.0 |

**Grid Dimensions:**
- **Number of columns:** 1,340
- **Number of rows:** 686
- **Total pixels:** 919,240

---

## 05) References

### Primary References

**Booth et al. (2014)**  
Booth, T. H., H. A. Nix, J. R. Busby, and M. F. Hutchinson. 2014. bioclim: the first species distribution modelling package, its early applications and relevance to most current MaxEnt studies. *Diversity and Distributions* 20:1-9.  
DOI: [10.1111/ddi.12144](https://doi.org/10.1111/ddi.12144)

**Hijmans et al. (2017)**  
Hijmans, R. J., S. Phillips, J. R. Leathwick, and J. Elith. 2017. dismo: Species Distribution Modeling. R package version 1.1-4.  
URL: [https://CRAN.R-project.org/package=dismo](https://CRAN.R-project.org/package=dismo)

**O'Neill et al. (2016)**  
O'Neill, B. C., C. Tebaldi, D. P. van Vuuren, V. Eyring, P. Friedlingstein, G. Hurtt, R. Knutti, E. Kriegler, J. F. Lamarque, J. Lowe, G. A. Meehl, R. Moss, K. Riahi, and B. M. Sanderson. 2016. The Scenario Model Intercomparison Project (ScenarioMIP) for CMIP6. *Geosci. Model Dev.* 9:3461-3482.  
DOI: [10.5194/gmd-9-3461-2016](https://doi.org/10.5194/gmd-9-3461-2016)

**Riahi et al. (2017)**  
Riahi, K., D. P. van Vuuren, E. Kriegler, J. Edmonds, B. C. O'Neill, S. Fujimori, N. Bauer, K. Calvin, R. Dellink, O. Fricko, W. Lutz, A. Popp, J. C. Cuaresma, S. Kc, M. Leimbach, L. Jiang, T. Kram, S. Rao, J. Emmerling, K. Ebi, T. Hasegawa, P. Havlik, F. Humpenöder, L. A. Da Silva, S. Smith, E. Stehfest, V. Bosetti, J. Eom, D. Gernaat, T. Masui, J. Rogelj, J. Strefler, L. Drouet, V. Krey, G. Luderer, M. Harmsen, K. Takahashi, L. Baumstark, J. C. Doelman, M. Kainuma, Z. Klimont, G. Marangoni, H. Lotze-Campen, M. Obersteiner, A. Tabeau, and M. Tavoni. 2017. The Shared Socioeconomic Pathways and their energy, land use, and greenhouse gas emissions implications: An overview. *Global Environmental Change* 42:153-168.

**Stewart et al. (2017)**  
Stewart, S. B., K. Choden, M. Fedrigo, S. H. Roxburgh, R. J. Keenan, and C. R. Nitschke. 2017. The role of topography and the north Indian monsoon on mean monthly climate interpolation within the Himalayan Kingdom of Bhutan. *International Journal of Climatology* 37:897-909.  
DOI: [10.1002/joc.5045](https://doi.org/10.1002/joc.5045)

**Stewart et al. (2021)**  
Stewart, S. B., M. Fedrigo, S. Kasel, S. H. Roxburgh, K. Choden, K. Tenzin, K. Allen, and C. R. Nitschke. 2021. Interpolated climate variables for the Himalayan Kingdom of Bhutan [Raster]. CSIRO. Data Collection.  
DOI: [10.25919/m8yh-gt42](https://doi.org/10.25919/m8yh-gt42)

### Source Data Citation

**Dorji et al. (2025)**  
Dorji, S., Stewart, S., Bajwa, A., Aziz, A., Shabbir, A., & Adkins, S. (2025). High-resolution (250 m) historical and projected (CMIP6) air temperature and precipitation grids for Bhutan (v1) [Data set]. CSIRO.  
DOI: [10.25919/pec2-hs50](https://doi.org/10.25919/pec2-hs50)

---

## Contact and Support

For questions regarding these data, please refer to the source publication or contact the corresponding authors.

**Project Website:** [CSIRO Data Access Portal](https://data.csiro.au/)

---

*Last updated: 2026-02-22*  
*Version: 1.0.0*
