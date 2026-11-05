# =============================================================================
# MS_Table3_winter_nightly_minimum.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table3_winter_nightly_minimum.csv
# What   : Manuscript Table 3. Per logger: coldest winter nightly minimum (T_min), 5th and 10th percentiles and median of nightly minima.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/MS_Table3_winter_nightly_minimum.R
# =============================================================================
# Summarizes each station's nightly minima (A04). T_min is the single coldest
# hour; the 5th and 10th percentiles describe the coldest 5% and 10% of
# nights, which are less sensitive to one unusual reading than T_min; the
# median is a typical night's minimum.
# =============================================================================
source("lib/pub_setup.R")

minima <- winter_nightly_minima()   # lib/study_data.R

stats <- minima %>%
  group_by(Cave, Logger) %>%
  summarise(t_min = min(night_min),
            p05   = quantile(night_min, 0.05),
            p10   = quantile(night_min, 0.10),
            med   = median(night_min),
            .groups = "drop")

# Every logger in the roster gets a row; Croc-2 L1 and L5 failed before winter.
tbl <- LOGGERS %>%
  select(Cave, Logger) %>%
  left_join(stats, by = c("Cave", "Logger")) %>%
  arrange(Cave, Logger) %>%
  transmute(Cave     = ms_cave(Cave),
            Logger,
            `T_min`  = fmt(t_min, 2, "--"),
            `5th %`  = fmt(p05,   2, "--"),
            `10th %` = fmt(p10,   2, "--"),
            Median   = fmt(med,   2, "--"))

write_table(tbl, pub_path("MS_Table3_winter_nightly_minimum"))
