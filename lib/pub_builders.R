# =============================================================================
# pub_builders.R -- functions that build the analysis tables
# =============================================================================
# Sourced by lib/pub_setup.R. Each build_*() returns ONE table and writes
# nothing; the matching script in tables/analysis/ writes it. Directional
# builders reproduce the table logic of the run_*() drivers in L2_drivers.R
# (which also draw figures and write workbooks, so they cannot be reused 1:1),
# calling the same per-pair library functions, seeds and rounding.
# =============================================================================

# -----------------------------------------------------------------------------
# Data
# -----------------------------------------------------------------------------
.hourly_cache <- NULL
load_study_hourly <- function() {
  if (is.null(.hourly_cache)) {
    .hourly_cache <<- load_hourly_data(file = DATA_FILE, window = WINDOW,
                                       sensor_style = sensor_style, threshold = THRESHOLD) %>%
      mutate(Cave = as.character(Cave),
             Logger = short_logger(Logger_Name),
             # Local clock date. (The loader's date_only comes from as.Date(),
             # which uses UTC, so it rolls over at 17:00 local time.)
             clock_date = lubridate::date(date_time),
             tod_min = hour(date_time) * 60 + minute(date_time))
  }
  .hourly_cache
}

stationarizer <- function(variant) {
  switch(variant,
         raw       = identity,
         detrended = function(x) harmonic_detrend(x, period = PERIOD, df = SPLINE_DF),
         stop("Unknown variant: ", variant))
}

prepared_pairs <- function(variant) {
  prepare_pairs(load_study_hourly(), pairs_def_all,
                stationarize = stationarizer(variant), min_overlap = MIN_OVERLAP)
}

STUDY_MONTHS <- format(seq(as.Date("2022-08-01"), as.Date("2023-02-01"), by = "month"), "%Y-%m")

# Day/night tagging on the local clock. Night = [18:30, 24:00) U [00:00, 05:30],
# dated by the evening it starts on; day = [DAY_START, DAY_END).
diel_tagged <- function() {
  load_study_hourly() %>%
    mutate(is_day     = tod_min >= DAY_START_MIN & tod_min < DAY_END_MIN,
           is_night   = tod_min >= NIGHT_START_MIN | tod_min <= NIGHT_END_MIN,
           night_date = if_else(tod_min >= NIGHT_START_MIN, clock_date, clock_date - 1))
}

# -----------------------------------------------------------------------------
# Observational tables
# -----------------------------------------------------------------------------

# First/last timestamp each logger recorded, over the FULL deployment (not the
# analysis window).
build_logger_record_span <- function() {
  roster <- sensor_style %>% transmute(Serial = as.character(Location), Logger_Name)
  purrr::map_dfr(readxl::excel_sheets(DATA_FILE), function(s) {
    d  <- readxl::read_excel(DATA_FILE, sheet = s)
    dt <- openxlsx::convertToDateTime(d$Date + d$Time)
    tibble(Serial = as.character(d$Location[1]),
           first_logged = format(min(dt), "%Y-%m-%d %H:%M"),
           last_logged  = format(max(dt), "%Y-%m-%d %H:%M"),
           n_obs = nrow(d))
  }) %>%
    left_join(roster, by = "Serial") %>%
    transmute(Cave = ifelse(as.numeric(Serial) <= 21433130, "Croc-2", "KHC"),
              Logger = short_logger(Logger_Name), Logger_Name, Serial,
              first_logged, last_logged, n_obs) %>%
    arrange(Cave, Logger)
}

# Day and night summaries by month. by_logger = FALSE -> Cave x Month;
# TRUE -> Cave x Logger x Month. A day (night) counts as above threshold if at
# least one of its observations is >= THRESHOLD. At cave level a date counts
# once, whichever logger exceeded. Nightly range = max - min within one logger's
# night; median_nightly_range is the median over the group's logger-nights.
build_diel_summary <- function(by_logger = FALSE) {
  h   <- diel_tagged()
  grp <- if (by_logger) c("Cave", "Logger", "Logger_Name") else "Cave"

  day <- h %>% filter(is_day) %>%
    mutate(Month = format(clock_date, "%Y-%m")) %>%
    group_by(across(all_of(c(grp, "Month")))) %>%
    summarise(median_day   = round(median(Temperature, na.rm = TRUE), 2),
              n_days       = n_distinct(clock_date),
              n_days_above = n_distinct(clock_date[above_threshold]),
              .groups = "drop")

  nights <- h %>% filter(is_night) %>% mutate(Month = format(night_date, "%Y-%m"))
  night <- nights %>%
    group_by(across(all_of(c(grp, "Month")))) %>%
    summarise(median_night   = round(median(Temperature, na.rm = TRUE), 2),
              n_nights       = n_distinct(night_date),
              n_nights_above = n_distinct(night_date[above_threshold]),
              .groups = "drop")
  night_range <- nights %>%
    group_by(across(all_of(unique(c(grp, "Month", "Logger", "night_date"))))) %>%
    summarise(night_range = max(Temperature) - min(Temperature), .groups = "drop") %>%
    group_by(across(all_of(c(grp, "Month")))) %>%
    summarise(median_nightly_range = round(median(night_range), 2), .groups = "drop")

  full_join(day, night, by = c(grp, "Month")) %>%
    left_join(night_range, by = c(grp, "Month")) %>%
    filter(Month %in% STUDY_MONTHS) %>%
    arrange(across(all_of(c(grp, "Month"))))
}

# One row per logger per winter night: the night's minimum Tw.
build_nightly_minimum_winter <- function() {
  diel_tagged() %>%
    filter(is_night, night_date >= WINTER[1], night_date <= WINTER[2]) %>%
    group_by(Cave, Logger, Logger_Name, night_date) %>%
    summarise(n_obs = n(), night_min = min(Temperature), .groups = "drop") %>%
    arrange(Cave, Logger, night_date)
}

# Daily statistics per cave (all loggers pooled), by local clock date.
build_daily_cave_summary <- function() {
  load_study_hourly() %>%
    group_by(Date = clock_date, Cave) %>%
    summarise(n_obs       = n(),
              temp_median = median(Temperature, na.rm = TRUE),
              temp_min    = min(Temperature, na.rm = TRUE),
              temp_max    = max(Temperature, na.rm = TRUE),
              temp_q25    = quantile(Temperature, 0.25, na.rm = TRUE),
              temp_q75    = quantile(Temperature, 0.75, na.rm = TRUE),
              prop_above_threshold = mean(above_threshold, na.rm = TRUE),
              .groups = "drop") %>%
    arrange(Cave, Date)
}

# -----------------------------------------------------------------------------
# Detrend spline-df sweep (logic of df_sweep.R; per-df means over 10 loggers)
# -----------------------------------------------------------------------------
build_detrend_df_sweep <- function() {
  h <- load_study_hourly()
  loggers <- sort(unique(as.character(h$Logger_Name)))
  res <- purrr::map_dfr(loggers, function(lg) {
    x <- prep_one_series(h, lg, identity, min_overlap = MIN_OVERLAP)
    if (is.null(x)) return(NULL)
    t <- seq_along(x); s1 <- sin(2 * pi * t / PERIOD); c1 <- cos(2 * pi * t / PERIOD); vtot <- var(x)
    purrr::map_dfr(DF_SWEEP, function(df) {
      Xns <- splines::ns(t, df = df)
      m   <- lm(x ~ Xns + s1 + c1); r <- residuals(m)
      trend <- as.numeric(coef(m)[1] + Xns %*% coef(m)[2:(df + 1)])
      kp <- suppressWarnings(tseries::kpss.test(r, null = "Level"))$statistic
      tibble(logger = short_logger(lg), df = df,
             resid_sd = sd(r), trend_var_pct = 100 * var(trend) / vtot,
             R2 = 1 - var(r) / vtot, kpss = unname(kp),
             kpss_stationary = unname(kp) < KPSS_CRIT5)
    })
  })
  agg <- res %>% group_by(df) %>% summarise(
    mean_resid_sd      = round(mean(resid_sd), 4),
    mean_trend_var_pct = round(mean(trend_var_pct), 1),
    mean_R2            = round(mean(R2), 4),
    mean_kpss          = round(mean(kpss), 3),
    n_kpss_stationary  = sum(kpss_stationary), .groups = "drop")
  agg$noise_removed_vs_prev_df <- c(NA, round(-diff(agg$mean_resid_sd), 5))
  agg
}

# -----------------------------------------------------------------------------
# Directional analyses (one variant per call)
# -----------------------------------------------------------------------------

# Cross-correlation peak per pair (table logic of run_ccf).
build_ccf_summary <- function(variant) {
  ccf_results <- map_dfr(prepared_pairs(variant), function(p) {
    res <- ccf_pair(p$prep, CCF_LAGMAX)
    if (is.null(res)) return(NULL)
    res %>% mutate(Cave = p$cave, .before = 1)
  }) %>% mutate(pair_label = factor(pair_label, levels = all_pair_levels))

  zero_lag_corr <- ccf_results %>% filter(lag_hr == 0) %>%
    select(Cave, pair_label, zero_lag_correlation = correlation)

  ccf_results %>%
    group_by(Cave, pair_label, n_overlap, sig_thresh, peak_lag_interp_hr, peak_corr_abs) %>%
    slice_max(abs(correlation), n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    left_join(zero_lag_corr, by = c("Cave", "pair_label")) %>%
    transmute(Cave,
              Pair                 = as.character(pair_label),
              n_hours_overlap      = n_overlap,
              peak_lag_hr          = round(peak_lag_interp_hr, 2),
              peak_correlation     = round(correlation, 3),
              zero_lag_correlation = round(zero_lag_correlation, 3),
              sig_threshold        = round(sig_thresh, 3),
              peak_is_significant  = abs(correlation) > sig_thresh) %>%
    arrange(Cave, Pair)
}

# Full coherence/phase spectrum per pair, 2-168 h band (input of run_coherence_phase).
coherence_results <- function(variant) {
  map_dfr(prepared_pairs(variant), function(p) {
    res <- coh_phase_pair(p$prep)
    if (is.null(res)) return(NULL)
    res %>% mutate(Cave = p$cave, .before = 1)
  }) %>% mutate(pair_label = factor(pair_label, levels = all_pair_levels))
}

build_coherence_spectra <- function(variant) {
  coherence_results(variant) %>%
    transmute(Cave, Pair = as.character(pair_label), n_overlap, freq, period_hr,
              coherency_sq, phase_rad, delay_hr, sig_thresh) %>%
    arrange(Cave, Pair, period_hr)
}

# Peak coherency per pair (table logic of run_coherence_phase).
build_coherence_summary <- function(variant) {
  coherence_results(variant) %>%
    group_by(Cave, pair_label, n_overlap, sig_thresh) %>%
    slice_max(coherency_sq, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(Cave,
              Pair                = as.character(pair_label),
              n_hours_overlap     = n_overlap,
              peak_period_hr      = round(period_hr, 2),
              peak_coherency_sq   = round(coherency_sq, 3),
              phase_at_peak_rad   = round(phase_rad, 3),
              delay_at_peak_hr    = round(delay_hr, 2),
              sig_threshold       = round(sig_thresh, 3),
              peak_is_significant = coherency_sq > sig_thresh) %>%
    arrange(Cave, Pair)
}

# Effective transfer entropy per pair (table logic of run_transfer_entropy).
build_te_summary <- function(variant) {
  map_dfr(prepared_pairs(variant), function(p) {
    run_te_pair(p$prep, p$cave, p$a, p$b, te = TE)
  }) %>%
    mutate(Pair = factor(Pair, levels = all_pair_levels)) %>%
    arrange(Cave, Pair) %>%
    mutate(Pair = as.character(Pair)) %>%
    mutate(across(where(is.numeric), ~ round(.x, 5)))
}

# Delay-optimized TE. One computation yields both the per-pair summary and the
# TE(u) profiles, so the result is cached per variant in output/cache/ and
# reused by both table scripts. The cache is keyed on every setting that feeds
# it and is recomputed if any changes; run_all.R clears it at the start.
teopt_results <- function(variant) {
  settings <- list(variant = variant, window = WINDOW, tz = Sys.getenv("TZ"),
                   spline_df = SPLINE_DF, period = PERIOD, min_overlap = MIN_OVERLAP,
                   te = TE, teopt = TEOPT, seed = teopt_seed,
                   data_mtime = file.mtime(DATA_FILE))
  f <- file.path(CACHE_DIR, paste0("teopt_", variant, ".rds"))
  if (file.exists(f)) {
    cached <- readRDS(f)
    if (identical(cached$settings, settings)) return(cached)
  }
  res <- map(prepared_pairs(variant), function(p) {
    run_te_optimal_pair(p$prep, p$cave, p$a, p$b, te = TE, teopt = TEOPT,
                        min_overlap = MIN_OVERLAP)
  })
  res <- res[!vapply(res, is.null, logical(1))]
  out <- list(settings = settings,
              summary  = map_dfr(res, "summary"),
              profiles = map_dfr(res, "profile"))
  saveRDS(out, f)
  out
}

# Table logic of run_te_optimal.
build_teopt_summary <- function(variant) {
  teopt_results(variant)$summary %>%
    mutate(Pair = factor(Pair, levels = all_pair_levels)) %>%
    arrange(Cave, Pair) %>%
    mutate(Pair = as.character(Pair)) %>%
    mutate(across(where(is.numeric), ~ round(.x, 5)))
}

build_teopt_profiles <- function(variant) {
  teopt_results(variant)$profiles %>%
    mutate(Pair = factor(Pair, levels = all_pair_levels)) %>%
    arrange(Cave, Pair, direction, u_hr) %>%
    mutate(Pair = as.character(Pair))
}

# Per-lag i.i.d. pairs bootstrap of the cross-correlation (table logic of
# run_lag_bootstrap: one seed, pairs in pairs_def_all order).
build_lagboot <- function(variant) {
  pairs <- prepared_pairs(variant)
  set.seed(lagboot_seed)
  map_dfr(pairs, function(p) {
    prep <- p$prep
    if (is.null(prep)) return(NULL)
    lag_pairs_bootstrap(prep$a, prep$b, lag_max = LAGBOOT$lag_max,
                        reps = LAGBOOT$reps, conf = LAGBOOT$conf) %>%
      mutate(Cave = p$cave, pair_label = prep$pair_label[1],
             n_overlap = prep$n_overlap[1],
             sig_thresh = 1.96 / sqrt(prep$n_overlap[1]),
             ci_excludes_zero = (ci_low > 0) | (ci_high < 0),
             reps = LAGBOOT$reps, conf = LAGBOOT$conf, seed = lagboot_seed,
             .before = 1)
  }) %>%
    transmute(Cave,
              Pair      = as.character(pair_label),
              lag_hr,
              corr_obs  = round(corr_obs, 4),
              ci_low    = round(ci_low, 4),
              ci_high   = round(ci_high, 4),
              boot_mean = round(boot_mean, 4),
              boot_se   = round(boot_se, 4),
              n_pairs,
              ci_excludes_zero,
              sig_thresh = round(sig_thresh, 4),
              reps, conf, seed) %>%
    arrange(Cave, Pair, lag_hr)
}

# -----------------------------------------------------------------------------
# Raw vs detrended comparison, from the per-variant analysis tables (logic of
# Stationarity_Comparison.R), in long format: one row per Cave x Pair x statistic.
# -----------------------------------------------------------------------------
build_variant_comparison <- function() {
  both <- function(stem) lapply(setNames(VARIANTS, VARIANTS), function(v) read_analysis(paste0(stem, "_", v)))
  lagboot_peak <- function(tbl) tbl %>% group_by(Cave, Pair) %>%
    slice_max(abs(corr_obs), n = 1, with_ties = FALSE) %>% ungroup() %>%
    transmute(Cave, Pair, lagboot_peak_corr = corr_obs, lagboot_peak_lag_hr = lag_hr)

  sets <- list(
    list(analysis = "CCF",          tbl = both("A07_ccf_summary"),       cols = c("peak_correlation", "peak_lag_hr"), f = identity),
    list(analysis = "Coherence",    tbl = both("A08_coherence_summary"), cols = c("peak_coherency_sq", "delay_at_peak_hr"), f = identity),
    list(analysis = "TransferEntropy", tbl = both("A10_te_summary"),     cols = "net_ete", f = identity),
    list(analysis = "TEOptimal",    tbl = both("A11_teopt_summary"),     cols = "net_ete", f = identity),
    list(analysis = "LagBootstrap", tbl = both("A13_lagboot"),           cols = c("lagboot_peak_corr", "lagboot_peak_lag_hr"), f = lagboot_peak)
  )
  purrr::map_dfr(sets, function(s) {
    cmp <- compare_variants(s$f(s$tbl$raw), s$f(s$tbl$detrended), value_cols = s$cols)
    purrr::map_dfr(s$cols, function(col) {
      cmp %>% transmute(analysis = s$analysis, Cave, Pair, statistic = col,
                        raw       = .data[[paste0(col, "_raw")]],
                        detrended = .data[[paste0(col, "_detrended")]],
                        delta     = .data[[paste0(col, "_delta")]],
                        same_sign = sign(raw) == sign(detrended))
    })
  })
}
