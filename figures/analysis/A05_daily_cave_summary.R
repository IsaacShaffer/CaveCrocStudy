# =============================================================================
# A05_daily_cave_summary.R
# -----------------------------------------------------------------------------
# Output : output/figures/analysis/A05_daily_cave_summary.csv
# What   : Daily median, quartiles, min, max and share of readings at or above
#          the threshold, per cave (all loggers pooled), by local clock date.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Used by: MS_Fig2
# Run from pub_code/:  Rscript figures/analysis/A05_daily_cave_summary.R
# =============================================================================
# MS Fig. 2 shows the seasonal course of each cave against the threshold. A
# daily median smooths out the diurnal cycle so the seasonal cooling is
# visible; the 25th-75th percentiles show the spread across loggers and hours
# within the day.
# =============================================================================
source("lib/pub_setup.R")

tbl <- load_study_hourly() %>%
  group_by(Date = clock_date, Cave) %>%
  summarise(n_obs       = n(),
            temp_median = median(Temperature, na.rm = TRUE),
            temp_min    = min(Temperature, na.rm = TRUE),
            temp_max    = max(Temperature, na.rm = TRUE),
            temp_q25    = quantile(Temperature, 0.25, na.rm = TRUE),
            temp_q75    = quantile(Temperature, 0.75, na.rm = TRUE),
            prop_above_threshold = mean(above_threshold, na.rm = TRUE),
            .groups = "drop") %>%
  arrange(Cave, Date)

write_table(tbl, analysis_path("A05_daily_cave_summary"))
