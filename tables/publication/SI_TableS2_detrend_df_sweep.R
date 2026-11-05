# =============================================================================
# SI_TableS2_detrend_df_sweep.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS2_detrend_df_sweep.csv
# What   : Supplement Table S2. Detrend spline-df sweep averaged over the ten
#          loggers: residual SD, noise removed per df step, variance removed
#          by the trend, and how many loggers pass KPSS.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS2_detrend_df_sweep.R
# =============================================================================
# The detrended variant removes a natural-spline trend whose flexibility is set
# by its df. Too few df leave seasonal drift in (series stay non-stationary);
# too many start removing real multi-day signal. This sweep justifies
# SPLINE_DF = 8: the smallest df at which all 10 loggers pass the KPSS test
# for level stationarity (statistic below the 5% critical value), after which
# the residual SD barely falls.
# =============================================================================
source("lib/pub_setup.R")

DF_SWEEP   <- c(2, 4, 6, 8, 10, 12, 16, 20, 24)
KPSS_CRIT5 <- 0.463   # KPSS level-stationarity critical value at 5%

hourly <- load_study_hourly()

per_logger <- purrr::map_dfr(LOGGERS$Logger_Name, function(lg) {
  # Same trimming rule as the pair analyses: the longest unbroken hourly run.
  s <- hourly %>%
    filter(Logger_Name == lg, !is.na(Temperature)) %>%
    arrange(date_time)
  s <- s[longest_regular_run(as.numeric(diff(s$date_time), units = "hours"), spacing = 1, tol = 0.1), ]
  if (nrow(s) < MIN_OVERLAP) return(NULL)
  x <- s$Temperature

  # The same model as harmonic_detrend (lib/study_data.R), at each df.
  t  <- seq_along(x)
  s1 <- sin(2 * pi * t / PERIOD)
  c1 <- cos(2 * pi * t / PERIOD)
  purrr::map_dfr(DF_SWEEP, function(df) {
    Xns   <- splines::ns(t, df = df)
    m     <- lm(x ~ Xns + s1 + c1)
    r     <- residuals(m)
    trend <- as.numeric(coef(m)[1] + Xns %*% coef(m)[2:(df + 1)])   # spline part only
    kp    <- unname(suppressWarnings(tseries::kpss.test(r, null = "Level"))$statistic)
    tibble(df = df,
           resid_sd        = sd(r),
           trend_var_pct   = 100 * var(trend) / var(x),   # share of variance that is slow trend
           kpss_stationary = kp < KPSS_CRIT5)
  })
})

tbl <- per_logger %>%
  group_by(df) %>%
  summarise(mean_resid_sd      = round(mean(resid_sd), 4),
            mean_trend_var_pct = round(mean(trend_var_pct), 1),
            n_kpss_stationary  = sum(kpss_stationary),
            .groups = "drop")
# Diminishing returns: how much more noise each step up in df removes.
tbl$noise_removed_vs_prev_df <- c(NA, round(-diff(tbl$mean_resid_sd), 5))

tbl <- tbl %>%
  transmute(df,
            `Mean resid. SD (°C)` = fmt(mean_resid_sd, 3),
            `Noise removed (°C)`  = fmt(noise_removed_vs_prev_df, 3, "---"),
            `Var. removed (%)`    = fmt(mean_trend_var_pct, 0),
            `n KPSS-stationary`   = n_kpss_stationary)

write_table(tbl, pub_path("SI_TableS2_detrend_df_sweep"))
