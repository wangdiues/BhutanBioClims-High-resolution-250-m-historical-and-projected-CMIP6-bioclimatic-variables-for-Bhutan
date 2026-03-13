#!/usr/bin/env Rscript

# =============================================================================
# BIOCLIM_MASTER.R
# Production-grade CLI for generating BIO1-BIO19 from CMIP6 monthly rasters
# =============================================================================

suppressPackageStartupMessages({
  library(terra)
})

# =============================================================================
# GLOBAL CONSTANTS
# =============================================================================

VERSION <- "1.0.0"
LOG_FILE <- NULL
SUMMARY_DATA <- list()

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

init_log <- function(log_root, output_root) {
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  if (!dir.exists(log_root)) {
    dir.create(log_root, recursive = TRUE)
  }
  LOG_FILE <<- file.path(log_root, paste0("bioclim_run_", timestamp, ".log"))
  
  # Initialize summary data
  SUMMARY_DATA <<- list(
    timestamp = timestamp,
    records = list()
  )
  
  log_msg(paste("=== BIOCLIM Master Processor v", VERSION, " ===", sep = ""))
  log_msg(paste("Started:", Sys.time()))
  log_msg(paste("Output root:", output_root))
}

log_msg <- function(msg, level = "INFO") {
  timestamp <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")
  line <- sprintf("[%s] [%s] %s", timestamp, level, msg)
  cat(line, "\n", file = stderr())
  if (!is.null(LOG_FILE)) {
    cat(line, "\n", file = LOG_FILE, append = TRUE)
  }
}

log_summary_record <- function(model, period, scenario, bio_var, n_na, n_nan, 
                                n_inf, min_val, max_val, mean_val) {
  record <- list(
    model = model,
    period = period,
    scenario = scenario,
    bio_var = bio_var,
    n_na = n_na,
    n_nan = n_nan,
    n_inf = n_inf,
    min_val = min_val,
    max_val = max_val,
    mean_val = mean_val,
    status = ifelse(n_na > 0 || n_nan > 0 || n_inf > 0, "WARNING", "OK")
  )
  records <- SUMMARY_DATA$records
  records[[length(records) + 1]] <- record
  SUMMARY_DATA$records <<- records
}

write_summary_csv <- function(log_root) {
  if (length(SUMMARY_DATA$records) == 0) {
    log_msg("No summary records to write", "WARN")
    return()
  }
  
  # Convert list to data frame
  df <- do.call(rbind, lapply(SUMMARY_DATA$records, function(r) {
    data.frame(
      model = r$model,
      period = r$period,
      scenario = r$scenario,
      bio_var = r$bio_var,
      n_na = r$n_na,
      n_nan = r$n_nan,
      n_inf = r$n_inf,
      min_val = r$min_val,
      max_val = r$max_val,
      mean_val = r$mean_val,
      status = r$status,
      stringsAsFactors = FALSE
    )
  }))
  
  summary_file <- file.path(log_root,
                            paste0("bioclim_summary_", SUMMARY_DATA$timestamp, ".csv"))
  write.csv(df, summary_file, row.names = FALSE)
  log_msg(paste("Summary CSV written:", summary_file))
}

# =============================================================================
# CLI ARGUMENT PARSING
# =============================================================================

parse_args <- function() {
  args <- commandArgs(trailingOnly = TRUE)
  
  # Default values
  defaults <- list(
    input_root = NULL,
    output_root = NULL,
    log_root = NULL,
    models = NULL,
    periods = NULL,
    scenarios = NULL,
    ensemble_stats = c("mean", "median", "min", "max", "sd"),
    skip_ensemble = FALSE,
    overwrite = FALSE,
    memfrac = 0.3,
    tempdir = tempdir()
  )
  
  parsed <- defaults
  
  i <- 1
  while (i <= length(args)) {
    if (args[i] == "--input_root" && i < length(args)) {
      parsed$input_root <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--output_root" && i < length(args)) {
      parsed$output_root <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--log_root" && i < length(args)) {
      parsed$log_root <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--models" && i < length(args)) {
      parsed$models <- strsplit(args[i + 1], ",")[[1]]
      i <- i + 2
    } else if (args[i] == "--periods" && i < length(args)) {
      parsed$periods <- strsplit(args[i + 1], ",")[[1]]
      i <- i + 2
    } else if (args[i] == "--scenarios" && i < length(args)) {
      parsed$scenarios <- strsplit(args[i + 1], ",")[[1]]
      i <- i + 2
    } else if (args[i] == "--ensemble_stats" && i < length(args)) {
      parsed$ensemble_stats <- strsplit(args[i + 1], ",")[[1]]
      i <- i + 2
    } else if (args[i] == "--overwrite" && i < length(args)) {
      parsed$overwrite <- as.logical(args[i + 1])
      i <- i + 2
    } else if (args[i] == "--memfrac" && i < length(args)) {
      parsed$memfrac <- as.numeric(args[i + 1])
      i <- i + 2
    } else if (args[i] == "--tempdir" && i < length(args)) {
      parsed$tempdir <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--skip_ensemble" && i < length(args)) {
      parsed$skip_ensemble <- as.logical(args[i + 1])
      i <- i + 2
    } else if (args[i] %in% c("--help", "-h")) {
      print_help()
      quit(status = 0)
    } else {
      i <- i + 1
    }
  }
  
  # Validate required arguments
  if (is.null(parsed$input_root)) {
    stop("--input_root is required")
  }
  if (is.null(parsed$output_root)) {
    stop("--output_root is required")
  }
  validate_output_root(parsed$output_root)
  if (is.null(parsed$log_root) || !nzchar(parsed$log_root)) {
    parsed$log_root <- file.path(parsed$output_root, "_logs")
  }
  
  parsed
}

validate_output_root <- function(output_root) {
  resolved_output <- normalizePath(output_root, winslash = "/", mustWork = FALSE)
  resolved_cwd <- normalizePath(getwd(), winslash = "/", mustWork = FALSE)
  if (identical(resolved_output, resolved_cwd)) {
    stop(
      "Refusing unsafe --output_root pointing to current working directory. ",
      "Use ./03_bioclim_variables/01_bioclim_by_gcm or another dedicated output folder."
    )
  }
}

print_help <- function() {
  cat("
BIOCLIM Master Processor v1.0.0
================================

Usage: Rscript bioclim_master.R [OPTIONS]

Required:
  --input_root    Root directory containing CMIP6 climate rasters
  --output_root   Root directory for BIOCLIM outputs

Optional:
  --models        Comma-separated list of models (default: auto-detect all)
  --periods       Comma-separated list of periods (default: auto-detect all)
  --scenarios     Comma-separated list of SSP scenarios (default: auto-detect all)
  --ensemble_stats Comma-separated stats for ensemble (default: mean,median,min,max,sd)
  --skip_ensemble Skip ensemble computation in this script (TRUE/FALSE, default: FALSE)
  --overwrite     Overwrite existing outputs (default: FALSE)
  --memfrac       Memory fraction for terra (default: 0.3)
  --tempdir       Temporary directory for terra (default: system temp)
  --log_root      Directory for run logs and summary CSV (default: <output_root>/_logs)

Example:
  Rscript bioclim_master.R --input_root ./CMIP6 --output_root ./BIOCLIM
")
}

# =============================================================================
# FOLDER SCANNING
# =============================================================================

normalize_model_name <- function(name) {
  # Normalize hyphens and underscores
  gsub("_", "-", toupper(name))
}

canonical_model_id <- function(name) {
  gsub("-", "_", tolower(name))
}

canonical_period_id <- function(period) {
  gsub("-", "_", period)
}

canonical_scenario_id <- function(scenario) {
  tolower(scenario)
}

scan_models <- function(input_root) {
  models <- list.dirs(input_root, recursive = FALSE, full.names = FALSE)
  # Filter out non-model directories and files
  models <- models[!grepl("^_|^\\.|^logs$|\\.txt$|\\.csv$", models, ignore.case = TRUE)]
  # Verify each has a data subdirectory (CMIP6 structure)
  valid_models <- character(0)
  for (m in models) {
    data_dir <- file.path(input_root, m, "data")
    if (dir.exists(data_dir)) {
      valid_models <- c(valid_models, m)
    }
  }
  log_msg(paste("Auto-detected models:", paste(valid_models, collapse = ", ")))
  valid_models
}

scan_periods <- function(input_root, model) {
  model_dir <- find_model_directory(input_root, model)
  if (is.null(model_dir)) {
    return(character(0))
  }
  
  # Navigate to data/MODEL_NAME structure
  data_dir <- file.path(model_dir, "data")
  if (!dir.exists(data_dir)) {
    return(character(0))
  }
  
  # Find the model-named subdirectory under data
  model_subdirs <- list.dirs(data_dir, recursive = FALSE, full.names = TRUE)
  if (length(model_subdirs) == 0) {
    return(character(0))
  }
  
  # Use first subdirectory (should be model-named)
  model_data_dir <- model_subdirs[1]
  
  periods <- list.dirs(model_data_dir, recursive = FALSE, full.names = FALSE)
  # Filter out non-period directories
  periods <- periods[!grepl("^_|^\\.", periods, ignore.case = TRUE)]
  
  # Normalize historical period naming
  periods <- sapply(periods, function(p) {
    if (grepl("historical", p, ignore.case = TRUE)) {
      "historical"
    } else {
      p
    }
  })
  
  log_msg(paste("Auto-detected periods for", model, ":", paste(periods, collapse = ", ")))
  periods
}

scan_scenarios <- function(input_root, model, period) {
  model_dir <- find_model_directory(input_root, model)
  if (is.null(model_dir)) {
    return(character(0))
  }
  
  # Navigate to data/MODEL_NAME/PERIOD
  data_dir <- file.path(model_dir, "data")
  model_subdirs <- list.dirs(data_dir, recursive = FALSE, full.names = TRUE)
  if (length(model_subdirs) == 0) {
    return(character(0))
  }
  model_data_dir <- model_subdirs[1]
  
  # Find period directory
  period_dir <- file.path(model_data_dir, period)
  if (!dir.exists(period_dir)) {
    # Try to find with different naming
    period_dirs <- list.dirs(model_data_dir, recursive = FALSE, full.names = TRUE)
    period_dir <- period_dirs[grepl(period, basename(period_dirs), ignore.case = TRUE)][1]
  }
  
  if (!dir.exists(period_dir)) {
    return(character(0))
  }
  
  # Check for scenario subdirectories (SSP folders)
  scenarios <- list.dirs(period_dir, recursive = FALSE, full.names = FALSE)
  scenarios <- scenarios[!grepl("^_|^\\.", scenarios, ignore.case = TRUE)]
  
  # Filter to SSP folders only
  ssp_scenarios <- scenarios[grepl("^ssp", scenarios, ignore.case = TRUE)]
  
  if (length(ssp_scenarios) > 0) {
    log_msg(paste("Auto-detected scenarios for", model, period, ":", 
                  paste(ssp_scenarios, collapse = ", ")))
    return(ssp_scenarios)
  }
  
  # No SSP subdirs - this is historical period (no scenario)
  return(NULL)
}

find_model_directory <- function(input_root, model) {
  # Try exact match first
  model_dir <- file.path(input_root, model)
  if (dir.exists(model_dir)) {
    return(model_dir)
  }
  
  # Try normalized name (hyphen vs underscore)
  normalized <- gsub("-", "_", model)
  model_dir <- file.path(input_root, normalized)
  if (dir.exists(model_dir)) {
    return(model_dir)
  }
  
  normalized <- gsub("_", "-", model)
  model_dir <- file.path(input_root, normalized)
  if (dir.exists(model_dir)) {
    return(model_dir)
  }
  
  # Search subdirectories
  all_dirs <- list.dirs(input_root, recursive = TRUE, full.names = TRUE)
  for (d in all_dirs) {
    base <- basename(d)
    if (normalize_model_name(base) == normalize_model_name(model)) {
      return(d)
    }
  }
  
  return(NULL)
}

get_model_data_path <- function(input_root, model, period, scenario = NULL) {
  # Navigate the CMIP6 folder structure:
  # input_root/MODEL/data/MODEL_NAME/PERIOD/[SSP]/files
  
  model_dir <- find_model_directory(input_root, model)
  if (is.null(model_dir)) {
    return(NULL)
  }
  
  data_dir <- file.path(model_dir, "data")
  if (!dir.exists(data_dir)) {
    return(NULL)
  }
  
  # Find model-named subdirectory under data
  model_subdirs <- list.dirs(data_dir, recursive = FALSE, full.names = TRUE)
  if (length(model_subdirs) == 0) {
    return(NULL)
  }
  model_data_base <- model_subdirs[1]
  
  # Find period directory
  period_dir <- file.path(model_data_base, period)
  if (!dir.exists(period_dir)) {
    period_dirs <- list.dirs(model_data_base, recursive = FALSE, full.names = TRUE)
    period_dir <- period_dirs[grepl(period, basename(period_dirs), ignore.case = TRUE)][1]
  }
  
  if (!dir.exists(period_dir)) {
    return(NULL)
  }
  
  # Add scenario if specified
  if (!is.null(scenario) && scenario != "historical") {
    scenario_dir <- file.path(period_dir, scenario)
    if (dir.exists(scenario_dir)) {
      return(scenario_dir)
    }
  }
  
  return(period_dir)
}

find_raster_files <- function(input_root, model, period, scenario, variable) {
  search_dir <- get_model_data_path(input_root, model, period, scenario)
  
  if (is.null(search_dir) || !dir.exists(search_dir)) {
    return(character(0))
  }
  
  # Find all tif files
  all_files <- list.files(search_dir, pattern = "\\.tif[f]?$", 
                          full.names = TRUE, recursive = FALSE, 
                          ignore.case = TRUE)
  
  # Filter by variable and month pattern
  # Filename pattern: MODEL_PERIOD_SSP_01Jan_variable.tif or MODEL_PERIOD_01Jan_variable.tif
  var_pattern <- paste0("_", variable, "\\.tif")
  month_pattern <- "(0[1-9]|1[0-2])(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
  
  matching_files <- all_files[
    grepl(var_pattern, all_files, ignore.case = TRUE) & 
    grepl(month_pattern, all_files, ignore.case = TRUE)
  ]
  
  # Remove duplicates and sort
  matching_files <- unique(matching_files)
  matching_files <- sort(matching_files)
  
  matching_files
}

extract_month_from_filename <- function(filename) {
  # Pattern: 01Jan, 02Feb, etc.
  month_pattern <- "(0[1-9]|1[0-2])(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)"
  
  match <- regmatches(filename, regexpr(month_pattern, filename, ignore.case = TRUE))
  if (length(match) > 0 && nchar(match) > 0) {
    month_num <- substr(match, 1, 2)
    return(as.integer(month_num))
  }
  
  # Fallback: try numeric patterns
  patterns <- c(
    "_(0[1-9]|1[0-2])_",
    "-(0[1-9]|1[0-2])-",
    "_m(0[1-9]|1[0-2])_",
    "mon(0[1-9]|1[0-2])"
  )
  
  for (p in patterns) {
    m <- regmatches(filename, regexpr(p, filename, ignore.case = TRUE))
    if (length(m) > 0 && nchar(m) > 0) {
      month_str <- gsub("[^0-9]", "", m)
      return(as.integer(month_str))
    }
  }
  
  return(NA)
}

# =============================================================================
# UNIT CONVERSION
# =============================================================================

detect_and_convert_units <- function(rast, variable, filename) {
  log_msg(paste("Detecting units for", filename))

  # Get sample statistics (disk-backed, efficient)
  # Sample random cells from the raster
  ncells <- ncell(rast)
  if (ncells > 10000) {
    sample_cells <- sample(ncells, 10000)
  } else {
    sample_cells <- 1:ncells
  }
  
  samp <- terra::values(rast)[sample_cells]
  samp <- samp[!is.na(samp)]
  
  if (length(samp) == 0) {
    log_msg("Could not sample raster for unit detection, assuming standard units", "WARN")
    return(rast)
  }

  max_val <- max(samp, na.rm = TRUE)
  min_val <- min(samp, na.rm = TRUE)

  if (variable %in% c("tasmin", "tasmax", "tmax", "tmin", "tmean")) {
    # Temperature
    if (max_val > 150) {
      log_msg(paste("Temperature in Kelvin (max:", round(max_val, 2),
                    "), converting to Celsius"))
      rast <- rast - 273.15
    } else {
      log_msg(paste("Temperature in Celsius (max:", round(max_val, 2), ")"))
    }
  } else if (variable == "pr") {
    # Precipitation
    if (max_val < 5) {
      log_msg(paste("Precipitation in kg m-2 s-1 (max:", round(max_val, 6),
                    "), converting to mm/month"))
      # Convert kg m-2 s-1 to mm/month
      # 1 kg m-2 s-1 = 86400 * days_in_month mm/month
      # Approximate: multiply by seconds in month (~2.628e6)
      rast <- rast * 2628000
    } else {
      log_msg(paste("Precipitation in mm/month (max:", round(max_val, 2), ")"))
    }
  }

  rast
}

# =============================================================================
# BIOCLIM CALCULATIONS
# =============================================================================

prepare_monthly_stack <- function(input_root, model, period, scenario, variable) {
  files <- find_raster_files(input_root, model, period, scenario, variable)
  
  if (length(files) == 0) {
    log_msg(paste("No files found for", model, period, scenario, variable), "WARN")
    return(NULL)
  }
  
  log_msg(paste("Found", length(files), "files for", variable))
  
  # Create list to hold rasters with month info
  monthly_rasts <- list()

  for (f in files) {
    month <- extract_month_from_filename(f)
    if (is.na(month)) {
      log_msg(paste("Could not extract month from", basename(f)), "WARN")
      next
    }

    r <- rast(f)
    r <- detect_and_convert_units(r, variable, f)
    monthly_rasts[[as.character(month)]] <- r
  }

  if (length(monthly_rasts) == 0) {
    return(NULL)
  }

  # Ensure all 12 months present
  for (m in 1:12) {
    if (!(as.character(m) %in% names(monthly_rasts))) {
      log_msg(paste("Missing month", m, "for", variable, "- using NA"), "WARN")
      # Create empty raster with same extent as first
      template <- monthly_rasts[[1]]
      monthly_rasts[[as.character(m)]] <- template * NA
    }
  }

  # Sort by month and stack - use unname() to remove names for sprc
  monthly_rasts <- monthly_rasts[order(as.integer(names(monthly_rasts)))]
  
  # Use rast() instead of sprc() for better compatibility
  stack <- rast(unname(monthly_rasts))
  names(stack) <- paste0("m", 1:12)

  stack
}

find_precomputed_bioclim_files <- function(input_root, model, period, scenario) {
  search_dir <- get_model_data_path(input_root, model, period, scenario)
  if (is.null(search_dir) || !dir.exists(search_dir)) {
    return(NULL)
  }

  all_files <- list.files(search_dir, pattern = "\\.tif[f]?$",
                          full.names = TRUE, recursive = FALSE,
                          ignore.case = TRUE)
  if (length(all_files) == 0) {
    return(NULL)
  }

  bio_files <- vector("list", 19)
  for (i in 1:19) {
    bio_pat <- paste0("(?<![0-9])bio0?", i, "(?![0-9])")
    hits <- all_files[grepl(bio_pat, basename(all_files), ignore.case = TRUE, perl = TRUE)]
    if (length(hits) > 0) {
      hits <- sort(unique(hits))
      if (length(hits) > 1) {
        log_msg(paste("Multiple candidates for BIO", sprintf("%02d", i),
                      "in", search_dir, "- using first"), "WARN")
      }
      bio_files[[i]] <- hits[1]
    } else {
      bio_files[[i]] <- NA_character_
    }
  }

  names(bio_files) <- paste0("BIO", sprintf("%02d", 1:19))
  bio_files
}

load_precomputed_bioclim <- function(input_root, model, period, scenario) {
  bio_files <- find_precomputed_bioclim_files(input_root, model, period, scenario)
  if (is.null(bio_files)) {
    return(NULL)
  }

  missing <- names(bio_files)[is.na(unlist(bio_files))]
  if (length(missing) > 0) {
    return(NULL)
  }

  bioclim <- list()
  for (bio_name in names(bio_files)) {
    r <- rast(bio_files[[bio_name]])
    names(r) <- bio_name
    bioclim[[bio_name]] <- r
  }

  bioclim
}

compute_tmean <- function(tmin_stack, tmax_stack) {
  # Compute mean temperature stack from min and max
  # Use terra::app for proper SpatRaster handling
  tmean <- (tmin_stack + tmax_stack) / 2
  tmean
}

get_quarter_indices <- function(start_month) {
  # Returns indices for a rolling 3-month quarter starting at start_month
  months <- c(start_month, start_month + 1, start_month + 2)
  ((months - 1) %% 12) + 1
}

build_rolling_quarter_stack <- function(monthly_stack, agg = c("sum", "mean")) {
  agg <- match.arg(agg)
  if (nlyr(monthly_stack) != 12) {
    stop("Expected 12 monthly layers for quarter computation")
  }

  quarter_layers <- vector("list", 12)
  for (start in 1:12) {
    idx <- get_quarter_indices(start)
    if (agg == "sum") {
      quarter_layers[[start]] <- sum(monthly_stack[[idx]])
    } else {
      quarter_layers[[start]] <- mean(monthly_stack[[idx]])
    }
  }

  quarter_stack <- rast(unname(quarter_layers))
  names(quarter_stack) <- paste0("q", sprintf("%02d", 1:12))
  quarter_stack
}

quarter_index_raster <- function(quarter_stack, mode = c("max", "min")) {
  mode <- match.arg(mode)
  if (mode == "max") {
    app(quarter_stack, fun = function(v) {
      if (all(is.na(v))) NA else which.max(v)
    })
  } else {
    app(quarter_stack, fun = function(v) {
      if (all(is.na(v))) NA else which.min(v)
    })
  }
}

select_quarter_value <- function(quarter_values, quarter_index) {
  selected <- ifel(quarter_index == 1, quarter_values[[1]], NA)
  if (nlyr(quarter_values) > 1) {
    for (i in 2:nlyr(quarter_values)) {
      selected <- cover(selected, ifel(quarter_index == i, quarter_values[[i]], NA))
    }
  }
  selected
}

compute_bioclim_variables <- function(tmin_stack, tmax_stack, pr_stack) {
  log_msg("Computing bioclimatic variables...")

  bioclim <- list()

  # tmean stack
  log_msg("Computing tmean...")
  tmean_stack <- compute_tmean(tmin_stack, tmax_stack)

  # BIO01 = Annual Mean Temperature = mean(tmean)
  log_msg("Computing BIO01...")
  bioclim$BIO01 <- mean(tmean_stack)
  names(bioclim$BIO01) <- "BIO01"

  # BIO02 = Mean Diurnal Range = mean(tmax - tmin)
  log_msg("Computing BIO02...")
  diurnal <- tmax_stack - tmin_stack
  bioclim$BIO02 <- mean(diurnal)
  names(bioclim$BIO02) <- "BIO02"

  # BIO03 = Isothermality = (BIO02 / BIO07) * 100
  # BIO05 = Max Temperature of Warmest Month = max(tmax)
  # BIO06 = Min Temperature of Coldest Month = min(tmin)
  # BIO07 = Temperature Annual Range = BIO05 - BIO06
  log_msg("Computing BIO05-BIO07...")
  bioclim$BIO05 <- max(tmax_stack)
  names(bioclim$BIO05) <- "BIO05"

  bioclim$BIO06 <- min(tmin_stack)
  names(bioclim$BIO06) <- "BIO06"

  bioclim$BIO07 <- bioclim$BIO05 - bioclim$BIO06
  names(bioclim$BIO07) <- "BIO07"

  bioclim$BIO03 <- (bioclim$BIO02 / bioclim$BIO07) * 100
  names(bioclim$BIO03) <- "BIO03"

  # BIO04 = Temperature Seasonality = sd(tmean) * 100
  log_msg("Computing BIO04...")
  bioclim$BIO04 <- app(tmean_stack, fun = sd) * 100
  names(bioclim$BIO04) <- "BIO04"

  # Precipitation variables
  # BIO12 = Annual Precipitation = sum(pr)
  # BIO13 = Precipitation of Wettest Month = max(pr)
  # BIO14 = Precipitation of Driest Month = min(pr)
  # BIO15 = Precipitation Seasonality = (sd(pr) / mean(pr)) * 100
  log_msg("Computing BIO12-BIO15...")

  bioclim$BIO12 <- sum(pr_stack)
  names(bioclim$BIO12) <- "BIO12"

  bioclim$BIO13 <- max(pr_stack)
  names(bioclim$BIO13) <- "BIO13"

  bioclim$BIO14 <- min(pr_stack)
  names(bioclim$BIO14) <- "BIO14"

  pr_mean <- mean(pr_stack)
  pr_sd <- app(pr_stack, fun = sd)
  bioclim$BIO15 <- (pr_sd / pr_mean) * 100
  names(bioclim$BIO15) <- "BIO15"

  # Quarterly temperature variables
  # BIO08 = Mean Temperature of Wettest Quarter
  # BIO09 = Mean Temperature of Driest Quarter
  # BIO10 = Mean Temperature of Warmest Quarter
  # BIO11 = Mean Temperature of Coldest Quarter
  log_msg("Computing BIO08-BIO11 (temperature quarters)...")

  pr_quarter_sum <- build_rolling_quarter_stack(pr_stack, agg = "sum")
  tmean_quarter_mean <- build_rolling_quarter_stack(tmean_stack, agg = "mean")
  
  wettest_q <- quarter_index_raster(pr_quarter_sum, mode = "max")
  bioclim$BIO08 <- select_quarter_value(tmean_quarter_mean, wettest_q)
  names(bioclim$BIO08) <- "BIO08"

  driest_q <- quarter_index_raster(pr_quarter_sum, mode = "min")
  bioclim$BIO09 <- select_quarter_value(tmean_quarter_mean, driest_q)
  names(bioclim$BIO09) <- "BIO09"

  warmest_q <- quarter_index_raster(tmean_quarter_mean, mode = "max")
  bioclim$BIO10 <- select_quarter_value(tmean_quarter_mean, warmest_q)
  names(bioclim$BIO10) <- "BIO10"

  coldest_q <- quarter_index_raster(tmean_quarter_mean, mode = "min")
  bioclim$BIO11 <- select_quarter_value(tmean_quarter_mean, coldest_q)
  names(bioclim$BIO11) <- "BIO11"
  
  # Quarterly precipitation variables
  # BIO16 = Precipitation of Wettest Quarter
  # BIO17 = Precipitation of Driest Quarter
  # BIO18 = Precipitation of Warmest Quarter
  # BIO19 = Precipitation of Coldest Quarter
  
  bioclim$BIO16 <- select_quarter_value(pr_quarter_sum, wettest_q)
  names(bioclim$BIO16) <- "BIO16"
  
  bioclim$BIO17 <- select_quarter_value(pr_quarter_sum, driest_q)
  names(bioclim$BIO17) <- "BIO17"
  
  bioclim$BIO18 <- select_quarter_value(pr_quarter_sum, warmest_q)
  names(bioclim$BIO18) <- "BIO18"
  
  bioclim$BIO19 <- select_quarter_value(pr_quarter_sum, coldest_q)
  names(bioclim$BIO19) <- "BIO19"
  
  bioclim
}

# =============================================================================
# OUTPUT WRITING
# =============================================================================

write_bioclim_rasters <- function(bioclim, output_root, model, period, scenario) {
  # Create output directory
  model_id <- canonical_model_id(model)
  period_id <- canonical_period_id(period)
  scenario_id <- canonical_scenario_id(scenario)
  out_dir <- file.path(output_root, model_id, period_id, scenario_id)
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }

  written_files <- character(0)

  for (bio_name in names(bioclim)) {
    r <- bioclim[[bio_name]]

    # Write with compression - terra handles NA automatically
    bio_num <- sub("^BIO", "", toupper(bio_name))
    out_name <- paste0("bhutan_cmip6_", model_id, "_", scenario_id, "_",
                       period_id, "_bio", tolower(bio_num), "_v1_0.tif")
    out_file <- file.path(out_dir, out_name)

    # Check overwrite
    if (file.exists(out_file) && !OPTS$overwrite) {
      log_msg(paste("Skipping", out_file, "(exists, no overwrite)"), "WARN")
      next
    }

    # Write with compression - use correct terra syntax
    writeRaster(r, out_file, overwrite = TRUE,
                filetype = "GTiff",
                gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"),
                NAflag = -9999)

    written_files <- c(written_files, out_file)
    log_msg(paste("Written:", out_file))
  }

  written_files
}

# =============================================================================
# VALIDATION
# =============================================================================

validate_bioclim <- function(bioclim, model, period, scenario) {
  log_msg(paste("Validating bioclim variables for", model, period, scenario))

  for (bio_name in names(bioclim)) {
    r <- bioclim[[bio_name]]
    vals <- terra::values(r)

    n_na <- sum(is.na(vals))
    n_nan <- sum(is.nan(vals))
    n_inf <- sum(is.infinite(vals))

    # Clean vals for min/max/mean
    clean_vals <- vals[!is.na(vals) & !is.nan(vals) & !is.infinite(vals)]

    if (length(clean_vals) > 0) {
      min_val <- min(clean_vals)
      max_val <- max(clean_vals)
      mean_val <- mean(clean_vals)
    } else {
      min_val <- NA
      max_val <- NA
      mean_val <- NA
    }
    
    log_summary_record(model, period, scenario, bio_name, 
                       n_na, n_nan, n_inf, min_val, max_val, mean_val)
    
    if (n_na > 0 || n_nan > 0 || n_inf > 0) {
      log_msg(paste("WARNING:", bio_name, "- NA:", n_na, 
                    "NaN:", n_nan, "Inf:", n_inf), "WARN")
    }
  }
}

# =============================================================================
# ENSEMBLE COMPUTATION
# =============================================================================

compute_ensemble <- function(output_root, period, scenario, stats) {
  log_msg(paste("Computing ensemble for", period, scenario))

  # Find all model outputs for this period/scenario
  model_dirs <- list.dirs(output_root, recursive = FALSE, full.names = FALSE)
  model_dirs <- model_dirs[!grepl("^_|^\\.|^logs$", model_dirs, ignore.case = TRUE)]

  if (is.null(OPTS$models)) {
    models_to_use <- model_dirs
  } else {
    models_to_use <- OPTS$models
  }

  # Collect rasters for each bio variable
  ensemble_dir <- file.path(output_root, "_ensemble", period, scenario)
  if (!dir.exists(ensemble_dir)) {
    dir.create(ensemble_dir, recursive = TRUE)
  }

  bio_vars <- paste0("BIO", sprintf("%02d", 1:19))
  ensemble_models <- list()

  period_id <- canonical_period_id(period)
  scenario_id <- canonical_scenario_id(scenario)

  for (bio in bio_vars) {
    model_rasters <- list()
    models_included <- character(0)

    for (model in models_to_use) {
      model_id <- canonical_model_id(model)
      bio_num <- sub("^BIO", "", bio)
      canonical_file <- file.path(
        output_root, model_id, period_id, scenario_id,
        paste0("bhutan_cmip6_", model_id, "_", scenario_id, "_",
               period_id, "_bio", tolower(bio_num), "_v1_0.tif")
      )

      # Backward-compat fallback for older outputs
      legacy_file <- file.path(output_root, model, period, scenario, paste0(bio, ".tif"))
      if (!file.exists(legacy_file) && scenario == "historical") {
        legacy_file <- file.path(output_root, model, period, paste0(bio, ".tif"))
      }

      model_file <- if (file.exists(canonical_file)) canonical_file else legacy_file
      
      if (file.exists(model_file)) {
        r <- rast(model_file)
        model_rasters[[model]] <- r
        models_included <- c(models_included, model)
      }
    }

    if (length(model_rasters) < 2) {
      log_msg(paste("Skipping ensemble for", bio, "- only",
                    length(model_rasters), "model(s) found"), "WARN")
      next
    }

    ensemble_models[[bio]] <- models_included
    log_msg(paste("Ensemble", bio, "- models:", paste(models_included, collapse = ", ")))

    # Stack models - use rast() for compatibility
    stack <- rast(unname(model_rasters))

    # Replace -9999 with NA for computation
    stack <- subst(stack, from = -9999, to = NA)

    # Compute stats
    for (stat in stats) {
      if (stat == "mean") {
        result <- mean(stack)
      } else if (stat == "median") {
        result <- app(stack, fun = median, na.rm = TRUE)
      } else if (stat == "min") {
        result <- min(stack)
      } else if (stat == "max") {
        result <- max(stack)
      } else if (stat == "sd") {
        result <- app(stack, fun = sd, na.rm = TRUE)
      } else {
        log_msg(paste("Unknown ensemble stat:", stat), "WARN")
        next
      }

      names(result) <- paste0(bio, "_", stat)

      out_file <- file.path(ensemble_dir, paste0(bio, "_", stat, ".tif"))

      # Set NA flag - use terra:: prefix
      vals <- terra::values(result)
      na_idx <- is.na(vals) | is.nan(vals) | is.infinite(vals)
      if (any(na_idx)) {
        vals[na_idx] <- -9999
        result <- terra::setValues(result, vals)
      }

      writeRaster(result, out_file, overwrite = TRUE,
                  filetype = "GTiff",
                  gdal = c("COMPRESS=DEFLATE", "PREDICTOR=2", "TILED=YES"),
                  NAflag = -9999)

      log_msg(paste("Written ensemble:", out_file))
    }
  }

  # Write models list CSV
  if (length(ensemble_models) > 0) {
    models_df <- data.frame(
      bio_var = names(ensemble_models),
      models = sapply(ensemble_models, paste, collapse = ";"),
      n_models = sapply(ensemble_models, length),
      stringsAsFactors = FALSE
    )
    
    models_file <- file.path(ensemble_dir, "models_included.csv")
    write.csv(models_df, models_file, row.names = FALSE)
    log_msg(paste("Written models list:", models_file))
  }
}

# =============================================================================
# MAIN PROCESSING
# =============================================================================

process_model <- function(input_root, output_root, model) {
  log_msg(paste("=== Processing model:", model, "==="))
  
  tryCatch({
    model_ok <- TRUE
    total_scenarios <- 0
    successful_scenarios <- 0
    failed_scenarios <- 0
    
    # Determine periods
    if (!is.null(OPTS$periods)) {
      periods <- OPTS$periods
    } else {
      periods <- scan_periods(input_root, model)
    }
    
    if (length(periods) == 0) {
      log_msg(paste("No periods found for", model), "WARN")
      return(FALSE)
    }
    
    for (period in periods) {
      log_msg(paste("Processing period:", period))
      
      # Determine scenarios
      if (!is.null(OPTS$scenarios)) {
        scenarios <- OPTS$scenarios
      } else {
        scenarios <- scan_scenarios(input_root, model, period)
      }

      # Handle historical period (no SSP subfolder)
      if (period == "historical" || is.null(scenarios) || length(scenarios) == 0) {
        scenarios <- list(NULL)  # NULL means no scenario subfolder
      } else {
        scenarios <- as.list(scenarios)
      }

      for (scenario in scenarios) {
        # scenario is NULL for historical, or SSP name for future periods
        scenario_label <- ifelse(is.null(scenario), "historical", scenario)
        log_msg(paste("Processing scenario:", scenario_label))
        total_scenarios <- total_scenarios + 1
        
        scenario_ok <- tryCatch({
          # If input already contains BIO01-BIO19, use those directly.
          precomputed_bioclim <- load_precomputed_bioclim(input_root, model, period, scenario)
          if (!is.null(precomputed_bioclim)) {
            log_msg(paste("Using precomputed BIOCLIM rasters for", model, period, scenario_label))
            written <- write_bioclim_rasters(precomputed_bioclim, output_root, model, period, scenario_label)
            validate_bioclim(precomputed_bioclim, model, period, scenario_label)
            log_msg(paste("Completed", model, period, scenario_label, "-",
                          length(written), "files written (precomputed input)"))
            TRUE
          } else {
            # Load monthly stacks
            tmin_stack <- prepare_monthly_stack(input_root, model, period, scenario, "tasmin")
            tmax_stack <- prepare_monthly_stack(input_root, model, period, scenario, "tasmax")
            pr_stack <- prepare_monthly_stack(input_root, model, period, scenario, "pr")
  
            if (is.null(tmin_stack) || is.null(tmax_stack) || is.null(pr_stack)) {
              log_msg(paste("Missing required variable stacks for", model, period, scenario_label), "ERROR")
              FALSE
            } else {
              # Compute bioclim
              bioclim <- compute_bioclim_variables(tmin_stack, tmax_stack, pr_stack)
    
              # Write outputs
              written <- write_bioclim_rasters(bioclim, output_root, model, period, scenario_label)
    
              # Validate
              validate_bioclim(bioclim, model, period, scenario_label)
    
              log_msg(paste("Completed", model, period, scenario_label, "-",
                            length(written), "files written"))
              TRUE
            }
          }

        }, error = function(e) {
          log_msg(paste("ERROR processing", model, period, scenario_label, ":", e$message), "ERROR")
          FALSE
        })
        
        if (isTRUE(scenario_ok)) {
          successful_scenarios <- successful_scenarios + 1
        } else {
          failed_scenarios <- failed_scenarios + 1
          model_ok <- FALSE
        }
      }
    }
    
    log_msg(paste("Model summary for", model, ":",
                  successful_scenarios, "/", total_scenarios, "scenarios succeeded,",
                  failed_scenarios, "failed"))
    
    return(model_ok)
  }, error = function(e) {
    log_msg(paste("ERROR processing model", model, ":", e$message), "ERROR")
    return(FALSE)
  })
}

run_ensemble <- function(output_root) {
  log_msg("=== Computing Ensembles ===")

  # Get unique periods and scenarios from outputs
  model_dirs <- list.dirs(output_root, recursive = FALSE, full.names = FALSE)
  model_dirs <- model_dirs[!grepl("^_|^\\.|^logs$", model_dirs, ignore.case = TRUE)]

  if (is.null(OPTS$models)) {
    models_to_check <- model_dirs
  } else {
    models_to_check <- OPTS$models
  }

  periods_found <- character(0)
  scenarios_found <- character(0)

  for (model in models_to_check) {
    model_dir <- file.path(output_root, model)
    if (!dir.exists(model_dir)) next

    period_dirs <- list.dirs(model_dir, recursive = FALSE, full.names = FALSE)
    periods_found <- unique(c(periods_found, period_dirs))

    for (period in period_dirs) {
      period_dir <- file.path(output_root, model, period)
      if (!dir.exists(period_dir)) next
      
      scenario_dirs <- list.dirs(period_dir, recursive = FALSE, full.names = FALSE)
      scenario_dirs <- scenario_dirs[!grepl("^_|^\\.", scenario_dirs)]
      
      # If no scenario subdirs, check for BIO files directly in period folder
      if (length(scenario_dirs) == 0) {
        bio_files <- list.files(period_dir, pattern = "^BIO[0-9]+\\.tif$", 
                                full.names = FALSE, ignore.case = TRUE)
        if (length(bio_files) > 0) {
          scenarios_found <- unique(c(scenarios_found, "historical"))
        }
      } else {
        scenarios_found <- unique(c(scenarios_found, scenario_dirs))
      }
    }
  }

  # Remove special directories
  periods_found <- periods_found[!grepl("^_|^\\.", periods_found)]
  scenarios_found <- scenarios_found[!grepl("^_|^\\.", scenarios_found)]

  log_msg(paste("Periods for ensemble:", paste(periods_found, collapse = ", ")))
  log_msg(paste("Scenarios for ensemble:", paste(scenarios_found, collapse = ", ")))

  for (period in periods_found) {
    for (scenario in scenarios_found) {
      tryCatch({
        compute_ensemble(output_root, period, scenario, OPTS$ensemble_stats)
      }, error = function(e) {
        log_msg(paste("ERROR computing ensemble for", period, scenario, ":", e$message), "ERROR")
      })
    }
  }
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

OPTS <- NULL

main <- function() {
  # Parse arguments
  OPTS <<- parse_args()
  
  # Initialize terra
  terraOptions(
    tempdir = OPTS$tempdir,
    memfrac = OPTS$memfrac
  )
  
  log_msg(paste("terraOptions: tempdir =", OPTS$tempdir, ", memfrac =", OPTS$memfrac))
  
  # Initialize logging
  init_log(OPTS$log_root, OPTS$output_root)
  
  # Create output root if needed
  if (!dir.exists(OPTS$output_root)) {
    dir.create(OPTS$output_root, recursive = TRUE)
  }
  
  # Auto-detect models
  if (is.null(OPTS$models)) {
    OPTS$models <<- scan_models(OPTS$input_root)
  } else {
    log_msg(paste("Using specified models:", paste(OPTS$models, collapse = ", ")))
  }
  
  if (length(OPTS$models) == 0) {
    log_msg("No models to process", "ERROR")
    quit(status = 1)
  }
  
  # Process each model
  success_count <- 0
  fail_count <- 0

  for (model in OPTS$models) {
    model_name <- model  # Save model name before potential scope issues
    result <- tryCatch({
      process_model(OPTS$input_root, OPTS$output_root, model)
    }, error = function(e) {
      log_msg(paste("FATAL ERROR for", model_name, ":", conditionMessage(e)), "ERROR")
      FALSE
    })

    if (isTRUE(result)) {
      success_count <- success_count + 1
    } else {
      fail_count <- fail_count + 1
    }

    # Clear terra cache between models
    gc()
  }

  log_msg(paste("Model processing complete:", success_count, "succeeded,",
                fail_count, "failed"))
  
  # Compute ensembles unless explicitly skipped
  if (!isTRUE(OPTS$skip_ensemble)) {
    tryCatch({
      run_ensemble(OPTS$output_root)
    }, error = function(e) {
      log_msg(paste("ERROR in ensemble computation:", e$message), "ERROR")
    })
  } else {
    log_msg("Skipping ensemble computation (--skip_ensemble=TRUE)")
  }
  
  # Write summary
  write_summary_csv(OPTS$log_root)
  
  log_msg(paste("Completed:", Sys.time()))
  log_msg(paste("Log file:", LOG_FILE))
  
  if (fail_count > 0) {
    log_msg(paste("Run finished with", fail_count, "failed model(s)"), "ERROR")
    quit(status = 1)
  }
}

# Run
main()
