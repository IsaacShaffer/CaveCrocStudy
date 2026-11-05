# =============================================================================
# SI_FigS4_coherence_delay_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS4_coherence_delay_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S4. Phase-derived delay (h) versus period (2-168 h,
#          log scale), one panel per Croc 2 logger pair, detrended data.
# Inputs : A09_coherence_spectra_detrended
# Run from pub_code/:  Rscript figures/SI_FigS4_coherence_delay_Croc2_detrended.R
# =============================================================================
# SI Table S4 gives one delay per pair, read at the period of peak coherency.
# This shows the delay at every period, so a reader can judge whether that
# value sits on a stable stretch of the curve or on a jump. Positive delay =
# first logger of the pair leads. (Line colour as in the published figure.)
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
d <- read_analysis("A09_coherence_spectra_detrended") %>%
  filter(Cave == cave) %>%
  mutate(Pair = factor(Pair, levels = PAIR_LEVELS))

g <- ggplot(d, aes(period_hr, delay_hr)) +
  geom_hline(yintercept = 0, linetype = "dashed", color = "gray20", linewidth = 0.5) +
  geom_line(linewidth = 0.4, color = "#E69F00") +
  facet_wrap(~ Pair, ncol = 2, scales = "free_y") +
  scale_x_continuous(trans = "log10", breaks = c(2, 6, 12, 24, 48, 72, 168),
                     labels = c(2, 6, 12, 24, 48, 72, 168)) +
  labs(title = "Phase-derived delay", x = "Period (hours, log scale)", y = "Delay (h)") +
  theme_minimal() +
  theme(plot.title = element_text(size = 11, face = "bold"),
        strip.text = element_text(face = "bold"),
        panel.grid.minor = element_blank())

save_figure(g, "SI_FigS4_coherence_delay_Croc2_detrended", width = 9.5, height = facet_height(n_distinct(d$Pair)))
