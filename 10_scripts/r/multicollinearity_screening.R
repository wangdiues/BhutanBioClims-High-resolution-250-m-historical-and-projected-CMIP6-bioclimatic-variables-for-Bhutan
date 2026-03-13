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
  parsed <- list(
    project_root = NULL,
    time_slice = "1986_2015",
    scenario = "historical"
  )
  i <- 1
  while (i <= length(args)) {
    if (args[i] == "--project_root" && i < length(args)) {
      parsed$project_root <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--time_slice" && i < length(args)) {
      parsed$time_slice <- args[i + 1]
      i <- i + 2
    } else if (args[i] == "--scenario" && i < length(args)) {
      parsed$scenario <- args[i + 1]
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
qc_dir <- file.path(project_root, "05_multicollinearity_analysis")
dir.create(qc_dir, recursive = TRUE, showWarnings = FALSE)

selected_time_slice <- opts$time_slice
selected_ssp <- opts$scenario

input_dir <- file.path(project_root, "04_ensemble_products", "ensemble_mean", selected_time_slice, selected_ssp)
if (!dir.exists(input_dir)) {
  stop("Information required: ensure ensemble_mean rasters exist for selected time slice and SSP. Missing: ", input_dir)
}

files <- list.files(input_dir, pattern = "\\.tif$", full.names = TRUE)
if (length(files) < 2) stop("Need at least two predictors for correlation/VIF analysis")

s <- rast(files)
names(s) <- gsub("^.*_(bio[0-9]{2})_v1_0\\.tif$", "\\1", basename(files), ignore.case = TRUE)

set.seed(42)
sample_n <- min(50000, ncell(s))
df <- spatSample(s, size = sample_n, method = "random", as.df = TRUE, na.rm = TRUE)

# Correlation matrix
cor_mat <- cor(df, method = "pearson", use = "pairwise.complete.obs")
write.csv(cor_mat, file.path(qc_dir, "correlation_matrix.csv"), row.names = TRUE)

calc_vif <- function(dat) {
  vars <- colnames(dat)
  v <- sapply(vars, function(vn) {
    others <- setdiff(vars, vn)
    if (length(others) == 0) return(NA_real_)
    fm <- as.formula(paste(vn, "~", paste(others, collapse = " + ")))
    fit <- lm(fm, data = dat)
    r2 <- summary(fit)$r.squared
    if (is.na(r2) || r2 >= 1) return(Inf)
    1 / (1 - r2)
  })
  data.frame(variable = vars, vif = as.numeric(v), stringsAsFactors = FALSE)
}

threshold <- 10
work <- df
removed <- data.frame(iteration = integer(), variable = character(), vif = numeric(), stringsAsFactors = FALSE)
iter <- 0

repeat {
  iter <- iter + 1
  vif_tbl <- calc_vif(work)
  max_v <- max(vif_tbl$vif, na.rm = TRUE)
  bad <- vif_tbl$variable[which.max(vif_tbl$vif)]

  if (is.infinite(max_v) || max_v > threshold) {
    removed <- bind_rows(removed, data.frame(iteration = iter, variable = bad, vif = max_v))
    work <- work[, setdiff(colnames(work), bad), drop = FALSE]
    if (ncol(work) <= 1) break
  } else {
    break
  }
}

retained <- if (ncol(work) > 1) calc_vif(work) else data.frame(variable = colnames(work), vif = NA_real_)
out <- bind_rows(
  removed %>% transmute(stage = "removed", variable, vif),
  retained %>% transmute(stage = "retained", variable, vif)
)

write.csv(out, file.path(qc_dir, "vif_results.csv"), row.names = FALSE)
writeLines(colnames(work), file.path(qc_dir, "selected_predictors.txt"))

message("Multicollinearity outputs written to ", qc_dir)

