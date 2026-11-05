# =============================================================================
# SI_TableS2_detrend_df_sweep.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS2_detrend_df_sweep.csv
# What   : Supplement Table S2. Detrend spline-df sweep averaged over the ten loggers.
# Inputs : A06_detrend_df_sweep
# Run from pub_code/:  Rscript tables/publication/SI_TableS2_detrend_df_sweep.R
# =============================================================================
source("lib/pub_setup.R")

tbl <- read_analysis("A06_detrend_df_sweep") %>%
  transmute(df,
            `Mean resid. SD (°C)` = fmt(mean_resid_sd, 3),
            `Noise removed (°C)`  = fmt(noise_removed_vs_prev_df, 3, "---"),
            `Var. removed (%)`    = fmt(mean_trend_var_pct, 0),
            `n KPSS-stationary`   = n_kpss_stationary)

write_table(tbl, pub_path("SI_TableS2_detrend_df_sweep"))
