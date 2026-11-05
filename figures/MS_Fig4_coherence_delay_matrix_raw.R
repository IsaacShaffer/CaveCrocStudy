# =============================================================================
# MS_Fig4_coherence_delay_matrix_raw.R
# -----------------------------------------------------------------------------
# Output : output/figures/MS_Fig4_coherence_delay_matrix_raw.png and .pdf
# What   : Manuscript Fig. 4. Phase-derived delay (h) at peak coherency for every logger pair, (A) Crocodile Cave 2 and (B) KHC, raw data; one shared colour scale.
# Inputs : A08_coherence_summary_raw
# Run from pub_code/:  Rscript figures/MS_Fig4_coherence_delay_matrix_raw.R
# =============================================================================
source("lib/pub_setup.R")

coh <- read_analysis("A08_coherence_summary_raw")
lim <- max(abs(coh$delay_at_peak_hr))

panel <- function(cave) {
  g <- plot_pair_matrix(coh, cave, "delay_at_peak_hr", "Delay (h)", signed = TRUE)
  g$layers[[2]]$mapping <- aes(label = sprintf("%.1f", val))   # one decimal, as published
  suppressMessages(
    g + scale_fill_gradient2(low = "#56B4E9", mid = "grey92", high = "#E69F00",
                             midpoint = 0, limits = c(-lim, lim)) +
      labs(x = "Comparison Logger", y = "Reference Logger")
  )
}

g <- (panel("Croc-2") | panel("KHC")) +
  plot_layout(guides = "collect") +
  plot_annotation(tag_levels = "A")

save_figure(g, "MS_Fig4_coherence_delay_matrix_raw", width = 12, height = 5.2)
