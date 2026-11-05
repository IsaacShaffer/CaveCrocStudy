# =============================================================================
# run_all.R -- regenerate every publication table and figure
# =============================================================================
# Usage (from pub_code/):
#   Rscript run_all.R            # everything (~50 min)
#   Rscript run_all.R MS_        # only scripts whose name contains "MS_"
#
# Each script runs in its own R process, so every one is proven to work on its
# own. Publication tables need only the data. Figures read intermediate tables
# from figures/analysis/, which run first; a pattern filter does not pull those
# in, so they must already exist when running figures alone.
# =============================================================================

if (!file.exists("lib/pub_setup.R")) stop("Run from pub_code/: Rscript run_all.R")

pattern <- commandArgs(trailingOnly = TRUE)

stages <- list(
  "tables/publication" = c(
    "MS_Table1_logger_inventory", "MS_Table2_winter_night_by_cave",
    "MS_Table3_winter_nightly_minimum", "MS_Table4_winter_night_by_logger",
    "MS_Table5_coherence_raw",
    "SM2_TableS1_day_by_cave", "SM2_TableS2_day_by_logger", "SM2_TableS3_coherence_complete",
    "SI_TableS1_logger_inventory", "SI_TableS2_detrend_df_sweep", "SI_TableS3_ccf_detrended",
    "SI_TableS4_coherence_detrended", "SI_TableS5_te_detrended", "SI_TableS6_teopt_detrended"),
  "figures/analysis" = c(
    "A04_nightly_minimum_winter", "A05_daily_cave_summary",
    "A07_ccf_summary_raw", "A07_ccf_summary_detrended",
    "A08_coherence_summary_raw", "A08_coherence_summary_detrended",
    "A09_coherence_spectra_detrended",
    "A10_te_summary_raw", "A10_te_summary_detrended",
    "A11_teopt_summary_raw", "A11_teopt_summary_detrended",
    "A12_teopt_profiles_detrended", "A13_lagboot_detrended"),
  "figures" = c(
    "MS_Fig2_daily_median_by_cave", "MS_Fig3_winter_nightly_minimum_boxplot",
    "MS_Fig4_coherence_delay_matrix_raw",
    "SI_FigS1_ccf_peaklag_matrix_detrended",
    "SI_FigS2_lagboot_Croc2_detrended", "SI_FigS3_lagboot_KHC_detrended",
    "SI_FigS4_coherence_delay_Croc2_detrended", "SI_FigS5_coherence_delay_KHC_detrended",
    "SI_FigS6_coherence_delay_matrix_detrended", "SI_FigS7_te_matrix_detrended",
    "SI_FigS8_teopt_profile_Croc2_detrended", "SI_FigS9_teopt_profile_KHC_detrended",
    "SI_FigS10_teopt_matrix_detrended", "SI_FigS11_variant_comparison")
)

scripts <- unlist(lapply(names(stages), function(d) file.path(d, paste0(stages[[d]], ".R"))))

# Every script on disk must be scheduled, and every scheduled script must exist.
on_disk <- list.files(names(stages), pattern = "\\.R$", full.names = TRUE)
if (length(setdiff(on_disk, scripts))) stop("Not in run order: ", paste(setdiff(on_disk, scripts), collapse = ", "))
if (length(setdiff(scripts, on_disk))) stop("Missing script: ", paste(setdiff(scripts, on_disk), collapse = ", "))

if (length(pattern)) scripts <- scripts[grepl(paste(pattern, collapse = "|"), scripts)]

rscript <- file.path(R.home("bin"), "Rscript")
dir.create("output/logs", recursive = TRUE, showWarnings = FALSE)
t_all <- Sys.time()
for (s in scripts) {
  log <- file.path("output/logs", sub("\\.R$", ".log", basename(s)))
  t0 <- Sys.time()
  status <- system2(rscript, s, stdout = log, stderr = log)
  cat(sprintf("%-6s %-58s %6.0f s\n", if (status == 0) "ok" else "FAILED", s,
              as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  if (status != 0) {
    cat(tail(readLines(log), 15), sep = "\n")
    stop("Stopped at ", s, " (log: ", log, ")")
  }
}
cat(sprintf("\nDone: %d scripts in %.1f min\n", length(scripts),
            as.numeric(difftime(Sys.time(), t_all, units = "mins"))))
