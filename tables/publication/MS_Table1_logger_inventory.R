# =============================================================================
# MS_Table1_logger_inventory.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/MS_Table1_logger_inventory.csv
# What   : Manuscript Table 1. Logger serial, cave, location, placement, last logged.
# Inputs : data/logger_placement.csv, A01_logger_record_span
# Run from pub_code/:  Rscript tables/publication/MS_Table1_logger_inventory.R
# =============================================================================
source("lib/pub_setup.R")

placement <- read_table(PLACEMENT_FILE) %>% mutate(Serial = as.character(Serial))
span      <- read_analysis("A01_logger_record_span") %>% mutate(Serial = as.character(Serial))

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
