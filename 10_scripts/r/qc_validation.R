suppressPackageStartupMessages({
  library(terra)
  library(sf)
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
input_dir <- file.path(project_root, "03_bioclim_variables", "01_bioclim_by_gcm")
qc_dir <- file.path(project_root, "06_quality_control")
dir.create(qc_dir, recursive = TRUE, showWarnings = FALSE)

files <- list.files(input_dir, pattern = "\\.tif$", recursive = TRUE, full.names = TRUE)
files <- files[grepl("^bhutan_cmip6_.*_bio[0-9]{2}_v1_0\\.tif$", basename(files), ignore.case = TRUE)]
if (length(files) == 0) stop("No raster files found in 03_bioclim_variables/01_bioclim_by_gcm")

ref_file <- files[1]
ref <- rast(ref_file)
ref_res <- res(ref)
ref_ext <- ext(ref)
ref_crs <- crs(ref)

# Use sf for CRS interoperability checks
ref_sf <- st_as_sf(as.polygons(ref_ext, crs = ref_crs))
if (nrow(ref_sf) < 1) stop("Failed to create sf object from reference extent")

rows <- lapply(files, function(f) {
  r <- rast(f)
  e <- ext(r)
  aligned <- compareGeom(ref, r, stopOnError = FALSE, crs = TRUE, ext = TRUE, rowcol = TRUE, res = TRUE)
  na_prop <- as.numeric(global(is.na(r), fun = "mean", na.rm = TRUE)[1, 1])

  data.frame(
    file = f,
    crs_wkt = crs(r),
    nrow = nrow(r),
    ncol = ncol(r),
    xres = res(r)[1],
    yres = res(r)[2],
    xmin = e[1],
    xmax = e[2],
    ymin = e[3],
    ymax = e[4],
    dx_min = e[1] - ref_ext[1],
    dx_max = e[2] - ref_ext[2],
    dy_min = e[3] - ref_ext[3],
    dy_max = e[4] - ref_ext[4],
    aligned_with_reference = aligned,
    na_proportion = na_prop,
    stringsAsFactors = FALSE
  )
})
meta <- bind_rows(rows)

resolution_df <- meta %>%
  select(file, nrow, ncol, xres, yres, aligned_with_reference)
write.csv(resolution_df, file.path(qc_dir, "resolution_check.csv"), row.names = FALSE)

missing_df <- meta %>%
  select(file, na_proportion) %>%
  mutate(na_percent = round(na_proportion * 100, 4))
write.csv(missing_df, file.path(qc_dir, "missing_value_summary.csv"), row.names = FALSE)

crs_unique <- unique(meta$crs_wkt)
bad_n <- sum(!meta$aligned_with_reference)
extent_diff <- meta %>%
  mutate(max_abs_extent_diff = pmax(abs(dx_min), abs(dx_max), abs(dy_min), abs(dy_max))) %>%
  arrange(desc(max_abs_extent_diff))

report_file <- file.path(qc_dir, "raster_alignment_report.txt")
con <- file(report_file, "wt")
writeLines("CMIP6 BIOCLIM Bhutan QC Alignment Report", con)
writeLines(paste0("Generated: ", format(Sys.time(), "%Y-%m-%d %H:%M:%S")), con)
writeLines("", con)
writeLines(paste0("Reference raster: ", ref_file), con)
writeLines(paste0("Reference CRS: ", ref_crs), con)
writeLines(paste0("Reference resolution: ", paste(ref_res, collapse = " x ")), con)
writeLines(paste0("Reference extent: ", paste(as.vector(ref_ext), collapse = ", ")), con)
writeLines("", con)
writeLines(paste0("Total rasters checked: ", nrow(meta)), con)
writeLines(paste0("Unique CRS count: ", length(crs_unique)), con)
writeLines(paste0("Rasters not aligned to reference: ", bad_n), con)
writeLines("", con)

if (length(crs_unique) > 1) {
  writeLines("CRS inconsistency detected:", con)
  for (i in seq_along(crs_unique)) {
    writeLines(paste0(" - CRS_", i, ": ", crs_unique[i]), con)
  }
} else {
  writeLines("CRS consistency check: PASS", con)
}

writeLines("", con)
writeLines("Top 20 rasters by absolute extent difference:", con)
top_n <- head(extent_diff, 20)
for (i in seq_len(nrow(top_n))) {
  msg <- sprintf("%02d | %s | max_abs_extent_diff=%.6f | aligned=%s",
                 i, top_n$file[i], top_n$max_abs_extent_diff[i], top_n$aligned_with_reference[i])
  writeLines(msg, con)
}
close(con)

# Export split reports with canonical names used by audit checks
writeLines(c(
  "Extent check summary",
  paste0("Top extent deviation file: ", extent_diff$file[1]),
  paste0("Max absolute extent deviation: ", round(extent_diff$max_abs_extent_diff[1], 6))
), file.path(qc_dir, "extent_check_report.txt"))

writeLines(c(
  "CRS check summary",
  paste0("Unique CRS count: ", length(crs_unique))
), file.path(qc_dir, "crs_check_report.txt"))

message("QC outputs written to ", qc_dir)

