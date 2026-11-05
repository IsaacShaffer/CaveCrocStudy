# =============================================================================
# SI_TableS1_logger_inventory.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS1_logger_inventory.csv
# What   : Supplement Table S1. Logger inventory (same content as manuscript Table 1, Supplement layout).
# Inputs : data/logger_placement.csv, A01_logger_record_span
# Run from pub_code/:  Rscript tables/publication/SI_TableS1_logger_inventory.R
# =============================================================================
source("lib/pub_setup.R")

placement <- read_table(PLACEMENT_FILE) %>% mutate(Serial = as.character(Serial))
span      <- read_analysis("A01_logger_record_span") %>% mutate(Serial = as.character(Serial))

tbl <- placement %>%
  left_join(span %>% select(Serial, last_logged), by = "Serial") %>%
  arrange(Cave, Logger) %>%
  transmute(Logger, Serial, Cave,
            `Zone / location` = Location,
            `Placement note`  = Placement,
            `Last logged`     = fmt_day(last_logged))

write_table(tbl, pub_path("SI_TableS1_logger_inventory"))
