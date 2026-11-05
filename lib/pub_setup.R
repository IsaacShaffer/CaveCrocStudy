# =============================================================================
# pub_setup.R -- sourced first by every script in pub_code/
# =============================================================================
# lib/ holds only code that two or more scripts use. Everything specific to one
# table or figure lives in that table's or figure's own script, so the reasoning
# behind each output can be read in one file.
#
# Every publication table (tables/publication/) computes from the cleaned data
# in data/, never from another table, so any one can be recreated on its own.
# Figures read intermediate tables built from the same data by
# figures/analysis/.
#
# This file sets the packages, the timezone, the reported constants, the logger
# roster, and the output and formatting helpers. It then sources:
#   lib/study_data.R   loading the data, day/night tagging, nightly minima,
#                      record spans, pair preparation
#   lib/directional.R  CCF, coherence, transfer entropy, delay-optimized TE
#   lib/plots.R        figure saving and the pair-matrix heatmaps
# =============================================================================

if (!file.exists("lib/pub_setup.R")) {
  stop("Run pub_code scripts with pub_code/ as the working directory.")
}

suppressPackageStartupMessages({
  library(lubridate)
  library(ggplot2)
  library(patchwork)
  library(purrr)
  library(tidyr)
  library(dplyr)
})

# -----------------------------------------------------------------------------
# Timezone. The loggers record local clock time without a zone. The study
# window, however, is compared as UTC instants (see load_study_hourly), so the
# result depends on the session timezone. The published results were produced
# under America/Phoenix (UTC-7, no DST), which makes the effective window
# 2022-07-31 17:00 -> 2023-02-17 17:00 on the logger clock. Pinning the zone
# makes every output the same on any machine. See README.md.
# -----------------------------------------------------------------------------
Sys.setenv(TZ = "America/Phoenix")

# -----------------------------------------------------------------------------
# Inputs and study design (manuscript Methods)
# -----------------------------------------------------------------------------
DATA_FILE      <- "data/all_cave_temp_data_ext.xlsx"   # hourly Tw, one sheet per logger
PLACEMENT_FILE <- "data/logger_placement.csv"          # Table 1 location/placement text

# Analysis window: from 1 Aug 2022 to 18 Feb 2023, the date trail cameras showed
# the first cave draining (after which loggers may record air, not water).
WINDOW    <- c("2022-08-01", "2023-02-18")
# Thermal threshold (degC): upper 95% CI bound of mean body temperature of
# juvenile C. acutus, from a mixed model of the Lang (1979) data (Methods).
THRESHOLD <- 24.25

# Night 18:30-05:30 (manuscript Methods). Sunrise and sunset in Belize shift by
# only ~30 min over the year, so fixed clock windows are used. Day is the
# [05:50, 18:00) window behind the published SM2 daytime tables (the Methods
# state 06:30-15:30; see README.md).
NIGHT_START_MIN <- 18 * 60 + 30
NIGHT_END_MIN   <-  5 * 60 + 30
DAY_START_MIN   <-  5 * 60 + 50
DAY_END_MIN     <- 18 * 60

# Months in the analysis window, and the winter reporting period (the question
# is whether caves stay warm enough on the coldest nights of the year).
STUDY_MONTHS  <- format(seq(as.Date("2022-08-01"), as.Date("2023-02-01"), by = "month"), "%Y-%m")
WINTER        <- as.Date(c("2022-11-01", "2023-02-18"))
WINTER_MONTHS <- format(seq(WINTER[1], WINTER[2], by = "month"), "%Y-%m")

# Directional-analysis settings (reported in the Supplement).
MIN_OVERLAP <- 200L   # a pair needs >= 200 unbroken shared hours to be analysed
PERIOD      <- 24     # diurnal period removed by the detrend (h)
SPLINE_DF   <- 8L     # spline df of the detrend; smallest df that makes all 10
                      # loggers KPSS-stationary (SI Table S2)
CCF_LAGMAX  <- 24L    # +/- one diurnal cycle of lags (h)
TE          <- list(lx = 1L, ly = 1L, quantiles = c(25, 50, 75), nboot = 300L, shuffles = 100L)
TEOPT       <- list(lag_max = 24L, nsurr = 100L, shuffles = 100L)
SEED        <- 230945L   # one seed for every resampling step

# -----------------------------------------------------------------------------
# Logger roster and the complete within-cave pair set
# -----------------------------------------------------------------------------
LOGGERS <- tibble(
  Serial      = 21433126:21433135,
  Cave        = rep(c("Croc-2", "KHC"), each = 5),
  Logger      = rep(paste0("L", 1:5), 2),
  Logger_Name = paste0(rep(c("Croc2", "KHC"), each = 5), "-Logger", rep(1:5, 2)))

# All 10 pairs per cave, not only neighbours: no prior assumption about which
# stations exchange heat. Within a pair, "a" is the lower-numbered logger, and
# every directional statistic is signed so that positive = a leads/drives b.
PAIRS <- do.call(c, lapply(c("Croc-2", "KHC"), function(cv) {
  names <- LOGGERS$Logger_Name[LOGGERS$Cave == cv]
  lapply(combn(names, 2, simplify = FALSE), function(p) list(cave = cv, a = p[1], b = p[2]))
}))
PAIR_LEVELS <- c("L1-L2", "L1-L3", "L1-L4", "L1-L5", "L2-L3",
                 "L2-L4", "L2-L5", "L3-L4", "L3-L5", "L4-L5")

# Main-text cave colours (manuscript captions: Croc 2 blue, KHC orange; Okabe-Ito).
CAVE_COLOURS <- c("Croc-2" = "#56B4E9", "KHC" = "#E69F00")

# -----------------------------------------------------------------------------
# Output paths and I/O helpers
# -----------------------------------------------------------------------------
PUB_DIR      <- "output/tables/publication"
FIG_DIR      <- "output/figures"
ANALYSIS_DIR <- "output/figures/analysis"   # intermediate tables read by figures
for (d in c(PUB_DIR, FIG_DIR, ANALYSIS_DIR)) dir.create(d, recursive = TRUE, showWarnings = FALSE)

analysis_path <- function(name) file.path(ANALYSIS_DIR, paste0(name, ".csv"))
pub_path      <- function(name) file.path(PUB_DIR, paste0(name, ".csv"))

write_table <- function(df, path) {
  utils::write.csv(as.data.frame(df), path, row.names = FALSE, na = "")
  cat(sprintf("Table written: %s (%d rows)\n", path, nrow(df)))
  invisible(df)
}

# Read an input table; fails loudly if the producing script has not run.
read_table <- function(path) {
  if (!file.exists(path)) stop("Missing input table ", path, ": run its script first (see run_all.R).")
  as_tibble(utils::read.csv(path, check.names = FALSE, stringsAsFactors = FALSE))
}
read_analysis <- function(name) read_table(analysis_path(name))

# Publication formatting: fixed decimals that keep trailing zeros as typeset,
# the main-text cave label, and "17 Oct 2022" dates.
fmt <- function(x, digits, missing = "") {
  ifelse(is.na(x), missing, formatC(round(x, digits), format = "f", digits = digits))
}
ms_cave <- function(cave) sub("Croc-2", "Croc 2", cave, fixed = TRUE)
fmt_day <- function(timestamp) {
  d <- as.Date(substr(timestamp, 1, 10))
  paste(as.integer(format(d, "%d")), format(d, "%b %Y"))
}

source("lib/study_data.R")
source("lib/directional.R")
source("lib/plots.R")
