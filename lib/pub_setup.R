# =============================================================================
# pub_setup.R -- shared setup for every table and figure script in pub_code/
# =============================================================================
# Every script starts with   source("lib/pub_setup.R")   and must be run with
# pub_code/ as the working directory (run_all.R does this).
#
# This file:
#   1. pins the timezone the published results were generated under,
#   2. loads the copied support libraries (lib/analysis_processes.R -> L1 kernels
#      + L2 data/plot/driver functions), unchanged from the analysis repo,
#   3. declares every reported constant once (the study's "L3" settings),
#   4. provides output paths and read/write helpers, and
#   5. sources lib/pub_builders.R (the table-building functions).
# =============================================================================

if (!file.exists("lib/pub_setup.R")) {
  stop("Run pub_code scripts with pub_code/ as the working directory.")
}

# -----------------------------------------------------------------------------
# Timezone. The loader (L2_data.R::load_hourly_data) reads logger clock times as
# local time and compares them with a window built in UTC. The published results
# were generated with TZ = America/Phoenix (UTC-7, no DST), which puts the
# effective window at 2022-07-31 17:00 -> 2023-02-17 17:00 logger clock time.
# Pinning TZ makes every output reproducible on any machine. See README.md.
# -----------------------------------------------------------------------------
Sys.setenv(TZ = "America/Phoenix")

# -----------------------------------------------------------------------------
# Support libraries (copied unchanged; analysis_processes.R sources its siblings
# by relative path, so source it from inside lib/).
# -----------------------------------------------------------------------------
local({
  old <- setwd("lib")
  tryCatch(suppressPackageStartupMessages(source("analysis_processes.R")),
           finally = setwd(old))
})

# -----------------------------------------------------------------------------
# Reported constants (single source for all of pub_code/)
# -----------------------------------------------------------------------------
DATA_FILE      <- "data/all_cave_temp_data_ext.xlsx"
PLACEMENT_FILE <- "data/logger_placement.csv"
WINDOW         <- c("2022-08-01", "2023-02-18")   # study period (see timezone note)
THRESHOLD      <- 24.25                           # degC crocodile thermal threshold

# Night: manuscript Methods, "nighttime (1830-0530 h)". A night is dated by the
# evening it starts on, so the hours after midnight belong to the previous date.
NIGHT_START_MIN <- 18 * 60 + 30   # 18:30
NIGHT_END_MIN   <-  5 * 60 + 30   # 05:30
# Day: the definition used for the published Supplemental Material File 2 daytime
# tables, [05:50, 18:00). The manuscript Methods state 0630-1530 h; see README.md.
DAY_START_MIN   <-  5 * 60 + 50   # 05:50
DAY_END_MIN     <- 18 * 60        # 18:00
# Winter reporting period (manuscript): 01 Nov 2022 - 18 Feb 2023.
WINTER          <- as.Date(c("2022-11-01", "2023-02-18"))

# Modelling settings (as reported in the Supplement).
SPLINE_DF   <- 8L
MIN_OVERLAP <- 200L
PERIOD      <- 24
CCF_LAGMAX  <- 24L
LAGBOOT     <- list(reps = 1000L, conf = 0.95, lag_max = 24L)
TE          <- list(lx = 1L, ly = 1L, quantiles = c(25, 50, 75), nboot = 300L, shuffles = 100L)
TEOPT       <- list(lag_max = 24L, nsurr = 100L, shuffles = 100L)
DF_SWEEP    <- c(2, 4, 6, 8, 10, 12, 16, 20, 24)
KPSS_CRIT5  <- 0.463

VARIANTS <- c("raw", "detrended")

# Sensor roster, pair set and pair-label order (mirror Model_Analyses.R).
sensor_style <- data.frame(
  Location = factor(c(21433126, 21433127, 21433128, 21433129, 21433130,
                      21433131, 21433132, 21433133, 21433134, 21433135)),
  line_style = factor(c(1, 2, 3, 4, 5, 1, 2, 3, 4, 5)),
  Logger_Name = c("Croc2-Logger1", "Croc2-Logger2", "Croc2-Logger3",
                  "Croc2-Logger4", "Croc2-Logger5",
                  "KHC-Logger1", "KHC-Logger2", "KHC-Logger3",
                  "KHC-Logger4", "KHC-Logger5"),
  suspect = c(1.4, 0.4, 0.4, 0.4, 1.4, 0.4, 0.4, 0.4, 0.4, 0.4)
)
pairs_def_all <- do.call(c, lapply(c("Croc-2", "KHC"), function(cv) {
  prefix <- if (cv == "Croc-2") "^Croc2" else "^KHC"
  logs   <- grep(prefix, sensor_style$Logger_Name, value = TRUE)
  lapply(combn(logs, 2, simplify = FALSE), function(p) list(cave = cv, a = p[1], b = p[2]))
}))
all_pair_levels <- c("L1-L2", "L1-L3", "L1-L4", "L1-L5", "L2-L3",
                     "L2-L4", "L2-L5", "L3-L4", "L3-L5", "L4-L5")

# Cave colours used by the main-text figures (manuscript captions: Croc 2 blue,
# KHC orange; Okabe-Ito palette).
CAVE_COLOURS <- c("Croc-2" = "#56B4E9", "KHC" = "#E69F00")

# -----------------------------------------------------------------------------
# Output paths and I/O helpers
# -----------------------------------------------------------------------------
ANALYSIS_DIR <- "output/tables/analysis"
PUB_DIR      <- "output/tables/publication"
FIG_DIR      <- "output/figures"
CACHE_DIR    <- "output/cache"
for (d in c(ANALYSIS_DIR, PUB_DIR, FIG_DIR, CACHE_DIR)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

analysis_path <- function(name) file.path(ANALYSIS_DIR, paste0(name, ".csv"))
pub_path      <- function(name) file.path(PUB_DIR, paste0(name, ".csv"))

write_table <- function(df, path) {
  utils::write.csv(as.data.frame(df), path, row.names = FALSE, na = "")
  cat(sprintf("Table written: %s (%d rows)\n", path, nrow(df)))
  invisible(df)
}

# Read an upstream table; fails loudly if the producing script has not run.
read_table <- function(path) {
  if (!file.exists(path)) stop("Missing input table ", path, ": run its script first (see run_all.R).")
  tibble::as_tibble(utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE))
}
read_analysis <- function(name) read_table(analysis_path(name))

# Display helpers for publication tables: fixed decimals (keeps trailing zeros,
# as typeset), the main-text cave label, and "17 Oct 2022" dates.
fmt <- function(x, digits, missing = "") {
  ifelse(is.na(x), missing, formatC(round(x, digits), format = "f", digits = digits))
}
ms_cave <- function(cave) sub("Croc-2", "Croc 2", cave, fixed = TRUE)
fmt_day <- function(timestamp) {
  d <- as.Date(substr(timestamp, 1, 10))
  paste(as.integer(format(d, "%d")), format(d, "%b %Y"))
}

save_figure <- function(plot, name, width, height) {
  png_path <- file.path(FIG_DIR, paste0(name, ".png"))
  pdf_path <- file.path(FIG_DIR, paste0(name, ".pdf"))
  ggsave(png_path, plot, width = width, height = height, dpi = 300)
  # cairo_pdf embeds Unicode glyphs (e.g. the ≥ in Fig. S11's legend) that
  # the default pdf() device cannot draw.
  ggsave(pdf_path, plot, width = width, height = height,
         device = if (capabilities("cairo")) grDevices::cairo_pdf else "pdf")
  cat(sprintf("Figure written: %s (.png, .pdf)\n", file.path(FIG_DIR, name)))
  invisible(plot)
}

source("lib/pub_builders.R")
