# =============================================================================
# MS_Table1_logger_inventory.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table1_logger_inventory.csv
# What   : Manuscript Table 1. Logger serial, cave, location, placement, last logged.
# Inputs : data/logger_placement.csv, data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/MS_Table1_logger_inventory.R
# =============================================================================
# Location and placement are edited field notes, so they are read as given.
# "Last Logged" comes from the data (logger_record_span in lib/study_data.R)
# and shows which loggers failed before winter.
# =============================================================================
source("lib/pub_setup.R")

placement <- read_table(PLACEMENT_FILE) %>% mutate(Serial = as.character(Serial))
span      <- logger_record_span()

tbl <- placement %>%
  left_join(span %>% select(Serial, last_logged), by = "Serial") %>%
  arrange(Cave, Logger) %>%
  transmute(`Logger#`     = Logger,
            `Serial#`     = Serial,
            Cave          = ms_cave(Cave),
            Location,
            Placement,
            `Last Logged` = fmt_day(last_logged))

write_table(tbl, pub_path("MS_Table1_logger_inventory"))
