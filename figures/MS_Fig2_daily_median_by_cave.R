# =============================================================================
# MS_Fig2_daily_median_by_cave.R
# -----------------------------------------------------------------------------
# Output : output/figures/MS_Fig2_daily_median_by_cave.png and .pdf
# What   : Manuscript Fig. 2. Daily median water temperature per cave over the
#          analysis window, with the 25th-75th percentile band and the threshold.
# Inputs : A05_daily_cave_summary
# Run from pub_code/:  Rscript figures/MS_Fig2_daily_median_by_cave.R
# =============================================================================
# Shows the seasonal setting for the winter results: both caves cool from
# August into winter and approach the 24.25 degC threshold. The band shows the
# spread across loggers and hours each day (the caption says "range among
# monitoring sites"; see README.md).
# =============================================================================
source("lib/pub_setup.R")

d <- read_analysis("A05_daily_cave_summary") %>% mutate(Date = as.Date(Date))
cave_names <- c("Croc-2" = "Crocodile Cave 2", "KHC" = "KHC Cave")

g <- ggplot(d, aes(Date, temp_median, colour = Cave, fill = Cave)) +
  geom_hline(yintercept = THRESHOLD, linetype = "dashed", colour = "black", linewidth = 0.8) +
  geom_ribbon(aes(ymin = temp_q25, ymax = temp_q75), alpha = 0.25, colour = NA) +
  geom_line(linewidth = 0.6) +
  scale_colour_manual(values = CAVE_COLOURS, labels = cave_names) +
  scale_fill_manual(values = CAVE_COLOURS, labels = cave_names) +
  scale_x_date(breaks = seq(as.Date("2022-08-01"), as.Date("2023-03-01"), by = "month"),
               date_labels = "%b") +
  labs(x = "Month (2022-2023)", y = "Temperature (°C)", colour = NULL, fill = NULL) +
  theme_minimal() +
  theme(legend.position = "bottom")

save_figure(g, "MS_Fig2_daily_median_by_cave", width = 10, height = 5)
