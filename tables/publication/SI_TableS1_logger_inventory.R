# =============================================================================
# SI_TableS1_logger_inventory.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS1_logger_inventory.csv
# What   : Supplement Table S1. Logger inventory (same content as manuscript
#          Table 1, Supplement layout).
# Inputs : data/logger_placement.csv, data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS1_logger_inventory.R
# =============================================================================
# Location and placement are edited field notes, so they are read as given.
# "Last logged" comes from the data (logger_record_span in lib/study_data.R).
# =============================================================================
source("lib/pub_setup.R")

placement <- read_table(PLACEMENT_FILE) %>% mutate(Serial = as.character(Serial))
span      <- logger_record_span()

tbl <- placement %>%
  left_join(span %>% select(Serial, last_logged), by = "Serial") %>%
  arrange(Cave, Logger) %>%
  transmute(Logger, Serial, Cave,
            `Zone / location` = Location,
            `Placement note`  = Placement,
            `Last logged`     = fmt_day(last_logged))

write_table(tbl, pub_path("SI_TableS1_logger_inventory"))
