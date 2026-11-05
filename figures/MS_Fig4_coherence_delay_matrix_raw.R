# =============================================================================
# MS_Fig4_coherence_delay_matrix_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/MS_Fig4_coherence_delay_matrix_raw.png and .pdf
# What   : Manuscript Fig. 4. Heatmaps of the phase-derived delay (h) at peak
#          coherency for every logger pair, (A) Croc 2 and (B) KHC, raw data.
# Inputs : A08_coherence_summary_raw
# Run from pub_code/:  Rscript figures/MS_Fig4_coherence_delay_matrix_raw.R
# =============================================================================
# Puts all pairwise delays of a cave in one grid, so the ordering of stations
# can be read at a glance: a row that is orange across means that logger
# leads the others. Both panels share one colour scale (+/- the largest
# |delay| in either cave) so the caves can be compared directly. Labels use
# one decimal, as in MS Table 5.
# =============================================================================
source("lib/pub_setup.R")

coh <- read_analysis("A08_coherence_summary_raw")
lim <- max(abs(coh$delay_at_peak_hr))

panel <- function(cave) {
  plot_pair_matrix(coh, cave, "delay_at_peak_hr", "Delay (h)",
                   label_fmt = "%.1f", limits = c(-lim, lim)) +
    labs(x = "Comparison Logger", y = "Reference Logger")
}

g <- (panel("Croc-2") | panel("KHC")) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A")

save_figure(g, "MS_Fig4_coherence_delay_matrix_raw", width = 12, height = 5.2)
