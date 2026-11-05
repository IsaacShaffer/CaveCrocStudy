# =============================================================================
# SI_FigS8_teopt_profile_Croc2_detrended.R
# -----------------------------------------------------------------------------
# Output : output/figures/SI_FigS8_teopt_profile_Croc2_detrended.png and .pdf
# What   : Supplement Fig. S8. Transfer entropy versus source delay u
#          (1-24 h), both directions, u* marked, one panel per Croc 2 pair,
#          detrended data.
# Inputs : A12_teopt_profiles_detrended
# Run from pub_code/:  Rscript figures/SI_FigS8_teopt_profile_Croc2_detrended.R
# =============================================================================
# Shows how each optimal delay u* in SI Table S6 was chosen. A clear interior
# peak supports a definite travel time; a flat curve, or a maximum at u = 1 or
# 24 h (flagged in the table), means u* is poorly determined.
# =============================================================================
source("lib/pub_setup.R")

cave <- "Croc-2"
d <- read_analysis("A12_teopt_profiles_detrended") %>%
  filter(Cave == cave) %>%
  mutate(Pair = factor(Pair, levels = PAIR_LEVELS))
stars <- d %>% filter(u_hr == u_star)

g <- ggplot(d, aes(u_hr, te, colour = direction)) +
  geom_vline(xintercept = 0, linetype = "dashed", color = "gray20", linewidth = 0.5) +
  geom_line(linewidth = 0.5) +
  geom_point(data = stars, size = 2.4) +
  facet_wrap(~ Pair, ncol = 2, scales = "free_y") +
  scale_x_continuous(breaks = seq(0, 24, 3), limits = c(0, NA)) +
  labs(x = "Source delay u (hours)", y = "Transfer entropy (bits)", colour = "Direction") +
  theme_minimal() +
  theme(strip.text = element_text(face = "bold"), panel.grid.minor = element_blank())

save_figure(g, "SI_FigS8_teopt_profile_Croc2_detrended", width = 9.5, height = facet_height(n_distinct(d$Pair)))
