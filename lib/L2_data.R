# =============================================================================
# L2_data.R -- study data facts + loading/preparation
# =============================================================================
# Sourced by analysis_processes.R. L2 layer: the label mechanism (short_logger),
# the RNG seeds, the data loader, and the pair/series preparers. Data-shaping
# VALUES (file, window, threshold, sensor roster, pair sets, label ordering) are
# NOT here -- they are declared in the L3 driver scripts and passed in.
# =============================================================================


# -----------------------------------------------------------------------------
# L2 mechanism / convention
# -----------------------------------------------------------------------------
# Data-shaping information -- the dataset file, study window, thermal threshold,
# the sensor roster (sensor_style), the logger-pair sets (pairs_def / pairs_def_all)
# and the pair-label ordering (all_pair_levels) -- is NOT captured here. It is
# declared in the driver scripts (Model_Analyses.R, Observational_Analysis.R) and
# handed through the interfaces: load_hourly_data(file, window, sensor_style,
# threshold), prepare_pairs(hourly, pair_defs, ...), run_dtw(hourly, pairs, ...),
# and run_*(..., pair_levels). Pinning any of it in L2 too would be a second
# source of truth. What remains here is genuine L2 mechanism/convention:
# short_logger() (the pure label transform) and the RNG seeds.

short_logger <- function(name) sub(".*-Logger", "L", name)

# -----------------------------------------------------------------------------
# RNG seeds (L2 -- NOT reported in the manuscript, so NOT threaded from L3;
# kept per-analysis, need not match). The reported tuning that used to sit here
# (lag-bootstrap reps/conf/lagmax; TE lx/ly/quantiles/nboot/shuffles) now lives
# in Model_Analyses.R and is passed into the drivers as `lagboot=` / `te=`.
# -----------------------------------------------------------------------------
lagboot_seed <- 230945L
te_seed      <- 230945L

# -----------------------------------------------------------------------------
# Data loading (single source of truth for all drivers)
# -----------------------------------------------------------------------------
# `file`, `window` (c(start, end)), `sensor_style` (the roster joined by Location)
# and `threshold` are L3 data-shaping choices, passed in by the driver script
# (Model_Analyses.R / Observational_Analysis.R) -- not defaulted here, so the
# loader never silently bakes in a dataset, window, or sensor roster.
load_hourly_data <- function(file, window, sensor_style, threshold = NULL) {
  df <- purrr::map_dfr(
    readxl::excel_sheets(file),
    ~ readxl::read_excel(file, sheet = .x)) %>%
    mutate(
      Cave = ifelse(Location <= 21433130, "Croc-2", "KHC"),
      Cave = as.factor(Cave),
      Location = as.factor(Location),
      date_time = convertToDateTime(Date + Time)
    ) %>%
    filter(date_time >= as_datetime(window[1]) & date_time <= as_datetime(window[2])) %>%
    left_join(sensor_style, by = "Location") %>%
    mutate(
      date_only = as.Date(date_time),
      week  = floor_date(date_only, "week"),
      month = floor_date(date_only, "month"),
      hour  = hour(date_time),
      Season = factor(
        ifelse(date_only < as.Date("2022-12-01"), "Wet", "Dry"),
        levels = c("Wet", "Dry")
      )
    )
  # above_threshold is an Observational_Analysis.R feature; compute it only when
  # that driver passes its reported threshold. Model_Analyses.R omits it.
  if (!is.null(threshold)) df$above_threshold <- df$Temperature >= threshold
  df
}

# -----------------------------------------------------------------------------
# Canonical pair preparer. Trims a logger pair to its longest contiguous hourly
# overlap, then applies the caller-supplied `stationarize` transform to each
# series and returns the paired result. `stationarize` is a function (vector ->
# vector) chosen by the L3 driver -- `identity` for a raw run, or a harmonic
# detrend closure for a detrended run, e.g.
#
#     detrend <- function(x) harmonic_detrend(x, period = 24, df = 8)
#       # residuals(lm(x ~ ns(t, df=8) + sin(2*pi*t/24) + cos(2*pi*t/24))): a
#       # natural-cubic-spline "variable mean" in time (df = 8, the smallest df
#       # KPSS-stationary for all 10 loggers; Suppl. S3.2) plus a diurnal sin+cos.
#
# So the raw/detrended difference is carried entirely by the DATA this returns;
# prepare_pair itself branches on nothing. Returns NULL if the contiguous run
# < min_overlap (pairs with <200 h dropped).
# -----------------------------------------------------------------------------
prepare_pair <- function(df, logger_a, logger_b, stationarize, min_overlap) {
  pair_wide <- df %>%
    filter(Logger_Name %in% c(logger_a, logger_b)) %>%
    select(date_time, Logger_Name, Temperature) %>%
    pivot_wider(names_from = Logger_Name, values_from = Temperature) %>%
    arrange(date_time) %>%
    filter(complete.cases(.))

  if (nrow(pair_wide) < min_overlap) return(NULL)

  # Keep only the longest contiguous 1-hour-spaced run (spacing within 6 min of
  # 1 h); a dropout there breaks the regular sampling the CCF/spectral/lag/TE
  # methods require. longest_regular_run() is the L1 kernel.
  hr_gap    <- as.numeric(diff(pair_wide$date_time), units = "hours")
  pair_wide <- pair_wide[longest_regular_run(hr_gap, spacing = 1, tol = 0.1), ]
  if (nrow(pair_wide) < min_overlap) return(NULL)

  # `stationarize` is the data-shaping transform chosen by the L3 driver
  # (identity for a raw run; a harmonic-detrend closure for a detrended run),
  # applied to each logger's trimmed series. The raw/detrended distinction lives
  # entirely in this data -- the downstream analyses receive it and branch on
  # nothing.
  tibble(
    a = stationarize(pair_wide[[logger_a]]),
    b = stationarize(pair_wide[[logger_b]])
  ) %>%
    mutate(
      pair_label = paste0(short_logger(logger_a), "-", short_logger(logger_b)),
      n_overlap  = nrow(pair_wide),
      .before    = 1
    )
}

# Data-shaping for the whole pair set: prepare every within-cave pair under one
# stationarizer, ONCE, so all five directional analyses consume the same shaped
# data (rather than each re-preparing it). Returns a list aligned with
# pairs_def_all, each element carrying the pair's cave/logger identity plus its
# prepared series `prep` (NULL where the overlap is too short). The stationarizer
# is the L3 data-shaping choice; the only thing that differs between a raw and a
# detrended run is the data this produces.
prepare_pairs <- function(hourly, pair_defs, stationarize, min_overlap) {
  lapply(pair_defs, function(p)
    list(cave = p$cave, a = p$a, b = p$b,
         prep = prepare_pair(hourly, p$a, p$b, stationarize = stationarize,
                             min_overlap = min_overlap)))
}
