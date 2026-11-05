# =============================================================================
# MS_Fig3_winter_nightly_minimum_boxplot.R
# -----------------------------------------------------------------------------
# Output : output/figures/MS_Fig3_winter_nightly_minimum_boxplot.png and .pdf
# What   : Manuscript Fig. 3. Boxplots of winter nightly minimum Tw (18:30-05:30) per logger, coloured by cave, with the thermal threshold.
# Inputs : A04_nightly_minimum_winter
# Run from pub_code/:  Rscript figures/MS_Fig3_winter_nightly_minimum_boxplot.R
# =============================================================================
source("lib/pub_setup.R")

m <- read_analysis("A04_nightly_minimum_winter") %>%
  arrange(Cave, Logger) %>%
  mutate(station = factor(paste(Cave, Logger), levels = unique(paste(Cave, Logger))))

g <- ggplot(m, aes(station, night_min, fill = Cave)) +
  geom_boxplot(width = 0.7, outlier.size = 1.6) +
  geom_hline(aes(yintercept = THRESHOLD, linetype = "threshold"), linewidth = 0.8,
             key_glyph = "path") +
  scale_fill_manual(values = CAVE_COLOURS, labels = c("Croc-2" = "Croc 2", "KHC" = "KHC"), name = NULL) +
  scale_linetype_manual(values = c(threshold = "dashed"),
                        labels = sprintf("%.2f°C\nthreshold", THRESHOLD), name = NULL) +
  scale_x_discrete(labels = function(x) sub(".* ", "", x)) +
  labs(x = "Data Logger", y = "Nightly Minimum Temperature (°C)") +
  theme_classic(base_size = 13) +
  theme(legend.position = "inside", legend.position.inside = c(0.88, 0.2),
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        legend.spacing.y = unit(2, "pt"),
        legend.key.width = unit(28, "pt"))

save_figure(g, "MS_Fig3_winter_nightly_minimum_boxplot", width = 7, height = 5)
