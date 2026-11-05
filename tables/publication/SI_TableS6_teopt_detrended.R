# =============================================================================
# SI_TableS6_teopt_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS6_teopt_detrended.csv
# What   : Supplement Table S6. Delay-optimized TE per pair (detrended): CCF lag, optimal delay u* with surrogate p each way (* = pinned at a grid edge), ETE at u*, net, dominant direction.
# Inputs : A11_teopt_summary_detrended
# Run from pub_code/:  Rscript tables/publication/SI_TableS6_teopt_detrended.R
# =============================================================================
source("lib/pub_setup.R")

# u* with its surrogate p, flagged "*" where u* sits on the [1, lag_max] grid edge
# (typeset in the Supplement as a dagger).
u_with_p <- function(u, p, edge) sprintf("%d%s (%.2f)", as.integer(u), ifelse(edge, "*", ""), p)

tbl <- read_analysis("A11_teopt_summary_detrended") %>%
  arrange(Cave, Pair) %>%
  transmute(Cave, Pair,
            `u_CCF`          = sprintf("%+.2f", u_ccf_hr),
            `u* A->B (p)`    = u_with_p(u_star_a_to_b_hr, p_delay_a_to_b, as.logical(edge_a_to_b)),
            `ETE A->B`       = fmt(ete_a_to_b, 3),
            `u* B->A (p)`    = u_with_p(u_star_b_to_a_hr, p_delay_b_to_a, as.logical(edge_b_to_a)),
            `ETE B->A`       = fmt(ete_b_to_a, 3),
            Net              = sprintf("%+.3f", net_ete),
            Dominant         = dominant_direction)

write_table(tbl, pub_path("SI_TableS6_teopt_detrended"))
