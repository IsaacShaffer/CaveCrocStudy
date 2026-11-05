# =============================================================================
# SI_FigS11_variant_comparison.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS11_variant_comparison.png and .pdf
# What   : Supplement Fig. S11. Raw vs detrended CCF peak lag, coherence delay, net ETE and delay-optimized net ETE per pair; non-significant net-ETE bars greyed.
# Inputs : A07, A08, A10, A11 (raw and detrended)
# Run from pub_code/:  Rscript figures/SI_FigS11_variant_comparison.R
# =============================================================================
# Shows which directional results depend on detrending: a bar that flips
# sign between raw and detrended reverses the inferred direction for that
# pair. TE bars whose leading direction is not significant are greyed.
# =============================================================================
source("lib/pub_setup.R")

VARIANTS <- c("raw", "detrended")

analysis_lvl <- c("CCF peak lag (h)", "Coherence delay (h)", "Net ETE (bits)", "Net ETE @ u* (bits)")

# One statistic from one analysis table, both variants. For the TE tables a bar
# is flagged non-significant when the direction giving the net its sign has
# p >= 0.05 (bootstrap p for TE, surrogate p_delay for TE-optimal).
variant_rows <- function(stem, value_col, analysis, pcol_ab = NULL, pcol_ba = NULL) {
  purrr::map_dfr(VARIANTS, function(v) {
    t <- read_analysis(paste0(stem, "_", v))
    sig <- if (is.null(pcol_ab)) rep(TRUE, nrow(t)) else
      ifelse(t[[value_col]] >= 0, t[[pcol_ab]], t[[pcol_ba]]) < 0.05
    tibble(Cave = t$Cave, Pair = t$Pair, analysis = analysis, variant = v,
           value = t[[value_col]], sig = sig)
  })
}

fig_df <- bind_rows(
  variant_rows("A07_ccf_summary",       "peak_lag_hr",      "CCF peak lag (h)"),
  variant_rows("A08_coherence_summary", "delay_at_peak_hr", "Coherence delay (h)"),
  variant_rows("A10_te_summary",        "net_ete",          "Net ETE (bits)",      "p_a_to_b",       "p_b_to_a"),
  variant_rows("A11_teopt_summary",     "net_ete",          "Net ETE @ u* (bits)", "p_delay_a_to_b", "p_delay_b_to_a")
) %>%
  mutate(variant  = factor(variant, levels = VARIANTS),
         analysis = factor(analysis, levels = analysis_lvl),
         Pair     = factor(Pair, levels = PAIR_LEVELS),
         fill_cat = ifelse(sig, as.character(variant), "ns"))

g <- ggplot(fig_df, aes(x = Pair, y = value, fill = fill_cat, group = variant)) +
  geom_hline(yintercept = 0, color = "gray30", linewidth = 0.4) +
  geom_col(position = position_dodge(width = 0.7), width = 0.6) +
  facet_grid(analysis ~ Cave, scales = "free_y") +
  scale_fill_manual(values = c("raw" = "#999999", "detrended" = "#0072B2", "ns" = "#D9D9D9"),
                    breaks = c("raw", "detrended", "ns"),
                    labels = c("raw", "detrended", "not significant (p ≥ 0.05)"),
                    name = "Variant") +
  labs(x = "Within-cave logger pair", y = "Statistic value (sign = direction)") +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold"),
        axis.text.x = element_text(angle = 45, hjust = 1),
        legend.position = "bottom")

save_figure(g, "SI_FigS11_variant_comparison", width = 11, height = 10)
