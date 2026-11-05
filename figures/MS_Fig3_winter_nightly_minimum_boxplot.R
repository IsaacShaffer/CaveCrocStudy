# =============================================================================
# MS_Fig3_winter_nightly_minimum_boxplot.R
# -----------------------------------------------------------------------------
# Output : output/figures/MS_Fig3_winter_nightly_minimum_boxplot.png and .pdf
# What   : Manuscript Fig. 3. Boxplots of winter nightly minimum water
#          temperature per logger, coloured by cave, with the threshold.
# Inputs : A04_nightly_minimum_winter
# Run from pub_code/:  Rscript figures/MS_Fig3_winter_nightly_minimum_boxplot.R
# =============================================================================
# The distribution of each station's coldest hour per night (A04) answers both
# questions at once: where the boxes sit relative to the threshold shows
# whether the cave stays warm enough (question 1); how much boxes differ
# between stations of one cave shows how uniform it is (question 2). Croc 2 L1
# and L5 failed before winter and so have no box.
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
  # Untitled legends have no guaranteed order, so fix it: threshold, then caves.
  guides(linetype = guide_legend(order = 1), fill = guide_legend(order = 2)) +
  labs(x = "Data Logger", y = "Nightly Minimum Temperature (°C)") +
  theme_classic(base_size = 13) +
  theme(legend.position = "inside", legend.position.inside = c(0.88, 0.2),
        legend.background = element_blank(),
        legend.box.background = element_rect(colour = "black"),
        legend.spacing.y = unit(2, "pt"),
        legend.key.width = unit(28, "pt"))

save_figure(g, "MS_Fig3_winter_nightly_minimum_boxplot", width = 7, height = 5)
