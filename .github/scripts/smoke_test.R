#!/usr/bin/env Rscript

suppressPackageStartupMessages({
  library(terra)
})

month_tags <- c(
  "01Jan", "02Feb", "03Mar", "04Apr", "05May", "06Jun",
  "07Jul", "08Aug", "09Sep", "10Oct", "11Nov", "12Dec"
)

build_synthetic_input <- function(input_root) {
  model_dir <- file.path(input_root, "SAMPLE_MODEL", "data", "SAMPLE-MODEL", "1986-2015")
  dir.create(model_dir, recursive = TRUE, showWarnings = FALSE)

  template <- rast(nrows = 2, ncols = 2, xmin = 88, xmax = 89, ymin = 27, ymax = 28, crs = "EPSG:4326")
  n <- ncell(template)

  for (i in seq_along(month_tags)) {
    m <- month_tags[i]

    pr <- setValues(template, rep(40 + i, n))
    tmin <- setValues(template, rep(8 + i * 0.2, n))
    tmax <- setValues(template, rep(18 + i * 0.2, n))

    writeRaster(pr, file.path(model_dir, paste0("SAMPLE-MODEL_1986-2015_", m, "_pr.tif")), overwrite = TRUE)
    writeRaster(tmin, file.path(model_dir, paste0("SAMPLE-MODEL_1986-2015_", m, "_tasmin.tif")), overwrite = TRUE)
    writeRaster(tmax, file.path(model_dir, paste0("SAMPLE-MODEL_1986-2015_", m, "_tasmax.tif")), overwrite = TRUE)
  }
}

run_smoke <- function() {
  root <- file.path(tempdir(), "bioclim_smoke")
  input_root <- file.path(root, "input")
  output_root <- file.path(root, "output")

  if (dir.exists(root)) {
    unlink(root, recursive = TRUE, force = TRUE)
  }
  dir.create(root, recursive = TRUE, showWarnings = FALSE)

  build_synthetic_input(input_root)

  args <- c(
    "10_scripts/r/bioclim_master.R",
    "--input_root", input_root,
    "--output_root", output_root,
    "--models", "SAMPLE_MODEL",
    "--periods", "1986-2015",
    "--overwrite", "TRUE",
    "--memfrac", "0.2"
  )

  out <- system2("Rscript", args = args, stdout = TRUE, stderr = TRUE)
  cat(paste(out, collapse = "\n"), "\n")

  status <- attr(out, "status")
  if (is.null(status)) status <- 0
  if (status != 0) {
    stop(sprintf("Smoke run failed with exit status %s", status))
  }

  product_dir <- file.path(output_root, "sample_model", "1986_2015", "historical")
  bio_files <- list.files(
    product_dir,
    pattern = "^bhutan_cmip6_sample_model_historical_1986_2015_bio[0-9]{2}_v1_0\\.tif$",
    full.names = TRUE
  )
  if (length(bio_files) != 19) {
    stop(sprintf("Expected 19 BIO outputs, found %s", length(bio_files)))
  }

  summary_files <- list.files(file.path(output_root, "_logs"),
                              pattern = "^bioclim_summary_.*\\.csv$",
                              full.names = TRUE)
  if (length(summary_files) != 1) {
    stop(sprintf("Expected 1 summary CSV, found %s", length(summary_files)))
  }

  summary_df <- read.csv(summary_files[1], stringsAsFactors = FALSE)
  if (nrow(summary_df) != 19) {
    stop(sprintf("Expected 19 summary rows, found %s", nrow(summary_df)))
  }
}

run_smoke()

