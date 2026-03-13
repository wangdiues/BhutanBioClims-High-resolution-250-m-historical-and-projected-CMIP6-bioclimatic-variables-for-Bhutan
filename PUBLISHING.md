# Publishing Guide

This project should be published in two parts:

1. GitHub repository for code, metadata, and workflow files.
2. External dataset host for large raster outputs and other heavy artifacts.

The current repository already reflects that split:

- Keep in GitHub: `README.md`, `LICENSE`, `.github/`, `00_project_metadata/`, `10_scripts/`
- Keep out of GitHub: `01_raw_cmip6_data/` through `09_release/`, plus `*.tif`, `*.tiff`, `*.vrt`

## 1. Prepare the code repository

Before publishing:

- Review `README.md`
- Review `00_project_metadata/citation.cff`
- Review `00_project_metadata/data_access.md`
- Review `00_project_metadata/data_download.md`
- Confirm `.gitignore` still excludes heavy data folders

This folder is not currently an initialized Git repository, so start there:

```powershell
cd E:\cmip6_bioclim_bhutan_v1_0
git init
git add README.md LICENSE .gitignore .gitattributes PUBLISHING.md
git add .github 00_project_metadata 10_scripts
git commit -m "Initial public release: code and metadata only"
```

Then create an empty GitHub repository and connect it:

```powershell
git remote add origin https://github.com/<your-user>/<your-repo>.git
git branch -M main
git push -u origin main
```

## 2. Publish the data separately

This repository contains many large raster files. Do not push those into the GitHub code repository.

Recommended dataset contents for external hosting:

- `01_raw_cmip6_data/`
- `02_bias_corrected_data/`
- `03_bioclim_variables/`
- `04_ensemble_products/`
- `05_multicollinearity_analysis/`
- `06_quality_control/`
- `07_logs/`
- `08_model_ready_layers/`
- `09_release/`
- `00_project_metadata/data_manifest.csv`
- `00_project_metadata/checksums_sha256.csv`
- `00_project_metadata/huggingface_dataset_card.md`

Recommended host:

- Hugging Face Dataset repo for the raster archive

Suggested dataset layout:

- Keep the stage-based folder structure unchanged
- Add the dataset card from `00_project_metadata/huggingface_dataset_card.md`
- Include checksums and manifest files with the upload

## 3. Create a release version

Once the GitHub code repository is pushed:

```powershell
git tag v1.0.0
git push origin v1.0.0
```

Use `09_release/v1_0_0/changelog.md` as the basis for the GitHub release notes.

## 4. Link the two publications

After both are live:

- Add the dataset URL to `README.md`
- Add the dataset URL to `00_project_metadata/data_access.md`
- Add the dataset URL to `00_project_metadata/data_download.md`
- If you mint a DOI later, add it to `00_project_metadata/citation.cff`

## 5. Recommended publication order

1. Clean the code repository so it only contains publishable code and metadata.
2. Push the GitHub repository.
3. Upload the heavy data to the external dataset host.
4. Create the `v1.0.0` GitHub release.
5. Update metadata files with the final public links.

## Practical recommendation

For this project, the simplest public setup is:

- GitHub: reproducible pipeline, metadata, citation, and release notes
- Hugging Face: rasters and QC outputs
- Optional Zenodo later: DOI for the GitHub release
