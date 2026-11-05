# =============================================================================
# MS_Table4_winter_night_by_logger.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table4_winter_night_by_logger.csv
# What   : Manuscript Table 4. Winter (Nov-Feb) monthly night median and
#          % nights with a reading >= threshold, by logger.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/MS_Table4_winter_night_by_logger.R
# =============================================================================
# Question 2 of the study is whether cave water is thermally uniform. This
# gives MS Table 2's night statistics for each station separately: if stations
# differ in their night medians or in how often they reach the threshold, a
# crocodile could find warmer spots by moving within the cave. Loggers with no
# nights in a month (stopped recording) have no row for it.
# =============================================================================
source("lib/pub_setup.R")

# A night runs 18:30-05:30 and belongs to the month of the evening it starts.
tbl <- diel_tagged() %>%
  filter(is_night) %>%
  mutate(Month = format(night_date, "%Y-%m")) %>%
  filter(Month %in% WINTER_MONTHS) %>%
  group_by(Cave, Logger, Month) %>%
  summarise(median_night   = round(median(Temperature, na.rm = TRUE), 2),
            n_nights       = n_distinct(night_date),
            n_nights_above = n_distinct(night_date[above_threshold]),
            .groups = "drop") %>%
  arrange(Cave, Logger, Month) %>%
  transmute(Cave   = ms_cave(Cave),
            Logger,
            Month,
            Median = fmt(median_night, 2),
            !!sprintf("Nights > %.2f°C (%%)", THRESHOLD) := fmt(100 * n_nights_above / n_nights, 2))

write_table(tbl, pub_path("MS_Table4_winter_night_by_logger"))
