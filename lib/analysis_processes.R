# =============================================================================
# analysis_processes.R — shared layer for the cave-temperature analyses
# =============================================================================
# Single sourced module loaded by all driver scripts:
#
#   Observational_Analysis.R   -> descriptive statistics, graphics, tables ONLY
#   Model_Analyses.R           -> all directional/modelling tools (CCF, coherence/
#                                 phase, lag-bootstrap, TE, TE-optimal, DTW), each
#                                 run for both the raw and detrended variants
#   Stationarity_Comparison.R  -> raw-vs-detrended deltas (reads Model outputs)
#
# Every stationarity-assuming analysis (spectral coherence/phase, CCF, per-lag
# pairs bootstrap, transfer entropy) is run twice -- once on RAW pairs, once on
# DETRENDED pairs. That choice is made in the L3 driver (Model_Analyses.R): it
# shapes the data with prepare_pairs() under a stationarizer of its choosing --
#   raw       -> identity
#   detrended -> function(x) harmonic_detrend(x, period = 24, df = 8)
#                (residuals of lm(x ~ ns(t, df=8) + sin(2*pi*t/24) + cos(2*pi*t/24)):
#                a natural-cubic-spline trend plus a diurnal sin+cos pair, removing
#                the slow nonlinear wet->dry drift AND the 24 h cycle; the spline
#                trend is what reaches KPSS stationarity -- see detrend_test.R)
# -- and hands the resulting prepared pairs to the run_* drivers. The drivers
# branch on NOTHING: they do identical work on whichever data they receive, and
# take a `tag` ("raw"/"detrended") only for the output-filename suffix (out_name()).
# So the raw/detrended difference lives entirely in the data, never in a flag.
# Seeds are identical across the two runs.
#
# Sign convention (shared by all analyses): positive lag / positive net info
# flow = the FIRST logger in the pair label leads / drives the second.
# =============================================================================

# -----------------------------------------------------------------------------
# Packages
# -----------------------------------------------------------------------------
library(readr)
library(forcats)
library(tibble)
library(readxl)
library(openxlsx)
library(purrr)
library(lubridate)
library(scales)
library(ggplot2)
library(dplyr)
library(tidyr)
library(knitr)
library(gridExtra)
library(patchwork)
library(corrplot)
library(RTransferEntropy)
library(future)
library(splines)
source("analysis_kernels.R")   # L1 pure kernels (values in -> values out)

# If dplyr/tidyr/purrr were attached earlier (or masked by another package),
# force them back to the top of the search path so their verbs win.
suppressPackageStartupMessages({
  for (pkg in c("dplyr", "tidyr", "purrr")) {
    pkg_pos <- paste0("package:", pkg)
    if (pkg_pos %in% search()) {
      try(detach(pkg_pos, character.only = TRUE, unload = FALSE), silent = TRUE)
    }
    library(pkg, character.only = TRUE)
  }
})

# Deterministic, single-process transfer entropy. Sequential also avoids the
# parallel-worker spawn that fails when Windows R is driven through WSL interop.
future::plan(future::sequential)

# L2 layer, split by role (all sourced here so `source("analysis_processes.R")`
# still loads the whole shared layer):
source("L2_data.R")      # loaders + pair/series preparers
source("L2_plots.R")     # ggplot builders + matrix heatmaps
source("L2_drivers.R")   # per-pair wrappers + run_* drivers + compare_variants
