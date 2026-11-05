# =============================================================================
# A13_lagboot_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A13_lagboot_detrended.csv
# What   : Cross-correlation at each lag from -24 to +24 h with a 95% bootstrap
#          interval, per within-cave logger pair (detrended variant).
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: SI_FigS2, SI_FigS3
# Run from pub_code/:  Rscript figures/analysis/A13_lagboot_detrended.R
# =============================================================================
# SI Table S3 reports only the peak of the cross-correlation. This gives the whole
# curve with an uncertainty band, so a reader can see whether the peak stands
# clearly above neighbouring lags. At each lag k the series are aligned
# (a[t] with b[t + k], positive k = a leads), and the aligned (a, b) pairs are
# resampled with replacement 1000 times; the 2.5% and 97.5% quantiles of the
# resampled correlations give the interval. Resampling individual hours treats
# them as independent, which they are not, so the interval is narrower than a
# block bootstrap would give; ci_excludes_zero should be read in that light.
# One seed is set once, before the first pair, so results depend on pair order.
# =============================================================================
source("lib/pub_setup.R")

LAGBOOT <- list(reps = 1000L, conf = 0.95, lag_max = 24L)

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), so the statistics reflect
# station-to-station timing rather than forcing shared by all stations.
pairs <- prepare_pairs(harmonic_detrend)

lo_p <- (1 - LAGBOOT$conf) / 2
hi_p <- 1 - lo_p

set.seed(SEED)
tbl <- purrr::map_dfr(pairs, function(p) {
  n <- length(p$a)
  purrr::map_dfr(seq.int(-LAGBOOT$lag_max, LAGBOOT$lag_max), function(k) {
    if (k >= 0) {
      x <- p$a[seq_len(n - k)];         y <- p$b[seq.int(k + 1L, n)]
    } else {
      x <- p$a[seq.int(-k + 1L, n)];    y <- p$b[seq_len(n + k)]
    }
    boot <- replicate(LAGBOOT$reps, {
      idx <- sample.int(length(x), replace = TRUE)
      cor(x[idx], y[idx])
    })
    ci <- quantile(boot, c(lo_p, hi_p), names = FALSE, type = 7)
    tibble(Cave             = p$cave,
           Pair             = p$pair,
           lag_hr           = k,
           corr_obs         = round(cor(x, y), 4),
           ci_low           = round(ci[1], 4),
           ci_high          = round(ci[2], 4),
           boot_mean        = round(mean(boot), 4),
           boot_se          = round(sd(boot), 4),
           n_pairs          = length(x),
           ci_excludes_zero = ci[1] > 0 | ci[2] < 0,
           sig_thresh       = round(1.96 / sqrt(p$n_overlap), 4),
           reps = LAGBOOT$reps, conf = LAGBOOT$conf, seed = SEED)
  })
}) %>%
  arrange(Cave, Pair, lag_hr)

write_table(tbl, analysis_path("A13_lagboot_detrended"))
