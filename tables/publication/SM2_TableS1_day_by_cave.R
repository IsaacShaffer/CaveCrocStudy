# =============================================================================
# SM2_TableS1_day_by_cave.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SM2_TableS1_day_by_cave.csv
# What   : Supplemental Material File 2, Table S1. Monthly daytime median and
#          days with a reading >= threshold, by cave, Aug 2022 - Feb 2023.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SM2_TableS1_day_by_cave.R
# =============================================================================
# The daytime counterpart of MS Table 2, over the whole analysis window, for
# readers who want the full record. A day counts as above threshold if any
# logger in the cave reached it during the day window (a date counts once).
# =============================================================================
source("lib/pub_setup.R")

tbl <- diel_tagged() %>%
  filter(is_day) %>%
  mutate(Month = format(clock_date, "%Y-%m")) %>%
  filter(Month %in% STUDY_MONTHS) %>%   # drop the partial month before 1 Aug
  group_by(Cave, Month) %>%
  summarise(median_day   = round(median(Temperature, na.rm = TRUE), 2),
            n_days       = n_distinct(clock_date),
            n_days_above = n_distinct(clock_date[above_threshold]),
            .groups = "drop") %>%
  arrange(Cave, Month) %>%
  transmute(Cave, Month,
            `Median day`                     = fmt(median_day, 2),
            `# Days above thermal threshold` = n_days_above,
            `total # days`                   = n_days)

write_table(tbl, pub_path("SM2_TableS1_day_by_cave"))
