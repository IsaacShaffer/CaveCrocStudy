# =============================================================================
# directional.R -- directional computations needed by more than one output
# =============================================================================
# Question 3 of the study asks how heat moves through each cave. Each function
# below answers it with a different method, and each is used both by a
# publication table (computed from the data) and by an intermediate table that
# feeds a figure:
#   ccf_summary        SI Table S3; A07 -> SI Figs. S1, S11
#   coherence_spectra  A09 -> SI Figs. S4, S5; and coherence_peaks below
#   coherence_peaks    MS Table 5, SM2 Table S3, SI Table S4; A08 -> MS Fig. 4,
#                      SI Figs. S6, S11
#   te_summary         SI Table S5; A10 -> SI Figs. S7, S11
#   teopt_results      SI Table S6; A11 -> SI Figs. S10, S11; A12 -> S8, S9
# All take the prepared pairs from prepare_pairs() (lib/study_data.R), so the
# raw/detrended choice is made by the calling script.
# =============================================================================

# -----------------------------------------------------------------------------
# Cross-correlation
# -----------------------------------------------------------------------------
# Correlation of a and b at lags -lag_max..+lag_max hours. R's ccf(a, b) at lag
# k is cor(a[t+k], b[t]), so a peak at k > 0 means b leads. The sign is flipped
# so that a positive lag means a leads b, the convention used throughout.
ccf_profile <- function(a, b, lag_max) {
  cc <- stats::ccf(a, b, lag.max = lag_max, plot = FALSE)
  tibble(lag_hr = -as.numeric(cc$lag), correlation = as.numeric(cc$acf))
}

# Lag of the strongest |correlation|, refined below the 1 h sampling step by
# fitting a parabola through the peak and its two neighbours and taking its
# vertex. Falls back to the whole-hour lag at the profile edge or when the fit
# is flat or puts the vertex outside the three points.
ccf_peak_lag <- function(lag_vals, cor_vals) {
  i <- which.max(abs(cor_vals))
  if (i == 1 || i == length(lag_vals)) return(lag_vals[i])
  x <- lag_vals[(i - 1):(i + 1)]
  y <- abs(cor_vals[(i - 1):(i + 1)])
  co <- coef(lm(y ~ x + I(x^2)))
  a2 <- unname(co["I(x^2)"]); b1 <- unname(co["x"])
  if (is.na(a2) || abs(a2) < 1e-12) return(lag_vals[i])
  vertex <- -b1 / (2 * a2)
  if (!is.finite(vertex) || vertex < min(x) || vertex > max(x)) return(lag_vals[i])
  vertex
}

# Cross-correlation peak per pair. If water warms at station a and the same
# change reaches station b some hours later, the correlation between a and b
# shifted by that many hours is highest. So for each pair:
#   1. correlate a with b at every shift from -24 to +24 h (one diurnal cycle
#      each way); positive lag = a's changes appear first, i.e. a leads b;
#   2. take the shift with the strongest |correlation| and refine it below the
#      hourly step with a parabola through the peak (ccf_peak_lag);
#   3. compare the peak with 1.96/sqrt(n), the 95% bound for a correlation
#      between independent series. Hourly temperatures are strongly
#      autocorrelated, so this bound is lenient; the per-lag bootstrap (SI Figs. S2, S3)
#      shows the uncertainty of the whole curve.
ccf_summary <- function(pairs) {
  purrr::map_dfr(pairs, function(p) {
    prof <- ccf_profile(p$a, p$b, CCF_LAGMAX)
    peak <- which.max(abs(prof$correlation))
    sig  <- 1.96 / sqrt(p$n_overlap)
    tibble(Cave                 = p$cave,
           Pair                 = p$pair,
           n_hours_overlap      = p$n_overlap,
           peak_lag_hr          = round(ccf_peak_lag(prof$lag_hr,
                                                     prof$correlation),
                                        2),
           peak_correlation     = round(prof$correlation[peak], 3),
           zero_lag_correlation = round(prof$correlation[prof$lag_hr == 0], 3),
           sig_threshold        = round(sig, 3),
           peak_is_significant  = abs(prof$correlation[peak]) > sig)
  }) %>%
    arrange(Cave, Pair)
}

# -----------------------------------------------------------------------------
# Cross-spectral coherence and phase
# -----------------------------------------------------------------------------
# For each pair, the smoothed cross-periodogram (modified Daniell, spans 15,15)
# gives at every frequency:
#   coherency_sq  share of variance the two series have in common at that
#                 frequency (a frequency-specific R^2)
#   phase_rad     phase of b relative to a; delay_hr = phase / (2 pi f) turns it
#                 into hours, positive = a leads
#   sig_thresh    95% significance level of coherency_sq (Bloomfield 2000,
#                 eq. 9.6), from the smoother's degrees of freedom
# Periods are limited to 2-168 h: below 2 h is at the hourly Nyquist limit,
# above a week too few cycles fit in the record to estimate.
coherence_spectra <- function(pairs) {
  purrr::map_dfr(pairs, function(p) {
    sp <- spec.pgram(cbind(a = p$a, b = p$b), spans = c(15, 15), plot = FALSE,
                     demean = TRUE, detrend = FALSE, fast = FALSE)
    tibble(Cave = p$cave, Pair = p$pair, n_overlap = p$n_overlap,
           freq         = sp$freq,
           period_hr    = 1 / sp$freq,
           coherency_sq = as.numeric(sp$coh),
           phase_rad    = as.numeric(sp$phase),
           delay_hr     = as.numeric(sp$phase) / (2 * pi * sp$freq),
           sig_thresh   = 1 - 0.05^(1 / (sp$df / 2 - 1))) %>%
      filter(period_hr >= 2, period_hr <= 168)
  })
}

# Peak of each pair's coherence spectrum: the period at which the two stations
# are most tightly linked, and the delay there.
#   peak_coherency_sq   how strongly linked (0-1);
#   delay_at_peak_hr    by how many hours, positive = first logger leads;
#   peak_is_significant whether coherency exceeds its 95% threshold. The delay
#                       is only meaningful where it does.
coherence_peaks <- function(pairs) {
  coherence_spectra(pairs) %>%
    group_by(Cave, Pair) %>%
    slice_max(coherency_sq, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(Cave, Pair,
              n_hours_overlap     = n_overlap,
              peak_period_hr      = round(period_hr, 2),
              peak_coherency_sq   = round(coherency_sq, 3),
              phase_at_peak_rad   = round(phase_rad, 3),
              delay_at_peak_hr    = round(delay_hr, 2),
              sig_threshold       = round(sig_thresh, 3),
              peak_is_significant = coherency_sq > sig_thresh) %>%
    arrange(Cave, Pair)
}

# -----------------------------------------------------------------------------
# Transfer entropy
# -----------------------------------------------------------------------------
# Correlation and coherence are symmetric: a lag says which station changes
# first, not which one drives the other. Transfer entropy (TE) is directional.
# TE(a -> b) asks how much knowing a's last hour improves prediction of b's
# next hour beyond what b's own last hour already tells. Steps per pair:
#   1. discretize each series into four quantile bins (25/50/75%), so the
#      estimate does not depend on the temperature scale or on outliers;
#   2. compute TE both ways with one hour of history (lx = ly = 1);
#   3. subtract the mean TE of 100 shuffled sources (effective TE, ETE), which
#      removes the positive bias of TE in finite samples;
#   4. bootstrap 300 times for a standard error and p-value per direction.
# net_ete = ETE(a -> b) - ETE(b -> a); its sign names the dominant direction.
# Slow: several minutes per variant.
te_summary <- function(pairs) {
  purrr::map_dfr(pairs, function(p) {
    fit <- RTransferEntropy::transfer_entropy(
      x = p$a, y = p$b, lx = TE$lx, ly = TE$ly, entropy = "Shannon",
      type = "quantiles", quantiles = TE$quantiles,
      shuffles = TE$shuffles, nboot = TE$nboot, seed = SEED, quiet = TRUE)
    cm  <- coef(fit)   # rows "X->Y" (a -> b) and "Y->X" (b -> a)
    la  <- sub("-.*", "", p$pair); lb <- sub(".*-", "", p$pair)
    net <- cm["X->Y", "ete"] - cm["Y->X", "ete"]
    tibble(Cave = p$cave, Pair = p$pair, n_overlap = p$n_overlap,
           te_a_to_b  = cm["X->Y", "te"], ete_a_to_b = cm["X->Y", "ete"],
           se_a_to_b  = cm["X->Y", "se"], p_a_to_b   = cm["X->Y", "p-value"],
           te_b_to_a  = cm["Y->X", "te"], ete_b_to_a = cm["Y->X", "ete"],
           se_b_to_a  = cm["Y->X", "se"], p_b_to_a   = cm["Y->X", "p-value"],
           net_ete    = net,
           dominant_direction = if (net >= 0) paste0(la, " -> ", lb) else paste0(lb, " -> ", la))
  }) %>%
    arrange(Cave, Pair) %>%
    mutate(across(where(is.numeric), ~ round(.x, 5)))
}

# -----------------------------------------------------------------------------
# Delay-optimized transfer entropy (Wibral et al. 2013)
# -----------------------------------------------------------------------------
# Ordinary TE asks whether a's last hour predicts b's next hour. Heat may take
# several hours to travel between stations, so here the source is delayed by u
# hours (a[t-u] paired with b[t]) and u is scanned from 1 to TEOPT$lag_max. The
# delay with the largest TE, u*, is the estimated travel time.

# Plain TE at one delay (fast; used for the scan and for the surrogates).
te_at_delay <- function(x, y, u) {
  n <- length(x)
  suppressWarnings(RTransferEntropy::calc_te(
    x[seq_len(n - u)], y[seq.int(u + 1L, n)], lx = TE$lx, ly = TE$ly,
    entropy = "Shannon", type = "quantiles", quantiles = TE$quantiles))
}

# Effective TE at one delay: TE minus its mean under shuffled sources, which
# removes small-sample bias (slow; computed once, at u*).
ete_at_delay <- function(x, y, u) {
  n <- length(x)
  suppressWarnings(RTransferEntropy::calc_ete(
    x[seq_len(n - u)], y[seq.int(u + 1L, n)], lx = TE$lx, ly = TE$ly,
    entropy = "Shannon", type = "quantiles", quantiles = TE$quantiles,
    shuffles = TEOPT$shuffles, seed = SEED))
}

# One direction, x -> y. Picking the maximum of 24 TE values inflates it, so u*
# is tested against surrogates: x is circularly shifted by an offset (keeping
# its own autocorrelation but breaking its timing relative to y), the whole
# scan is repeated, and its maximum recorded. p_delay is the share of
# surrogate maxima at or above the observed maximum. u_edge flags u* at 1 or
# lag_max, where the true optimum may lie outside the scanned range.
teopt_direction <- function(x, y) {
  u_grid  <- seq_len(TEOPT$lag_max)
  te_prof <- vapply(u_grid, function(u) te_at_delay(x, y, u), numeric(1))
  i       <- which.max(te_prof)
  n       <- length(x)
  offsets <- unique(round(seq(n / (TEOPT$nsurr + 1), n - n / (TEOPT$nsurr + 1),
                              length.out = TEOPT$nsurr)))
  surr_max <- vapply(offsets, function(k) {
    xs <- x[((seq_len(n) - 1L + k) %% n) + 1L]
    max(vapply(u_grid, function(u) te_at_delay(xs, y, u), numeric(1)), na.rm = TRUE)
  }, numeric(1))
  list(u_grid = u_grid, te = te_prof, u_star = u_grid[i],
       u_edge = i == 1L || i == length(u_grid),
       ete_star = ete_at_delay(x, y, u_grid[i]),
       p_delay  = (1 + sum(surr_max >= te_prof[i], na.rm = TRUE)) / (1 + length(surr_max)))
}

# Both directions for every pair. Returns list(summary = one row per pair,
# profiles = TE at every u per direction). The CCF peak lag is reported beside
# u* as a linear reference; it does not limit the scan. A12 needs the profiles
# and A11 / SI Table S6 the summary; each recomputes it (several minutes).
# The summary is rounded to 5 decimals, as reported.
teopt_results <- function(pairs) {
  res <- lapply(pairs, function(p) {
    prof  <- ccf_profile(p$a, p$b, TEOPT$lag_max)
    u_ccf <- ccf_peak_lag(prof$lag_hr, prof$correlation)
    ab <- teopt_direction(p$a, p$b)
    ba <- teopt_direction(p$b, p$a)
    la <- sub("-.*", "", p$pair); lb <- sub(".*-", "", p$pair)
    net <- ab$ete_star - ba$ete_star
    list(
      summary = tibble(
        Cave = p$cave, Pair = p$pair, n_overlap = p$n_overlap, u_ccf_hr = u_ccf,
        ete_a_to_b = ab$ete_star, u_star_a_to_b_hr = ab$u_star, p_delay_a_to_b = ab$p_delay,
        edge_a_to_b = ab$u_edge,
        ete_b_to_a = ba$ete_star, u_star_b_to_a_hr = ba$u_star, p_delay_b_to_a = ba$p_delay,
        edge_b_to_a = ba$u_edge,
        net_ete = net,
        dominant_direction = if (net >= 0) paste0(la, " -> ", lb) else paste0(lb, " -> ", la)),
      profile = bind_rows(
        tibble(Cave = p$cave, Pair = p$pair, direction = paste0(la, "->", lb),
               u_hr = ab$u_grid, te = ab$te, u_star = ab$u_star),
        tibble(Cave = p$cave, Pair = p$pair, direction = paste0(lb, "->", la),
               u_hr = ba$u_grid, te = ba$te, u_star = ba$u_star)))
  })
  list(summary  = purrr::map_dfr(res, "summary") %>%
                   arrange(Cave, Pair) %>%
                   mutate(across(where(is.numeric), ~ round(.x, 5))),
       profiles = purrr::map_dfr(res, "profile") %>%
                   arrange(Cave, Pair, direction, u_hr))
}
