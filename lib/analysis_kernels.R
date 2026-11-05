# =============================================================================
#  analysis_kernels.R  --  L1 pure abstractions (study-agnostic, package-ready)
# =============================================================================
#  Layer 1. Pure functions: values in -> values out; no I/O, no globals, no
#  seeds, no study labels. Sourced by analysis_processes.R (L2). Publishable as-is.
#  (Phase 2, increment 1: the self-contained kernels/utils. The MIXED-function
#  kernel extractions and parameter-lifting follow in later increments --
#  see LAYER_RESTRUCTURE_PLAN.md.)
# =============================================================================

# ----- Cross-correlation function + moving-block bootstrap peak-lag CI --------
estimate_ccf_peak_lag <- function(lag_vals, cor_vals) {
    peak_idx <- which.max(abs(cor_vals))

    peak_lag <- lag_vals[peak_idx]

    if (peak_idx == 1 || peak_idx == length(lag_vals)) {
      return(peak_lag)
    }

    x <- lag_vals[(peak_idx - 1):(peak_idx + 1)]
    y <- abs(cor_vals[(peak_idx - 1):(peak_idx + 1)])
    quad_fit <- lm(y ~ x + I(x^2))
    coefs <- coef(quad_fit)
    a2 <- unname(coefs["I(x^2)"])
    b1 <- unname(coefs["x"])

    if (is.na(a2) || abs(a2) < 1e-12) {
      return(peak_lag)
    }

    vertex <- -b1 / (2 * a2)
    if (!is.finite(vertex) || vertex < min(x) || vertex > max(x)) {
      return(peak_lag)
    }

    vertex
}

# ----- Per-lag i.i.d. pairs bootstrap of the CCF -----------------------------
lag_pairs_bootstrap <- function(a, b, lag_max = 24L, reps = 1000L, conf = 0.95) {
  n    <- length(a)
  lags <- seq.int(-lag_max, lag_max)
  lo_p <- (1 - conf) / 2
  hi_p <- 1 - lo_p

  purrr::map_dfr(lags, function(k) {
    if (k >= 0) {
      x <- a[seq_len(n - k)]
      y <- b[seq.int(k + 1L, n)]
    } else {
      kk <- -k
      x <- a[seq.int(kk + 1L, n)]
      y <- b[seq_len(n - kk)]
    }
    n_k      <- length(x)
    corr_obs <- stats::cor(x, y)

    boot <- replicate(reps, {
      idx <- sample.int(n_k, replace = TRUE)
      stats::cor(x[idx], y[idx])
    })
    ci <- stats::quantile(boot, c(lo_p, hi_p), names = FALSE, type = 7)

    tibble::tibble(
      lag_hr    = k,
      corr_obs  = corr_obs,
      ci_low    = ci[1],
      ci_high   = ci[2],
      boot_mean = mean(boot),
      boot_se   = stats::sd(boot),
      n_pairs   = n_k
    )
  })
}

dtw_align <- function(x, y, window_size = 7L) {
  n <- length(x)
  m <- length(y)
  if (n == 0 || m == 0) return(NULL)

  cost <- matrix(Inf, nrow = n + 1, ncol = m + 1)
  step <- matrix(0L, nrow = n + 1, ncol = m + 1)
  cost[1, 1] <- 0

  for (i in seq_len(n)) {
    j_min <- max(1L, i - window_size)
    j_max <- min(m, i + window_size)
    for (j in j_min:j_max) {
      local_cost <- abs(x[i] - y[j])
      prev_costs <- c(cost[i, j + 1], cost[i + 1, j], cost[i, j])
      best_idx   <- which.min(prev_costs)
      cost[i + 1, j + 1] <- local_cost + prev_costs[best_idx]
      step[i + 1, j + 1] <- best_idx
    }
  }

  if (!is.finite(cost[n + 1, m + 1])) return(NULL)

  i <- n
  j <- m
  path_i <- integer()
  path_j <- integer()

  while (i > 0 && j > 0) {
    path_i <- c(i, path_i)
    path_j <- c(j, path_j)
    move <- step[i + 1, j + 1]
    if (move == 1L) {
      i <- i - 1L
    } else if (move == 2L) {
      j <- j - 1L
    } else {
      i <- i - 1L
      j <- j - 1L
    }
  }

  tibble::tibble(
    idx_a = path_i,
    idx_b = path_j,
    lag_days = path_j - path_i
  ) %>%
    dplyr::mutate(
      dtw_distance = cost[n + 1, m + 1],
      path_length = n()
    )
}

# Circular time-shift of a series by k (surrogate: preserves x's autocorrelation,
# destroys the specific source->target lag alignment).
teopt_shift <- function(x, k) {
  n <- length(x); x[((seq_len(n) - 1L + k) %% n) + 1L]
}

assess_stationarity <- function(x) {
  if (!requireNamespace("tseries", quietly = TRUE)) {
    return(tibble::tibble(adf_stat = NA_real_, adf_p = NA_real_,
                          kpss_stat = NA_real_, kpss_p = NA_real_,
                          verdict = "tseries not installed"))
  }
  adf  <- suppressWarnings(tseries::adf.test(x))                  # H0: unit root
  kpss <- suppressWarnings(tseries::kpss.test(x, null = "Level")) # H0: stationary
  adf_reject  <- adf$p.value  < 0.05   # reject unit root  -> looks stationary
  kpss_reject <- kpss$p.value < 0.05   # reject stationary -> looks non-stationary
  verdict <- dplyr::case_when(
     adf_reject & !kpss_reject ~ "stationary",
    !adf_reject &  kpss_reject ~ "unit root (difference)",
    !adf_reject & !kpss_reject ~ "inconclusive (low power)",
    TRUE                       ~ "deterministic trend/seasonal (detrend)"
  )
  tibble::tibble(adf_stat  = unname(adf$statistic),  adf_p  = adf$p.value,
                 kpss_stat = unname(kpss$statistic), kpss_p = kpss$p.value,
                 verdict   = verdict)
}

# =============================================================================
# PLOT FUNCTIONS (take the results frame + a variant label for the title)
# =============================================================================
# Per-pair facet figures now hold up to 10 pair rows per cave (complete pair set),
# so their saved height scales with the pair count (base + per-facet inches).
facet_h <- function(n_pairs) 2 + 1.5 * max(1L, n_pairs)

# -----------------------------------------------------------------------------
# Output-filename suffixer: out_name("Fig14_LagBootstrap_Croc2", "raw", "png")
#   -> "Fig14_LagBootstrap_Croc2_raw.png"
# -----------------------------------------------------------------------------
out_name <- function(base, variant, ext) paste0(base, "_", variant, ".", ext)

# --- Preprocessing -----------------------------------------------------------
# Longest contiguous regularly-spaced run. Given the vector of consecutive
# spacings `gaps` (length n-1), return the row indices (1..n) of the longest
# run whose spacing stays within `tol` of `spacing`. Values in -> indices out.
longest_regular_run <- function(gaps, spacing = 1, tol = 0) {
  n <- length(gaps) + 1L
  if (n <= 1L) return(seq_len(n))
  is_break <- abs(gaps - spacing) > tol
  if (!any(is_break)) return(seq_len(n))
  breaks  <- c(0L, which(is_break), n)
  longest <- which.max(diff(breaks))
  (breaks[longest] + 1L):breaks[longest + 1L]
}

# Harmonic-spline detrend: residuals of a natural-cubic-spline trend (df) plus a
# single sinusoid of the given period. Values in -> residuals out.
harmonic_detrend <- function(x, period = 24, df = 8) {
  t <- seq_along(x)
  residuals(lm(x ~ splines::ns(t, df = df) + sin(2 * pi * t / period) + cos(2 * pi * t / period)))
}

# ----- CCF lag profile (native lag convention; NO sign flip) -----------------
# Cross-correlation of a against b over +/- lag_max, in R's native convention:
# ccf(a, b)[k] = cor(a[t+k], b[t]). Any study sign convention is applied by the
# caller (see ccf_pair, which flips so positive lag = a leads b). Values -> frame.
ccf_lag_profile <- function(a, b, lag_max) {
  cc <- ccf(a, b, lag.max = lag_max, plot = FALSE)
  tibble::tibble(lag = as.numeric(cc$lag), correlation = as.numeric(cc$acf))
}

# ----- Cross-spectral coherence + phase --------------------------------------
# Smoothed-periodogram squared coherency and phase between series a and b, plus
# the 95% coherency significance threshold (Bloomfield 2000, eq. 9.6). One row
# per Fourier frequency; period-band windowing and pair labels are the caller's.
coherence_phase_profile <- function(a, b, spans = c(15, 15)) {
  sp <- spec.pgram(cbind(a = a, b = b), spans = spans, plot = FALSE,
                   demean = TRUE, detrend = FALSE, fast = FALSE)
  alpha      <- 0.05
  sig_thresh <- 1 - alpha^(1 / (sp$df / 2 - 1))
  freq <- sp$freq
  tibble::tibble(
    freq         = freq,
    period_hr    = 1 / freq,
    coherency_sq = as.numeric(sp$coh),
    phase_rad    = as.numeric(sp$phase),
    delay_hr     = as.numeric(sp$phase) / (2 * pi * freq),
    sig_thresh   = sig_thresh
  )
}

# ----- Transfer entropy: bidirectional effective TE + net --------------------
# Effective transfer entropy each way between series a and b (RTransferEntropy),
# with bootstrap SE/p-values, and the net (a->b minus b->a). Pure numeric TE; the
# caller attaches study labels + the dominant-direction string. `seed` is supplied
# by the caller (an L2-owned RNG seed). Values in -> one-row frame out.
te_net_directional <- function(a, b, lx, ly, quantiles, shuffles, nboot, seed) {
  fit <- RTransferEntropy::transfer_entropy(
    x = a, y = b, lx = lx, ly = ly, entropy = "Shannon",
    type = "quantiles", quantiles = quantiles,
    shuffles = shuffles, nboot = nboot, seed = seed, quiet = TRUE)
  cm <- coef(fit)   # rows X->Y (a->b), Y->X (b->a); cols te, ete, se, p-value
  ete_ab <- cm["X->Y", "ete"]; ete_ba <- cm["Y->X", "ete"]
  tibble::tibble(
    te_a_to_b = cm["X->Y", "te"], ete_a_to_b = ete_ab,
    se_a_to_b = cm["X->Y", "se"], p_a_to_b   = cm["X->Y", "p-value"],
    te_b_to_a = cm["Y->X", "te"], ete_b_to_a = ete_ba,
    se_b_to_a = cm["Y->X", "se"], p_b_to_a   = cm["Y->X", "p-value"],
    net_ete   = ete_ab - ete_ba
  )
}

# ----- Lag-informed (delayed) transfer entropy: TE_SPO delay scan ------------
# Delay-optimized TE (Wibral et al. 2013): align source x behind target y at a
# causal delay u, scan a window of delays, and take the one maximizing TE. Pure
# numeric TE-delay operators (RTransferEntropy); the study seed convention + the
# CCF-peak sign flip live in the L2 wrappers (teopt_ccf_peak / run_te_optimal_pair).
# `seed` is supplied by the caller (an L2-owned RNG seed). teopt_shift() above.

# Align source x and target y at causal source delay u >= 1 (x_{t-u} paired with
# y_t). Returns list(src, tgt) or NULL if the aligned overlap < min_overlap.
teopt_align_delay <- function(x, y, u, min_overlap) {
  n   <- length(x)
  src <- x[seq_len(n - u)]
  tgt <- y[seq.int(u + 1L, n)]
  if (length(src) < min_overlap) return(NULL)
  list(src = src, tgt = tgt)
}

# Raw TE source -> target at delay u (fast; used for the scan + surrogate null).
teopt_te_at <- function(x, y, u, te, min_overlap) {
  a <- teopt_align_delay(x, y, u, min_overlap)
  if (is.null(a)) return(NA_real_)
  suppressWarnings(RTransferEntropy::calc_te(
    a$src, a$tgt, lx = te$lx, ly = te$ly, entropy = "Shannon",
    type = "quantiles", quantiles = te$quantiles))
}

# Effective (bias-corrected) TE source -> target at delay u (slow; used once, at u*).
teopt_ete_at <- function(x, y, u, te, teopt, min_overlap, seed) {
  a <- teopt_align_delay(x, y, u, min_overlap)
  if (is.null(a)) return(NA_real_)
  suppressWarnings(RTransferEntropy::calc_ete(
    a$src, a$tgt, lx = te$lx, ly = te$ly, entropy = "Shannon",
    type = "quantiles", quantiles = te$quantiles,
    shuffles = teopt$shuffles, seed = seed))
}

# CCF-seeded delay window (u >= 1): +/- teopt$window hours around u_center, clipped
# to [1, teopt$lag_max]. RETAINED ONLY for the historical teopt_seedcheck.R diagnostic
# -- production no longer seeds the scan (teopt_direction below scans the full causal
# range directly), so this is not on the reported path.
teopt_grid <- function(u_center, teopt) {
  seq.int(max(1L, round(u_center) - teopt$window),
          min(teopt$lag_max, round(u_center) + teopt$window))
}

# Scan source x -> target y over the FULL causal delay range [1, teopt$lag_max]
# (systematic; no CCF seed -- the CCF peak is reported by the L2 wrapper as a linear
# reference only). Returns the TE(u) profile, the argmax delay u*, whether u* sits on
# a grid edge (u_edge: min or max of the grid -- an interior peak is better localised
# than an edge-pinned one), the bias-corrected ETE at u*, and a surrogate p-value for
# the scanned max (null = circularly-shifted source, re-scanned, grid-max TE).
teopt_direction <- function(x, y, te, teopt, min_overlap, seed) {
  u_grid <- seq_len(teopt$lag_max)
  te_prof <- vapply(u_grid, function(u) teopt_te_at(x, y, u, te, min_overlap), numeric(1))
  if (all(is.na(te_prof))) return(NULL)
  i        <- which.max(te_prof)
  u_star   <- u_grid[i]
  u_edge   <- u_star == min(u_grid) || u_star == max(u_grid)
  te_star  <- te_prof[i]
  ete_star <- teopt_ete_at(x, y, u_star, te, teopt, min_overlap, seed)
  n        <- length(x)
  offs     <- unique(round(seq(n / (teopt$nsurr + 1),
                               n - n / (teopt$nsurr + 1),
                               length.out = teopt$nsurr)))
  surr_max <- vapply(offs, function(k) {
    xs <- teopt_shift(x, k)
    max(vapply(u_grid, function(u) teopt_te_at(xs, y, u, te, min_overlap), numeric(1)), na.rm = TRUE)
  }, numeric(1))
  p_delay <- (1 + sum(surr_max >= te_star, na.rm = TRUE)) / (1 + length(surr_max))
  list(u_grid = u_grid, te = te_prof, u_star = u_star, u_edge = u_edge,
       te_star = te_star, ete_star = ete_star, p_delay = p_delay)
}
