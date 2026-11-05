# =============================================================================
# L2_plots.R -- ggplot builders + directed-matrix heatmaps
# =============================================================================
# Sourced by analysis_processes.R. Figure construction only; called by the
# run_* drivers in L2_drivers.R. Uses the L1 layout utils (facet_h, out_name).
# =============================================================================



# Directed pair-by-pair matrix heatmap of ONE scalar per ordered pair -- the
# headline view of the complete pair set (flow topology at a glance). `summary` has
# Cave, Pair ("L1-L2"), and `value_col`. For a SIGNED value (positive = first logger
# leads), cell (from=a, to=b) = value and (b,a) = -value (antisymmetric) -> DIVERGING
# scale, grey at 0. For a MAGNITUDE value the relation is undirected, so both cells =
# |value| -> SEQUENTIAL scale. The diagonal stays blank. Palette = Okabe-Ito
# (colour-blind safe): blue<->orange diverging, blue sequential.
plot_pair_matrix <- function(summary, cave_name, value_col, fill_lab, signed = TRUE) {
  d <- summary %>%
    filter(Cave == cave_name) %>%
    transmute(a = sub("-.*", "", as.character(Pair)),
              b = sub(".*-", "", as.character(Pair)),
              val = .data[[value_col]])
  if (nrow(d) == 0) return(NULL)

  cells <- if (signed) {
    bind_rows(transmute(d, from = a, to = b, val),
              transmute(d, from = b, to = a, val = -val))
  } else {
    bind_rows(transmute(d, from = a, to = b, val = abs(val)),
              transmute(d, from = b, to = a, val = abs(val)))
  }
  lv <- sort(unique(c(cells$from, cells$to)))
  cells <- cells %>% mutate(from = factor(from, levels = rev(lv)),
                            to   = factor(to,   levels = lv))

  p <- ggplot(cells, aes(x = to, y = from, fill = val)) +
    geom_tile(color = "white", linewidth = 1.2) +
    geom_text(aes(label = sprintf("%.2f", val)), size = 3, color = "gray10") +
    coord_equal() +
    labs(x = "to (target)", y = "from (source / leader)", fill = fill_lab) +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(), axis.ticks = element_blank())

  if (signed) {
    p + scale_fill_gradient2(low = "#56B4E9", mid = "grey92", high = "#E69F00", midpoint = 0)
  } else {
    p + scale_fill_gradient(low = "grey92", high = "#0072B2")
  }
}

# Save a pair-matrix heatmap for both caves (png + pdf), skipping empty caves.
save_pair_matrix <- function(summary, base, value_col, fill_lab, signed, variant) {
  for (cv in c("Croc-2", "KHC")) {
    g <- plot_pair_matrix(summary, cv, value_col, fill_lab, signed)
    if (is.null(g)) next
    tag <- if (cv == "Croc-2") "Croc2" else "KHC"
    ggsave(out_name(paste0(base, "_", tag), variant, "png"), g, width = 6, height = 5.2, dpi = 300)
    ggsave(out_name(paste0(base, "_", tag), variant, "pdf"), g, width = 6, height = 5.2)
  }
  cat(sprintf("Matrix figures saved: %s_{Croc2,KHC}_%s.png/pdf\n", base, variant))
}

# Directional matrix: each cell is the directed value FROM the row logger TO the
# column logger, taken from the two per-direction columns (col_ab for a->b,
# col_ba for b->a). Unlike plot_pair_matrix(signed = TRUE), this is NOT
# antisymmetric -- e.g. ETE(A->B) and ETE(B->A) are independent quantities, so the
# two triangles differ in magnitude, not merely in sign. Diagonal left blank.
# If per-direction p-value columns (pcol_ab/pcol_ba) are given, cells that fail
# the p < sig_level test are GREYED OUT (neutral fill, muted label) so only the
# statistically supported directed transfers carry the colour scale.
plot_pair_matrix_directional <- function(summary, cave_name, col_ab, col_ba, fill_lab,
                                         pcol_ab = NULL, pcol_ba = NULL, sig_level = 0.05) {
  d <- summary %>%
    filter(Cave == cave_name) %>%
    transmute(a = sub("-.*", "", as.character(Pair)),
              b = sub(".*-", "", as.character(Pair)),
              ab = .data[[col_ab]], ba = .data[[col_ba]],
              pab = if (!is.null(pcol_ab)) .data[[pcol_ab]] else NA_real_,
              pba = if (!is.null(pcol_ba)) .data[[pcol_ba]] else NA_real_)
  if (nrow(d) == 0) return(NULL)

  cells <- bind_rows(transmute(d, from = a, to = b, val = ab, p = pab),
                     transmute(d, from = b, to = a, val = ba, p = pba))
  lv <- sort(unique(c(cells$from, cells$to)))
  cells <- cells %>% mutate(
    from = factor(from, levels = rev(lv)),
    to   = factor(to,   levels = lv),
    sig  = is.na(p) | p < sig_level,          # no p supplied -> treat as significant
    fill_val = ifelse(sig, val, NA_real_))    # non-significant -> NA -> na.value grey

  ggplot(cells, aes(x = to, y = from)) +
    geom_tile(aes(fill = fill_val), color = "white", linewidth = 1.2) +
    geom_text(aes(label = sprintf("%.3f", val), colour = sig), size = 3) +
    coord_equal() +
    labs(x = "to (target)", y = "from (source / leader)", fill = fill_lab) +
    scale_fill_gradient(low = "#D6E6F4", high = "#0072B2", na.value = "grey85") +
    scale_colour_manual(values = c(`TRUE` = "gray10", `FALSE` = "gray55"), guide = "none") +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(), axis.ticks = element_blank())
}

save_pair_matrix_directional <- function(summary, base, col_ab, col_ba, fill_lab, variant,
                                         pcol_ab = NULL, pcol_ba = NULL, sig_level = 0.05) {
  for (cv in c("Croc-2", "KHC")) {
    g <- plot_pair_matrix_directional(summary, cv, col_ab, col_ba, fill_lab,
                                      pcol_ab, pcol_ba, sig_level)
    if (is.null(g)) next
    tag <- if (cv == "Croc-2") "Croc2" else "KHC"
    ggsave(out_name(paste0(base, "_", tag), variant, "png"), g, width = 6, height = 5.2, dpi = 300)
    ggsave(out_name(paste0(base, "_", tag), variant, "pdf"), g, width = 6, height = 5.2)
  }
  cat(sprintf("Directional matrix saved: %s_{Croc2,KHC}_%s.png/pdf\n", base, variant))
}

plot_lagboot <- function(results, cave_name, variant) {
  d <- results %>% filter(Cave == cave_name)

  ggplot(d, aes(x = lag_hr, y = corr_obs)) +
    geom_vline(xintercept = 0, color = "gray20", linewidth = 0.7) +
    geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
    geom_ribbon(aes(ymin = ci_low, ymax = ci_high),
                fill = "steelblue", alpha = 0.25) +
    geom_line(color = "steelblue4", linewidth = 0.4) +
    geom_point(color = "gray15", size = 1.4) +
    facet_wrap(~ pair_label, ncol = 2, scales = "free_y") +
    scale_x_continuous(breaks = seq(-24, 24, 6)) +
    labs(
      x        = "Lag (hours)",
      y        = "Correlation"
    ) +
    theme_minimal() +
    theme(
      plot.title       = element_text(face = "bold"),
      plot.subtitle    = element_text(size = 8, color = "gray40"),
      strip.text       = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}

plot_te <- function(summary, cave_name, variant) {
  d <- summary %>%
    filter(Cave == cave_name) %>%
    transmute(pair_label = Pair,
              `A -> B` = ete_a_to_b, p_ab = p_a_to_b,
              `B -> A` = ete_b_to_a, p_ba = p_b_to_a)

  d_long <- d %>%
    pivot_longer(c(`A -> B`, `B -> A`),
                 names_to = "direction", values_to = "ete") %>%
    mutate(pval = ifelse(direction == "A -> B", p_ab, p_ba),
           sig  = ifelse(pval < 0.05, "*", ""))

  ggplot(d_long, aes(x = direction, y = ete, fill = direction)) +
    geom_col(width = 0.6) +
    geom_text(aes(label = sig), vjust = -0.2, size = 5) +
    facet_wrap(~ pair_label, ncol = 2, scales = "free_y") +
    scale_fill_manual(values = c("A -> B" = "#0072B2", "B -> A" = "#D55E00")) +
    labs(
      x        = NULL,
      y        = "Effective transfer entropy (bits)"
    ) +
    theme_minimal() +
    theme(
      plot.title       = element_text(face = "bold"),
      plot.subtitle    = element_text(size = 8, color = "gray40"),
      strip.text       = element_text(face = "bold"),
      legend.position  = "none",
      panel.grid.minor = element_blank()
    )
}

plot_coh_phase <- function(results, cave_name, variant) {
  d <- results %>% filter(Cave == cave_name)

  coh_color = "darkgreen"
  if (cave_name == "Croc-2"){coh_color = "#E69F00"}
  if (cave_name == "KHC"){coh_color = "#56B4E9"}
  coh_d <- d %>% select(pair_label, period_hr, value = coherency_sq)
  del_d <- d %>% select(pair_label, period_hr, value = delay_hr)
  sig_d <- d %>% distinct(pair_label, sig_thresh)

  x_scale <- scale_x_continuous(trans  = "log10",
                                breaks = c(2, 6, 12, 24, 48, 72, 168),
                                labels = c(2, 6, 12, 24, 48, 72, 168))
  base_theme <- theme_minimal() +
    theme(plot.title       = element_text(size = 10, face = "bold"),
          strip.text       = element_text(face = "bold"),
          panel.grid.minor = element_blank())

  # Squared coherency: fixed y-range [-1, 1], independent of the delay panel
  # (a facet_grid row otherwise forces the coherency column to share the delay
  # column's much wider y-range, flattening the [0,1] coherency curve).
  p_coh <- ggplot(coh_d, aes(period_hr, value)) +
    geom_hline(data = sig_d, aes(yintercept = sig_thresh),
               linetype = "dashed", color = "gray20", linewidth = 0.5) +
    geom_line(linewidth = 0.4, color = coh_color) +
    facet_grid(pair_label ~ .) +
    coord_cartesian(ylim = c(-1, 1)) +
    x_scale +
    labs(title = "Squared coherency", x = "Period (hours, log scale)", y = NULL) +
    base_theme +
    theme(strip.text.y = element_blank())

  # Delay: its own free y-range per pair row (unchanged)
  p_del <- ggplot(del_d, aes(period_hr, value)) +
    geom_hline(yintercept = 0, linetype = "dashed",
               color = "gray20", linewidth = 0.5) +
    geom_line(linewidth = 0.4, color = coh_color) +
    facet_grid(pair_label ~ ., scales = "free_y") +
    x_scale +
    labs(title = "Delay (hours)", x = "Period (hours, log scale)", y = NULL) +
    base_theme

  (p_coh | p_del)
}

# One coherence metric (coherency^2 OR delay) as a 2-column facet grid over pairs,
# so 10 pairs tile onto one page (see plot_coh_phase for the combined dual-panel).
plot_coh_metric <- function(results, cave_name, metric = c("coherency", "delay")) {
  metric <- match.arg(metric)
  d <- results %>% filter(Cave == cave_name)
  coh_color <- if (cave_name == "Croc-2") "#E69F00" else if (cave_name == "KHC") "#56B4E9" else "darkgreen"
  x_scale <- scale_x_continuous(trans  = "log10",
                                breaks = c(2, 6, 12, 24, 48, 72, 168),
                                labels = c(2, 6, 12, 24, 48, 72, 168))
  base_theme <- theme_minimal() +
    theme(plot.title = element_text(size = 11, face = "bold"),
          strip.text = element_text(face = "bold"),
          panel.grid.minor = element_blank())
  if (metric == "coherency") {
    sig_d <- d %>% distinct(pair_label, sig_thresh)
    ggplot(d, aes(period_hr, coherency_sq)) +
      geom_hline(data = sig_d, aes(yintercept = sig_thresh),
                 linetype = "dashed", color = "gray20", linewidth = 0.5) +
      geom_line(linewidth = 0.4, color = coh_color) +
      facet_wrap(~ pair_label, ncol = 2) +
      coord_cartesian(ylim = c(0, 1)) +
      x_scale +
      labs(title = "Squared coherency", x = "Period (hours, log scale)",
           y = expression(kappa^2)) +
      base_theme
  } else {
    ggplot(d, aes(period_hr, delay_hr)) +
      geom_hline(yintercept = 0, linetype = "dashed", color = "gray20", linewidth = 0.5) +
      geom_line(linewidth = 0.4, color = coh_color) +
      facet_wrap(~ pair_label, ncol = 2, scales = "free_y") +
      x_scale +
      labs(title = "Phase-derived delay", x = "Period (hours, log scale)",
           y = "Delay (h)") +
      base_theme
  }
}

plot_ccf <- function(results, cave_name, variant) {
  d <- results %>% filter(Cave == cave_name)

  ggplot(d, aes(x = lag_hr, y = correlation)) +
    geom_vline(xintercept = 0, color = "gray20", linewidth = 0.7) +
    geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
    geom_segment(aes(xend = lag_hr, yend = 0),
                 color = "gray30", linewidth = 0.5) +
    geom_point(color = "gray15", size = 1.8) +
    facet_grid(pair_label ~ ., scales = "free_y") +
    scale_x_continuous(breaks = seq(-24, 24, 6)) +
    labs(
      x        = "Lag (hours)",
      y        = "Correlation"
    ) +
    theme_minimal() +
    theme(
      plot.title       = element_text(face = "bold"),
      plot.subtitle    = element_text(size = 9, color = "gray40"),
      strip.text       = element_text(face = "bold"),
      panel.grid.minor = element_blank()
    )
}


# Per-cave TE(u) profile figure: TE vs source delay u, both directions, u* marked.
plot_te_optimal <- function(profiles, cave_name, variant, pair_levels) {
  d <- profiles %>%
    filter(Cave == cave_name) %>%
    mutate(Pair = factor(Pair, levels = pair_levels))
  stars <- d %>% filter(u_hr == u_star)
  ggplot(d, aes(u_hr, te, colour = direction)) +
    geom_vline(xintercept = 0, linetype = "dashed", color = "gray20", linewidth = 0.5) +
    geom_line(linewidth = 0.5) +
    geom_point(data = stars, size = 2.4) +
    facet_wrap(~ Pair, ncol = 2, scales = "free_y") +
    scale_x_continuous(breaks = seq(0, 24, 3), limits = c(0, NA)) +
    labs(
      x = "Source delay u (hours)", y = "Transfer entropy (bits)", colour = "Direction"
    ) +
    theme_minimal() +
    theme(plot.title = element_text(face = "bold"),
          plot.subtitle = element_text(size = 8, color = "gray40"),
          strip.text = element_text(face = "bold"),
          panel.grid.minor = element_blank())
}
