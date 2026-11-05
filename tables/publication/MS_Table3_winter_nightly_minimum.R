# =============================================================================
# MS_Table3_winter_nightly_minimum.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table3_winter_nightly_minimum.csv
# What   : Manuscript Table 3. Per logger: coldest winter nightly minimum (T_min), 5th and 10th percentiles and median of nightly minima.
# Inputs : A04_nightly_minimum_winter (loggers with no winter nights shown as --)
# Run from pub_code/:  Rscript tables/publication/MS_Table3_winter_nightly_minimum.R
# =============================================================================
source("lib/pub_setup.R")

minima <- read_analysis("A04_nightly_minimum_winter")

stats <- minima %>%
  group_by(Cave, Logger) %>%
  summarise(t_min = min(night_min),
            p05   = quantile(night_min, 0.05),
            p10   = quantile(night_min, 0.10),
            med   = median(night_min),
            .groups = "drop")

# Every logger in the roster gets a row; Croc-2 L1 and L5 failed before winter.
roster <- sensor_style %>%
  transmute(Cave = ifelse(grepl("^Croc2", Logger_Name), "Croc-2", "KHC"),
            Logger = short_logger(Logger_Name))

tbl <- roster %>%
  left_join(stats, by = c("Cave", "Logger")) %>%
  arrange(Cave, Logger) %>%
  transmute(Cave     = ms_cave(Cave),
            Logger,
            `T_min`  = fmt(t_min, 2, "--"),
            `5th %`  = fmt(p05,   2, "--"),
            `10th %` = fmt(p10,   2, "--"),
            Median   = fmt(med,   2, "--"))

write_table(tbl, pub_path("MS_Table3_winter_nightly_minimum"))
