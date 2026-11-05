# =============================================================================
# MS_Table2_winter_night_by_cave.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table2_winter_night_by_cave.csv
# What   : Manuscript Table 2. Winter (Nov-Feb) monthly night median, % nights with an observation >= threshold, median nightly range, by cave.
# Inputs : A02_diel_cave_month
# Run from pub_code/:  Rscript tables/publication/MS_Table2_winter_night_by_cave.R
# =============================================================================
source("lib/pub_setup.R")

winter_months <- format(seq(WINTER[1], WINTER[2], by = "month"), "%Y-%m")

tbl <- read_analysis("A02_diel_cave_month") %>%
  filter(Month %in% winter_months) %>%
  arrange(Cave, Month) %>%
  transmute(Cave   = ms_cave(Cave),
            Month,
            Median = fmt(median_night, 2),
            !!sprintf("%% Nights > %.2f°C", THRESHOLD) := fmt(100 * n_nights_above / n_nights, 2),
            Range  = fmt(median_nightly_range, 2))

write_table(tbl, pub_path("MS_Table2_winter_night_by_cave"))
