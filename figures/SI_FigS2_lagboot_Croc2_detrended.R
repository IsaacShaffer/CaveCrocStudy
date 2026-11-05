# =============================================================================
# SI_FigS2_lagboot_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS2_lagboot_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S2. Cross-correlation versus lag (-24..+24 h) with
#          its 95% bootstrap band, one panel per Croc 2 logger pair, detrended.
# Inputs : A13_lagboot_detrended
# Run from pub_code/:  Rscript figures/SI_FigS2_lagboot_Croc2_detrended.R
# =============================================================================
# Shows the whole correlation curve behind each CCF peak lag (SI Table S3):
# a sharp peak clear of its neighbours and of zero supports a definite lead;
# a broad or flat curve means the peak lag is poorly determined. Positive lag
# = first logger of the pair leads.
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
d <- read_analysis("A13_lagboot_detrended") %>%
  filter(Cave == cave) %>%
  mutate(Pair = factor(Pair, levels = PAIR_LEVELS))

g <- ggplot(d, aes(x = lag_hr, y = corr_obs)) +
  geom_vline(xintercept = 0, color = "gray20", linewidth = 0.7) +
  geom_hline(yintercept = 0, color = "gray70", linewidth = 0.3) +
  geom_ribbon(aes(ymin = ci_low, ymax = ci_high), fill = "steelblue", alpha = 0.25) +
  geom_line(color = "steelblue4", linewidth = 0.4) +
  geom_point(color = "gray15", size = 1.4) +
  facet_wrap(~ Pair, ncol = 2, scales = "free_y") +
  scale_x_continuous(breaks = seq(-24, 24, 6)) +
  labs(x = "Lag (hours)", y = "Correlation") +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold"), panel.grid.minor = element_blank())

save_figure(g, "SI_FigS2_lagboot_Croc2_detrended", width = 9.5, height = facet_height(n_distinct(d$Pair)))
