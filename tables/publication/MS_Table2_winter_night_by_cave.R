# =============================================================================
# MS_Table2_winter_night_by_cave.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table2_winter_night_by_cave.csv
# What   : Manuscript Table 2. Winter (Nov-Feb) monthly night median, % nights
#          with a reading >= threshold, and median nightly range, by cave.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/MS_Table2_winter_night_by_cave.R
# =============================================================================
# Question 1 of the study is whether a crocodile could stay in the cave all
# winter. Nights are the critical time: crocodiles cannot bask, and water is
# coldest. For each cave and winter month:
#   Median    typical night water temperature (all loggers in the cave pooled);
#   % Nights  share of nights on which at least one reading anywhere in the
#             cave reached the threshold, i.e. warm-enough water existed
#             somewhere that night (a night counts once, whichever logger);
#   Range     median over logger-nights of (max - min) within one logger's
#             night, a measure of stability. Taking the range within one
#             logger keeps differences between loggers out of it.
# =============================================================================
source("lib/pub_setup.R")

# A night runs 18:30-05:30 and belongs to the month of the evening it starts.
nights <- diel_tagged() %>%
  filter(is_night) %>%
  mutate(Month = format(night_date, "%Y-%m")) %>%
  filter(Month %in% WINTER_MONTHS)

night <- nights %>%
  group_by(Cave, Month) %>%
  summarise(median_night   = round(median(Temperature, na.rm = TRUE), 2),
            n_nights       = n_distinct(night_date),
            n_nights_above = n_distinct(night_date[above_threshold]),
            .groups = "drop")

night_range <- nights %>%
  group_by(Cave, Month, Logger, night_date) %>%
  summarise(night_range = max(Temperature) - min(Temperature), .groups = "drop") %>%
  group_by(Cave, Month) %>%
  summarise(median_nightly_range = round(median(night_range), 2), .groups = "drop")

tbl <- night %>%
  left_join(night_range, by = c("Cave", "Month")) %>%
  arrange(Cave, Month) %>%
  transmute(Cave   = ms_cave(Cave),
            Month,
            Median = fmt(median_night, 2),
            !!sprintf("%% Nights > %.2f°C", THRESHOLD) := fmt(100 * n_nights_above / n_nights, 2),
            Range  = fmt(median_nightly_range, 2))

write_table(tbl, pub_path("MS_Table2_winter_night_by_cave"))
