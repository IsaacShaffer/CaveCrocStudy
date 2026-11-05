# =============================================================================
# L2_drivers.R -- per-pair compute wrappers + high-level run_* drivers
# =============================================================================
# Sourced by analysis_processes.R. Each per-pair wrapper (ccf_pair, coh_phase_pair,
# run_te_pair, teopt_ccf_peak, run_te_optimal_pair, run_dtw_pair, prep_one_series,
# prep_dtw_pair) calls the L1 kernels; each run_* driver loops the prepared pairs,
# builds figures (L2_plots.R) + xlsx, and returns a summary. compare_variants (used
# by Stationarity_Comparison.R) is the raw-vs-detrended delta helper.
# =============================================================================



# =============================================================================
# ANALYSIS COMPUTE FUNCTIONS (variant-agnostic; consume a prepared `prep` tibble)
# =============================================================================

# ----- Cross-spectral coherence and phase ------------------------------------
# Detrending (if any) already happened in prepare_pair(), so the L1 kernel
# coherence_phase_profile() is called on the prepared series; this L2 wrapper
# windows to the reported period band and attaches the pair labels.
coh_phase_pair <- function(prep,
                           spans      = c(15, 15),
                           period_min = 2,
                           period_max = 168) {
  if (is.null(prep)) return(NULL)
  coherence_phase_profile(prep$a, prep$b, spans = spans) %>%
    filter(period_hr >= period_min, period_hr <= period_max) %>%
    mutate(pair_label = prep$pair_label[1], n_overlap = prep$n_overlap[1], .before = 1)
}



ccf_pair <- function(prep, lag_max) {
  if (is.null(prep)) return(NULL)

  # L1 kernel returns the profile in R's native lag convention; R defines
  # ccf(a, b)[k] = cor(a[t+k], b[t]), so peak at k>0 means b leads a. We flip
  # here (the study sign convention stays in L2) so positive lag = a leads b.
  prof     <- ccf_lag_profile(prep$a, prep$b, lag_max)
  lag_vals <- -prof$lag
  cor_vals <- prof$correlation

  n_eff      <- prep$n_overlap[1]
  sig_thresh <- 1.96 / sqrt(n_eff)
  peak_lag_interp <- estimate_ccf_peak_lag(lag_vals, cor_vals)
  peak_idx <- which.max(abs(cor_vals))

  # Per-lag uncertainty for the CCF comes from the independence-assuming per-lag
  # pairs bootstrap (run_lag_bootstrap() -> Lag_Bootstrap_Summary_{raw,detrended}.xlsx;
  # see Lag_Bootstrap_Notes.md). The retired moving-block peak-lag CI (which did
  # not reliably contain the observed peak lag) lives in OLD_ANALYSIS_CODE.R.

  tibble(
    pair_label  = prep$pair_label[1],
    n_overlap   = n_eff,
    lag_hr      = lag_vals,
    correlation = cor_vals,
    sig_thresh  = sig_thresh
  ) %>%
    mutate(
      peak_lag_interp_hr = peak_lag_interp,
      peak_corr_abs = abs(cor_vals[peak_idx])
      # bootstrap_* / lag_ci_* columns removed with the moving-block bootstrap.
    ) %>%
    arrange(lag_hr)
}

# ----- Transfer entropy for one prepared pair --------------------------------
run_te_pair <- function(prep, cave_name, logger_a, logger_b, te) {
  if (is.null(prep)) return(NULL)

  # L1 kernel does the numeric TE; te_seed is the L2-owned RNG seed, passed in.
  r  <- te_net_directional(prep$a, prep$b, lx = te$lx, ly = te$ly,
                           quantiles = te$quantiles, shuffles = te$shuffles,
                           nboot = te$nboot, seed = te_seed)
  la <- short_logger(logger_a); lb <- short_logger(logger_b)

  tibble::tibble(
    Cave        = cave_name,
    Pair        = paste0(la, "-", lb),
    n_overlap   = prep$n_overlap[1],
    te_a_to_b   = r$te_a_to_b,
    ete_a_to_b  = r$ete_a_to_b,
    se_a_to_b   = r$se_a_to_b,
    p_a_to_b    = r$p_a_to_b,
    te_b_to_a   = r$te_b_to_a,
    ete_b_to_a  = r$ete_b_to_a,
    se_b_to_a   = r$se_b_to_a,
    p_b_to_a    = r$p_b_to_a,
    net_ete     = r$net_ete,
    dominant_direction = if (r$net_ete >= 0) paste0(la, " -> ", lb)
                         else                paste0(lb, " -> ", la)
  )
}


# =============================================================================
# HIGH-LEVEL DRIVERS
# Each consumes a set of PREPARED pairs (from prepare_pairs()) -- so it does the
# SAME work whether the data is raw or detrended -- writes figures + xlsx tagged
# with `tag`, and returns the summary tibble (used by Stationarity_Comparison.R).
# The raw/detrended choice is a data-shaping decision made in the L3 driver, not
# a flag interpreted here.
# =============================================================================

# --- Stationarity assessment (ADF + KPSS) ------------------------------------
# Verifies (rather than assumes) the stationarity the spectral coherence, CCF,
# per-lag bootstrap, and transfer-entropy analyses rest on. The two tests have
# OPPOSITE null hypotheses and are read together (four-case logic):
#   ADF  (tseries::adf.test)        H0: unit root (non-stationary)
#   KPSS (tseries::kpss.test,Level) H0: stationary around a constant mean
# See ANALYSIS_DOCS.md and the per-analysis *_Notes.md for interpretation + refs.

# Trim ONE logger's hourly series to its longest contiguous run and apply the
# variant's stationarizer (single-series mirror of prepare_pair()).
prep_one_series <- function(df, logger, stationarize, min_overlap) {
  s <- df %>%
    dplyr::filter(Logger_Name == logger) %>%
    dplyr::select(date_time, Temperature) %>%
    dplyr::arrange(date_time) %>%
    dplyr::filter(!is.na(Temperature))
  if (nrow(s) < min_overlap) return(NULL)
  # Longest contiguous 1-hour-spaced run (same L1 kernel/rule as prepare_pair).
  hr_gap <- as.numeric(diff(s$date_time), units = "hours")
  s <- s[longest_regular_run(hr_gap, spacing = 1, tol = 0.1), ]
  if (nrow(s) < min_overlap) return(NULL)
  x <- stationarize(s$Temperature)   # identity (raw) or harmonic-detrend closure
  x
}


# Per-logger ADF + KPSS for one variant; writes Stationarity_Tests_<variant>.xlsx.
run_stationarity_tests <- function(hourly, stationarize, tag, min_overlap) {
  loggers <- sort(unique(as.character(hourly$Logger_Name)))
  res <- purrr::map_dfr(loggers, function(lg) {
    x <- prep_one_series(hourly, lg, stationarize, min_overlap = min_overlap)
    if (is.null(x)) return(NULL)
    cave <- as.character(hourly$Cave[hourly$Logger_Name == lg][1])
    dplyr::bind_cols(
      tibble::tibble(Cave = cave, Logger = short_logger(lg),
                     variant = tag, n = length(x)),
      assess_stationarity(x))
  })
  if (nrow(res) == 0) return(invisible(NULL))
  res <- res %>%
    dplyr::mutate(dplyr::across(c(adf_stat, adf_p, kpss_stat, kpss_p),
                                ~ round(.x, 4))) %>%
    dplyr::arrange(Cave, Logger)
  cat(sprintf("\n=== Stationarity tests (ADF + KPSS), variant = %s ===\n\n", tag))
  print(res, n = Inf)
  wb <- openxlsx::createWorkbook()
  for (cv in unique(res$Cave)) {
    openxlsx::addWorksheet(wb, cv)
    openxlsx::writeData(wb, cv, res %>% dplyr::filter(Cave == cv))
  }
  openxlsx::saveWorkbook(wb, out_name("Stationarity_Tests", tag, "xlsx"),
                         overwrite = TRUE)
  cat(sprintf("Table saved: %s\n", out_name("Stationarity_Tests", tag, "xlsx")))
  invisible(res)
}

run_lag_bootstrap <- function(pairs, tag, lagboot, pair_levels) {
  set.seed(lagboot_seed)

  lagboot_results <- map_dfr(pairs, function(p) {
    prep <- p$prep
    if (is.null(prep)) return(NULL)
    lag_pairs_bootstrap(prep$a, prep$b,
                        lag_max = lagboot$lag_max,
                        reps = lagboot$reps,
                        conf = lagboot$conf) %>%
      mutate(
        Cave             = p$cave,
        pair_label       = prep$pair_label[1],
        n_overlap        = prep$n_overlap[1],
        sig_thresh       = 1.96 / sqrt(prep$n_overlap[1]),
        ci_excludes_zero = (ci_low > 0) | (ci_high < 0),
        reps             = lagboot$reps,
        conf             = lagboot$conf,
        seed             = lagboot_seed,
        .before          = 1
      )
  }) %>%
    mutate(pair_label = factor(pair_label,
                               levels = pair_levels))

  fig_c <- plot_lagboot(lagboot_results, "Croc-2", tag)
  fig_k <- plot_lagboot(lagboot_results, "KHC", tag)
  # Two-column facet tiling (see plot_lagboot): height scales with the number of
  # facet ROWS = ceil(n_pairs / 2), and width widens to hold the two columns.
  h_c <- facet_h(ceiling(n_distinct(filter(lagboot_results, Cave == "Croc-2")$pair_label) / 2))
  h_k <- facet_h(ceiling(n_distinct(filter(lagboot_results, Cave == "KHC")$pair_label) / 2))
  ggsave(out_name("Fig14_LagBootstrap_Croc2", tag, "png"), fig_c, width = 9.5, height = h_c, dpi = 300)
  ggsave(out_name("Fig14_LagBootstrap_Croc2", tag, "pdf"), fig_c, width = 9.5, height = h_c)
  ggsave(out_name("Fig15_LagBootstrap_KHC",   tag, "png"), fig_k, width = 9.5, height = h_k, dpi = 300)
  ggsave(out_name("Fig15_LagBootstrap_KHC",   tag, "pdf"), fig_k, width = 9.5, height = h_k)
  cat(sprintf("Figures 14/15 saved: Fig14/15_LagBootstrap_*_%s.png/pdf\n", tag))

  lagboot_table <- lagboot_results %>%
    transmute(
      Cave,
      Pair             = as.character(pair_label),
      lag_hr,
      corr_obs         = round(corr_obs, 4),
      ci_low           = round(ci_low, 4),
      ci_high          = round(ci_high, 4),
      boot_mean        = round(boot_mean, 4),
      boot_se          = round(boot_se, 4),
      n_pairs,
      ci_excludes_zero,
      sig_thresh       = round(sig_thresh, 4),
      reps, conf, seed
    ) %>%
    arrange(Cave, Pair, lag_hr)

  lagboot_wb <- createWorkbook()
  addWorksheet(lagboot_wb, "Croc-2")
  writeData(lagboot_wb, "Croc-2", lagboot_table %>% filter(Cave == "Croc-2"))
  addWorksheet(lagboot_wb, "KHC")
  writeData(lagboot_wb, "KHC",    lagboot_table %>% filter(Cave == "KHC"))
  saveWorkbook(lagboot_wb, out_name("Lag_Bootstrap_Summary", tag, "xlsx"), overwrite = TRUE)
  cat(sprintf("Table saved: %s (sheets: Croc-2, KHC)\n",
              out_name("Lag_Bootstrap_Summary", tag, "xlsx")))

  invisible(lagboot_table)
}

run_transfer_entropy <- function(pairs, tag, te, pair_levels) {
  te_summary <- map_dfr(pairs, function(p) {
    run_te_pair(p$prep, p$cave, p$a, p$b, te = te)
  }) %>%
    mutate(Pair = factor(Pair, levels = pair_levels)) %>%
    arrange(Cave, Pair)

  fig_c <- plot_te(te_summary, "Croc-2", tag)
  fig_k <- plot_te(te_summary, "KHC", tag)
  # Two-column facet tiling (see plot_te): height scales with facet ROWS.
  h_c <- facet_h(ceiling(n_distinct(filter(te_summary, Cave == "Croc-2")$Pair) / 2))
  h_k <- facet_h(ceiling(n_distinct(filter(te_summary, Cave == "KHC")$Pair) / 2))
  ggsave(out_name("Fig16_TransferEntropy_Croc2", tag, "png"), fig_c, width = 9.5, height = h_c, dpi = 300)
  ggsave(out_name("Fig16_TransferEntropy_Croc2", tag, "pdf"), fig_c, width = 9.5, height = h_c)
  ggsave(out_name("Fig17_TransferEntropy_KHC",   tag, "png"), fig_k, width = 9.5, height = h_k, dpi = 300)
  ggsave(out_name("Fig17_TransferEntropy_KHC",   tag, "pdf"), fig_k, width = 9.5, height = h_k)
  cat(sprintf("Figures 16/17 saved: Fig16/17_TransferEntropy_*_%s.png/pdf\n", tag))

  te_table <- te_summary %>%
    mutate(Pair = as.character(Pair)) %>%
    mutate(across(where(is.numeric), ~ round(.x, 5)))

  te_wb <- createWorkbook()
  addWorksheet(te_wb, "Croc-2")
  writeData(te_wb, "Croc-2", te_table %>% filter(Cave == "Croc-2"))
  addWorksheet(te_wb, "KHC")
  writeData(te_wb, "KHC",    te_table %>% filter(Cave == "KHC"))
  saveWorkbook(te_wb, out_name("Transfer_Entropy_Summary", tag, "xlsx"), overwrite = TRUE)
  cat(sprintf("Table saved: %s (sheets: Croc-2, KHC)\n",
              out_name("Transfer_Entropy_Summary", tag, "xlsx")))

  # Complete-pair matrix heatmap: directed net effective TE (diverging).
  save_pair_matrix_directional(te_summary, "TE_Matrix_DirETE", "ete_a_to_b", "ete_b_to_a", "ETE (bits)", tag,
                               pcol_ab = "p_a_to_b", pcol_ba = "p_b_to_a")

  invisible(te_table)
}

# =============================================================================
# LAG-INFORMED (DELAYED) TRANSFER ENTROPY — TE_SPO  (TEOptimal_*)
# =============================================================================
# Seeds the source->target interaction delay from the CCF peak, scans a causal
# window around it, and takes the delay maximising effective TE for each
# direction (Wibral et al. 2013). Called from Model_Analyses.R via
# run_te_optimal(). See Transfer_Entropy_Lag_Theory.md.
#
# The argmax-over-u is guarded by a circular-shift surrogate test (p_delay).
#
# Cost control: the delay scan AND the surrogate null use fast raw TE (calc_te,
# no shuffles); the bias-corrected effective TE (calc_ete) is computed once per
# direction, at the selected delay u*, as the reported effect size.

# teopt_seed stays L2 (an RNG seed, not a reported constant). The reported TE
# embedding (lx, ly, quantiles) arrives via `te=` and the delay-scan tuning
# (window, lag_max, nsurr, shuffles) via `teopt=`, both set in Model_Analyses.R.
teopt_seed <- 230945L

# The pure delay-scan kernels -- teopt_align_delay, teopt_te_at, teopt_ete_at,
# teopt_grid, teopt_direction -- now live in analysis_kernels.R (L1). What stays
# in L2 is teopt_ccf_peak, which applies the study CCF sign convention.

# CCF peak lag (interpolated); our sign convention: positive => x leads y.
teopt_ccf_peak <- function(x, y, lag_max) {
  prof <- ccf_lag_profile(x, y, lag_max)                 # L1 kernel (native lag)
  estimate_ccf_peak_lag(-prof$lag, prof$correlation)     # flip so positive => x leads y
}

# One pair: full-range optimal-delay scan + surrogate p-value each way; the CCF peak
# is computed and reported alongside as a linear reference (it no longer seeds or
# bounds the scan). Returns list(summary row, TE(u) profile rows).
run_te_optimal_pair <- function(prep, cave_name, logger_a, logger_b, te, teopt, min_overlap) {
  if (is.null(prep)) return(NULL)
  a <- prep$a; b <- prep$b
  u_ccf <- teopt_ccf_peak(a, b, teopt$lag_max)             # reported as a linear reference only; does NOT bound the scan
  ab <- teopt_direction(a, b, te, teopt, min_overlap, teopt_seed)   # A -> B, full [1,lag_max] scan
  ba <- teopt_direction(b, a, te, teopt, min_overlap, teopt_seed)   # B -> A, full [1,lag_max] scan
  if (is.null(ab) || is.null(ba)) return(NULL)
  la <- short_logger(logger_a); lb <- short_logger(logger_b)
  pair <- paste0(la, "-", lb)
  net  <- ab$ete_star - ba$ete_star
  summary <- tibble::tibble(
    Cave = cave_name, Pair = pair, n_overlap = prep$n_overlap[1], u_ccf_hr = u_ccf,
    ete_a_to_b = ab$ete_star, u_star_a_to_b_hr = ab$u_star, p_delay_a_to_b = ab$p_delay,
    edge_a_to_b = ab$u_edge,
    ete_b_to_a = ba$ete_star, u_star_b_to_a_hr = ba$u_star, p_delay_b_to_a = ba$p_delay,
    edge_b_to_a = ba$u_edge,
    net_ete = net,
    dominant_direction = if (net >= 0) paste0(la, " -> ", lb) else paste0(lb, " -> ", la)
  )
  profile <- dplyr::bind_rows(
    tibble::tibble(Cave = cave_name, Pair = pair, direction = paste0(la, "->", lb),
                   u_hr = ab$u_grid, te = ab$te, u_star = ab$u_star),
    tibble::tibble(Cave = cave_name, Pair = pair, direction = paste0(lb, "->", la),
                   u_hr = ba$u_grid, te = ba$te, u_star = ba$u_star)
  )
  list(summary = summary, profile = profile)
}


run_te_optimal <- function(pairs, tag, min_overlap, te, teopt, pair_levels) {
  future::plan(future::sequential)

  res <- map(pairs, function(p) {
    run_te_optimal_pair(p$prep, p$cave, p$a, p$b, te = te, teopt = teopt, min_overlap = min_overlap)
  })
  res <- res[!vapply(res, is.null, logical(1))]
  teo <- map_dfr(res, "summary") %>%
    mutate(Pair = factor(Pair, levels = pair_levels)) %>%
    arrange(Cave, Pair)
  profiles <- map_dfr(res, "profile")

  cat(sprintf("\n=== TE-OPTIMAL (delayed TE / TE_SPO), variant = %s ===\n\n", tag))
  print(teo %>% transmute(Cave, Pair, u_ccf = round(u_ccf_hr, 2),
          ETE_AtoB = round(ete_a_to_b, 4), u_AtoB = u_star_a_to_b_hr, p_AtoB = round(p_delay_a_to_b, 3), e_AB = edge_a_to_b,
          ETE_BtoA = round(ete_b_to_a, 4), u_BtoA = u_star_b_to_a_hr, p_BtoA = round(p_delay_b_to_a, 3), e_BA = edge_b_to_a,
          net = round(net_ete, 4), dominant_direction), n = Inf)

  # Edge-pinned check (u* on a grid boundary): report which edge-pinned directions
  # are surrogate-significant. On the full [1,lag_max] scan, u*=1 is the minimal
  # causal delay (expected for tight coupling); u*=lag_max means the optimum may lie
  # beyond the searched range. Either way, an edge-pinned direction is only trusted
  # where p_delay < 0.05.
  edge_rows <- dplyr::bind_rows(
    teo %>% transmute(Cave, Pair, dir = "A->B", u = u_star_a_to_b_hr, p = p_delay_a_to_b, edge = edge_a_to_b),
    teo %>% transmute(Cave, Pair, dir = "B->A", u = u_star_b_to_a_hr, p = p_delay_b_to_a, edge = edge_b_to_a)
  ) %>% filter(edge)
  cat(sprintf("\nEdge-pinned directions (u* on grid boundary): %d; significant (p<0.05): %d\n",
              nrow(edge_rows), sum(edge_rows$p < 0.05, na.rm = TRUE)))
  if (nrow(edge_rows) > 0) print(edge_rows %>% mutate(p = round(p, 3), sig = p < 0.05) %>% as.data.frame(), row.names = FALSE)

  fig_c <- plot_te_optimal(profiles, "Croc-2", tag, pair_levels)
  fig_k <- plot_te_optimal(profiles, "KHC", tag, pair_levels)
  # Two-column facet tiling (see plot_te_optimal): height scales with facet ROWS
  # = ceil(n_pairs / 2), width widens to hold the two columns.
  h_c <- facet_h(ceiling(n_distinct(filter(teo, Cave == "Croc-2")$Pair) / 2))
  h_k <- facet_h(ceiling(n_distinct(filter(teo, Cave == "KHC")$Pair) / 2))
  ggsave(out_name("Fig19_TEOptimal_Croc2", tag, "png"), fig_c, width = 9.5, height = h_c, dpi = 300)
  ggsave(out_name("Fig19_TEOptimal_Croc2", tag, "pdf"), fig_c, width = 9.5, height = h_c)
  ggsave(out_name("Fig20_TEOptimal_KHC",   tag, "png"), fig_k, width = 9.5, height = h_k, dpi = 300)
  ggsave(out_name("Fig20_TEOptimal_KHC",   tag, "pdf"), fig_k, width = 9.5, height = h_k)
  cat(sprintf("Figures 19/20 saved: Fig19/20_TEOptimal_*_%s.png/pdf\n", tag))

  teo_table <- teo %>%
    mutate(Pair = as.character(Pair)) %>%
    mutate(across(where(is.numeric), ~ round(.x, 5)))
  wb <- createWorkbook()
  for (cv in c("Croc-2", "KHC")) {
    addWorksheet(wb, cv)
    writeData(wb, cv, teo_table %>% filter(Cave == cv))
  }
  saveWorkbook(wb, out_name("TEOptimal_Summary", tag, "xlsx"), overwrite = TRUE)
  cat(sprintf("Table saved: %s (sheets: Croc-2, KHC)\n",
              out_name("TEOptimal_Summary", tag, "xlsx")))

  # Complete-pair matrix heatmap: directed net effective TE at u* (diverging).
  save_pair_matrix_directional(teo, "TEOptimal_Matrix_DirETE", "ete_a_to_b", "ete_b_to_a", "ETE @ u* (bits)", tag,
                               pcol_ab = "p_delay_a_to_b", pcol_ba = "p_delay_b_to_a")

  invisible(teo_table)
}

run_coherence_phase <- function(pairs, tag, pair_levels) {
  coh_phase_results <- map_dfr(pairs, function(p) {
    res  <- coh_phase_pair(p$prep)
    if (is.null(res)) return(NULL)
    res %>% mutate(Cave = p$cave, .before = 1)
  }) %>%
    mutate(pair_label = factor(pair_label,
                               levels = pair_levels))

  # Coherency and delay are tiled as separate 2-column grids (10 pairs -> 5x2)
  # so each fits one page; height scales with facet ROWS = ceil(n_pairs / 2).
  h_c <- facet_h(ceiling(n_distinct(filter(coh_phase_results, Cave == "Croc-2")$pair_label) / 2))
  h_k <- facet_h(ceiling(n_distinct(filter(coh_phase_results, Cave == "KHC")$pair_label) / 2))
  for (met in c("coherency", "delay")) {
    lab <- if (met == "coherency") "Coherency" else "Delay"
    gc <- plot_coh_metric(coh_phase_results, "Croc-2", met)
    gk <- plot_coh_metric(coh_phase_results, "KHC",    met)
    ggsave(out_name(paste0("Fig10_Coherence_", lab, "_Croc2"), tag, "png"), gc, width = 9.5, height = h_c, dpi = 300)
    ggsave(out_name(paste0("Fig10_Coherence_", lab, "_Croc2"), tag, "pdf"), gc, width = 9.5, height = h_c)
    ggsave(out_name(paste0("Fig11_Coherence_", lab, "_KHC"),   tag, "png"), gk, width = 9.5, height = h_k, dpi = 300)
    ggsave(out_name(paste0("Fig11_Coherence_", lab, "_KHC"),   tag, "pdf"), gk, width = 9.5, height = h_k)
  }
  cat(sprintf("Coherence grids saved: Fig10/11_Coherence_{Coherency,Delay}_*_%s.png/pdf\n", tag))

  coh_phase_summary <- coh_phase_results %>%
    group_by(Cave, pair_label, n_overlap, sig_thresh) %>%
    slice_max(coherency_sq, n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    transmute(
      Cave,
      Pair                = as.character(pair_label),
      n_hours_overlap     = n_overlap,
      peak_period_hr      = round(period_hr, 2),
      peak_coherency_sq   = round(coherency_sq, 3),
      phase_at_peak_rad   = round(phase_rad, 3),
      delay_at_peak_hr    = round(delay_hr, 2),
      sig_threshold       = round(sig_thresh, 3),
      peak_is_significant = coherency_sq > sig_thresh
    ) %>%
    arrange(Cave, Pair)

  coh_phase_wb <- createWorkbook()
  addWorksheet(coh_phase_wb, "Croc-2")
  writeData(coh_phase_wb, "Croc-2", coh_phase_summary %>% filter(Cave == "Croc-2"))
  addWorksheet(coh_phase_wb, "KHC")
  writeData(coh_phase_wb, "KHC",    coh_phase_summary %>% filter(Cave == "KHC"))
  saveWorkbook(coh_phase_wb, out_name("Coherence_Phase_Summary", tag, "xlsx"), overwrite = TRUE)
  cat(sprintf("Table saved: %s (sheets: Croc-2, KHC)\n",
              out_name("Coherence_Phase_Summary", tag, "xlsx")))

  # Complete-pair matrix heatmaps: directed delay (diverging) + peak coherency (magnitude).
  save_pair_matrix(coh_phase_summary, "Coherence_Matrix_Delay",     "delay_at_peak_hr",  "Delay (h)",   TRUE,  tag)
  save_pair_matrix(coh_phase_summary, "Coherence_Matrix_Coherency", "peak_coherency_sq", "Coherency^2", FALSE, tag)

  invisible(coh_phase_summary)
}

run_ccf <- function(pairs, tag, ccf_lag_max, pair_levels) {
  ccf_results <- map_dfr(pairs, function(p) {
    res  <- ccf_pair(p$prep, ccf_lag_max)
    if (is.null(res)) return(NULL)
    res %>% mutate(Cave = p$cave, .before = 1)
  }) %>%
    mutate(pair_label = factor(pair_label,
                               levels = pair_levels))

  fig_c <- plot_ccf(ccf_results, "Croc-2", tag)
  fig_k <- plot_ccf(ccf_results, "KHC", tag)
  h_c <- facet_h(n_distinct(filter(ccf_results, Cave == "Croc-2")$pair_label))
  h_k <- facet_h(n_distinct(filter(ccf_results, Cave == "KHC")$pair_label))
  ggsave(out_name("Fig12_CCF_Croc2", tag, "png"), fig_c, width = 7, height = h_c, dpi = 300)
  ggsave(out_name("Fig12_CCF_Croc2", tag, "pdf"), fig_c, width = 7, height = h_c)
  ggsave(out_name("Fig13_CCF_KHC",   tag, "png"), fig_k, width = 7, height = h_k, dpi = 300)
  ggsave(out_name("Fig13_CCF_KHC",   tag, "pdf"), fig_k, width = 7, height = h_k)
  cat(sprintf("Figures 12/13 saved: Fig12/13_CCF_*_%s.png/pdf\n", tag))

  zero_lag_corr <- ccf_results %>%
    filter(lag_hr == 0) %>%
    select(Cave, pair_label, zero_lag_correlation = correlation)

  ccf_summary <- ccf_results %>%
    group_by(Cave, pair_label, n_overlap, sig_thresh,
             peak_lag_interp_hr, peak_corr_abs) %>%
    slice_max(abs(correlation), n = 1, with_ties = FALSE) %>%
    ungroup() %>%
    left_join(zero_lag_corr, by = c("Cave", "pair_label")) %>%
    transmute(
      Cave,
      Pair                 = as.character(pair_label),
      n_hours_overlap      = n_overlap,
      peak_lag_hr          = round(peak_lag_interp_hr, 2),
      peak_correlation     = round(correlation, 3),
      zero_lag_correlation = round(zero_lag_correlation, 3),
      # Moving-block bootstrap CI columns removed (disabled per review).
      # Per-lag peak/lag uncertainty is in Lag_Bootstrap_Summary_{raw,detrended}.xlsx
      # (independence-assuming per-lag pairs bootstrap; see Lag_Bootstrap_Notes.md).
      sig_threshold        = round(sig_thresh, 3),
      peak_is_significant  = abs(correlation) > sig_thresh
    ) %>%
    arrange(Cave, Pair)

  ccf_wb <- createWorkbook()
  addWorksheet(ccf_wb, "Croc-2")
  writeData(ccf_wb, "Croc-2", ccf_summary %>% filter(Cave == "Croc-2"))
  addWorksheet(ccf_wb, "KHC")
  writeData(ccf_wb, "KHC",    ccf_summary %>% filter(Cave == "KHC"))
  saveWorkbook(ccf_wb, out_name("CCF_Summary", tag, "xlsx"), overwrite = TRUE)
  cat(sprintf("Table saved: %s (sheets: Croc-2, KHC)\n",
              out_name("CCF_Summary", tag, "xlsx")))

  # Complete-pair matrix heatmaps: directed peak lag (diverging) + peak |r| (magnitude).
  save_pair_matrix(ccf_summary, "CCF_Matrix_PeakLag",  "peak_lag_hr",      "Peak lag (h)", TRUE,  tag)
  save_pair_matrix(ccf_summary, "CCF_Matrix_PeakCorr", "peak_correlation", "Peak |r|",     FALSE, tag)

  invisible(ccf_summary)
}

# -----------------------------------------------------------------------------
# Dynamic Time Warping (DTW) — daily-median alignment per adjacent pair.
# DTW is a shape-similarity/alignment measure. It operates on DAILY-MEDIAN series
# (not hourly) and needs no stationarization, so unlike the spectral/lag methods
# it is variant-agnostic (one run, no raw/detrended split). Each pair is aligned
# within a +/- window_days Sakoe--Chiba band with an absolute-difference (L1)
# local cost; we report the normalized alignment distance (cost per path step) and
# the warp-path lag in days.
# -----------------------------------------------------------------------------
prep_dtw_pair <- function(df, logger_a, logger_b) {
  pair_daily <- df %>%
    dplyr::filter(Logger_Name %in% c(logger_a, logger_b)) %>%
    dplyr::select(date_only, Logger_Name, temp_median) %>%
    tidyr::pivot_wider(names_from = Logger_Name, values_from = temp_median) %>%
    dplyr::arrange(date_only) %>%
    dplyr::filter(complete.cases(.))

  if (nrow(pair_daily) < 14) return(NULL)

  # Longest contiguous 1-day-spaced run (exact daily spacing; L1 kernel).
  day_gap    <- as.numeric(diff(pair_daily$date_only), units = "days")
  pair_daily <- pair_daily[longest_regular_run(day_gap, spacing = 1, tol = 0), ]
  if (nrow(pair_daily) < 14) return(NULL)

  pair_daily
}


run_dtw_pair <- function(df, cave_name, logger_a, logger_b, window_size) {
  pair_daily <- prep_dtw_pair(df, logger_a, logger_b)
  if (is.null(pair_daily)) return(NULL)

  alignment <- dtw_align(pair_daily[[logger_a]], pair_daily[[logger_b]], window_size)
  if (is.null(alignment)) return(NULL)

  n_days <- nrow(pair_daily)
  path_length <- alignment$path_length[1]
  dtw_distance <- alignment$dtw_distance[1]

  summary <- tibble::tibble(
    Cave = cave_name,
    Pair = paste0(short_logger(logger_a), "-", short_logger(logger_b)),
    Logger_A = logger_a,
    Logger_B = logger_b,
    start_date = min(pair_daily$date_only),
    end_date = max(pair_daily$date_only),
    n_days_overlap = n_days,
    window_days = window_size,
    dtw_distance = round(dtw_distance, 3),
    normalized_distance = round(dtw_distance / path_length, 4),
    path_length = path_length,
    mean_lag_days = round(mean(alignment$lag_days), 3),
    median_lag_days = round(stats::median(alignment$lag_days), 3),
    min_lag_days = min(alignment$lag_days),
    max_lag_days = max(alignment$lag_days),
    mean_abs_lag_days = round(mean(abs(alignment$lag_days)), 3)
  )

  path_table <- alignment %>%
    dplyr::mutate(
      Cave = cave_name,
      Pair = paste0(short_logger(logger_a), "-", short_logger(logger_b)),
      date_a = pair_daily$date_only[idx_a],
      date_b = pair_daily$date_only[idx_b],
      temp_a = pair_daily[[logger_a]][idx_a],
      temp_b = pair_daily[[logger_b]][idx_b],
      .before = 1
    )

  list(summary = summary, path = path_table)
}

run_dtw <- function(hourly, dtw_pairs, window_days) {
  cat("\n=== DYNAMIC TIME WARPING (daily-median alignment per adjacent pair) ===\n\n")
  daily_med <- hourly %>%
    dplyr::group_by(date_only, Cave, Logger_Name) %>%
    dplyr::summarise(temp_median = stats::median(Temperature, na.rm = TRUE),
                     .groups = "drop")

  dtw_results <- purrr::map(dtw_pairs, function(p) {
    run_dtw_pair(daily_med, p$cave, p$a, p$b, window_days)
  })
  dtw_summary <- purrr::map_dfr(dtw_results, "summary") %>% dplyr::arrange(Cave, Pair)
  dtw_paths   <- purrr::map_dfr(dtw_results, "path")

  print(dtw_summary, n = Inf)

  dtw_wb <- createWorkbook()
  for (cave_name in unique(dtw_summary$Cave)) {
    addWorksheet(dtw_wb, paste0(cave_name, "_Summary"))
    writeData(dtw_wb, paste0(cave_name, "_Summary"),
              dtw_summary %>% dplyr::filter(Cave == cave_name))
    addWorksheet(dtw_wb, paste0(cave_name, "_Paths"))
    writeData(dtw_wb, paste0(cave_name, "_Paths"),
              dtw_paths %>% dplyr::filter(Cave == cave_name))
  }
  saveWorkbook(dtw_wb, "DTW_Analysis.xlsx", overwrite = TRUE)
  cat("\nDTW saved: DTW_Analysis.xlsx (Summary / Paths per cave). See DTW_Notes.md.\n")
  invisible(dtw_summary)
}

# =============================================================================
# COMPARISON HELPER (used by Stationarity_Comparison.R)
# Joins a raw summary and a detrended summary on `keys`, renaming each value
# column to <col>_raw / <col>_detrended and adding <col>_delta = detrended - raw.
# =============================================================================
compare_variants <- function(raw_tbl, det_tbl, value_cols, keys = c("Cave", "Pair")) {
  raw_sel <- raw_tbl %>%
    select(all_of(c(keys, value_cols))) %>%
    rename_with(~ paste0(.x, "_raw"), all_of(value_cols))
  det_sel <- det_tbl %>%
    select(all_of(c(keys, value_cols))) %>%
    rename_with(~ paste0(.x, "_detrended"), all_of(value_cols))

  out <- raw_sel %>% left_join(det_sel, by = keys)
  for (col in value_cols) {
    out[[paste0(col, "_delta")]] <- out[[paste0(col, "_detrended")]] -
                                    out[[paste0(col, "_raw")]]
  }
  out %>% arrange(across(all_of(keys)))
}
