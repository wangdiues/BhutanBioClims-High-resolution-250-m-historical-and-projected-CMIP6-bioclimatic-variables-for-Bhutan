suppressPackageStartupMessages({
  library(terra)
  library(dplyr)
})

get_script_path <- function() {
  args <- commandArgs(trailingOnly = FALSE)
  file_arg <- args[grepl("^--file=", args)]
  if (length(file_arg) == 0) return(NULL)
  sub("^--file=", "", file_arg[1])
}

parse_cli <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  parsed <- list(project_root = NULL)
  i <- 1
  while (i <= length(args)) {
    if (args[i] == "--project_root" && i < length(args)) {
      parsed$project_root <- args[i + 1]
      i <- i + 2
    } else {
      i <- i + 1
    }
  }
  parsed
}

detect_project_root <- function(cli_root = NULL) {
  if (!is.null(cli_root) && nzchar(cli_root)) {
    return(normalizePath(cli_root, winslash = "/", mustWork = FALSE))
  }
  script_path <- get_script_path()
  if (!is.null(script_path)) {
    return(normalizePath(file.path(dirname(script_path), "..", ".."), winslash = "/", mustWork = FALSE))
  }
  normalizePath(getwd(), winslash = "/", mustWork = FALSE)
}

opts <- parse_cli()
project_root <- detect_project_root(opts$project_root)
input_root <- file.path(project_root, "03_bioclim_variables", "01_bioclim_by_gcm")
out_root <- file.path(project_root, "04_ensemble_products")
log_dir <- file.path(project_root, "07_logs", "processing_logs")
dir.create(log_dir, recursive = TRUE, showWarnings = FALSE)
log_file <- file.path(log_dir, "ensemble_build_log.txt")

all_files <- list.files(input_root, pattern = "\\.tif$", recursive = TRUE, full.names = TRUE)
all_files <- all_files[grepl("^bhutan_cmip6_.*_bio[0-9]{2}_v1_0\\.tif$", basename(all_files), ignore.case = TRUE)]
if (length(all_files) == 0) stop("No input rasters found in 03_bioclim_variables/01_bioclim_by_gcm")

parse_meta <- function(f) {
  rel <- gsub("\\\\", "/", sub(paste0("^", gsub("\\\\", "/", input_root), "/"), "", gsub("\\\\", "/", f)))
  p <- strsplit(rel, "/", fixed = TRUE)[[1]]
  if (length(p) < 4) return(NULL)

  data.frame(
    file = f,
    gcm = p[1],
    time_slice = p[2],
    ssp = p[3],
    bio = sub("^.*_(bio[0-9]{2})_v1_0\\.tif$", "\\1", tolower(basename(f))),
    stringsAsFactors = FALSE
  )
}

align_to_reference <- function(ref, candidate, method = "bilinear") {
  if (compareGeom(ref, candidate, stopOnError = FALSE, crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE)) {
    return(candidate)
  }

  same_crs <- FALSE
  ref_crs <- suppressWarnings(terra::crs(ref, proj = TRUE))
  cand_crs <- suppressWarnings(terra::crs(candidate, proj = TRUE))
  if (!is.na(ref_crs) && !is.na(cand_crs) && nzchar(ref_crs) && nzchar(cand_crs)) {
    same_crs <- identical(ref_crs, cand_crs)
  }

  if (same_crs) {
    return(resample(candidate, ref, method = method))
  }
  project(candidate, ref, method = method)
}

meta <- bind_rows(lapply(all_files, parse_meta))
if (nrow(meta) == 0) stop("Could not parse input metadata from file paths")

meta <- meta %>% filter(tolower(gcm) != "historical")
if (nrow(meta) == 0) stop("No valid GCM rasters after filtering non-GCM historical mirror directory")

groups <- meta %>% group_by(time_slice, ssp, bio) %>% group_split()

con <- file(log_file, "wt")
writeLines(paste("Ensemble build started:", Sys.time()), con)

for (g in groups) {
  ts <- g$time_slice[1]
  sp <- g$ssp[1]
  bio <- g$bio[1]

  if (nrow(g) < 2) {
    writeLines(sprintf("SKIP %s %s %s | only %d GCM", ts, sp, bio, nrow(g)), con)
    next
  }

  ref <- rast(g$file[1])
  aligned_layers <- list(ref)
  aligned_gcms <- c(g$gcm[1])
  dropped <- character(0)

  if (nrow(g) > 1) {
    for (i in 2:nrow(g)) {
      candidate <- tryCatch(rast(g$file[i]), error = function(e) e)
      if (inherits(candidate, "error")) {
        dropped <- c(dropped, g$gcm[i])
        writeLines(sprintf("DROP_MODEL %s %s %s %s | read error: %s", ts, sp, bio, g$gcm[i], candidate$message), con)
        next
      }

      aligned <- tryCatch(
        align_to_reference(ref, candidate, method = "bilinear"),
        error = function(e) e
      )

      if (inherits(aligned, "error")) {
        dropped <- c(dropped, g$gcm[i])
        writeLines(sprintf("DROP_MODEL %s %s %s %s | alignment error: %s", ts, sp, bio, g$gcm[i], aligned$message), con)
        next
      }

      aligned_layers[[length(aligned_layers) + 1]] <- aligned
      aligned_gcms <- c(aligned_gcms, g$gcm[i])
    }
  }

  if (length(aligned_layers) < 2) {
    writeLines(sprintf("SKIP %s %s %s | <2 usable GCM after alignment", ts, sp, bio), con)
    next
  }

  stack <- rast(aligned_layers)
  names(stack) <- aligned_gcms
  if (length(dropped) > 0) {
    writeLines(sprintf("WARN %s %s %s | dropped models: %s", ts, sp, bio, paste(unique(dropped), collapse = ",")), con)
  }

  stats <- c("mean", "standard_deviation", "minimum", "maximum")

  for (stat in stats) {
    out_dir <- file.path(out_root, paste0("ensemble_", stat), ts, sp)
    dir.create(out_dir, recursive = TRUE, showWarnings = FALSE)
    out_name <- sprintf("bhutan_cmip6_ensemble_%s_%s_%s_%s_v1_0.tif", stat, sp, ts, bio)
    out_file <- file.path(out_dir, out_name)
    if (file.exists(out_file)) {
      writeLines(sprintf("SKIP_WRITE %s %s %s %s | output exists", ts, sp, bio, stat), con)
      next
    }

    stat_raster <- tryCatch(
      {
        if (stat == "mean") {
          mean(stack, na.rm = TRUE)
        } else if (stat == "standard_deviation") {
          app(stack, sd, na.rm = TRUE)
        } else if (stat == "minimum") {
          min(stack, na.rm = TRUE)
        } else if (stat == "maximum") {
          max(stack, na.rm = TRUE)
        } else {
          stop("Unknown stat: ", stat)
        }
      },
      error = function(e) e
    )

    if (inherits(stat_raster, "error")) {
      writeLines(sprintf("FAIL %s %s %s %s | %s", ts, sp, bio, stat, stat_raster$message), con)
      next
    }

    writeRaster(
      stat_raster, out_file,
      overwrite = TRUE,
      filetype = "GTiff",
      gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"),
      NAflag = -9999
    )
  }

  writeLines(sprintf("DONE %s %s %s | models=%d", ts, sp, bio, nrow(g)), con)
}

writeLines(paste("Ensemble build completed:", Sys.time()), con)
close(con)

message("Ensemble outputs written to ", out_root)

