# =============================================================================
# SI_TableS6_teopt_detrended.R
# -----------------------------------------------------------------------------
# Output : output/tables/publication/SI_TableS6_teopt_detrended.csv
# What   : Supplement Table S6. Delay-optimized TE per pair (detrended): CCF lag, optimal delay u* with surrogate p each way (* = pinned at a grid edge), ETE at u*, net, dominant direction.
# Inputs : data/all_cave_temp_data_ext.xlsx
# Run from pub_code/:  Rscript tables/publication/SI_TableS6_teopt_detrended.R
# =============================================================================
# A u* on the edge of the 1-24 h scan is marked because the true optimum may
# lie outside the scanned range; read those delays as bounds, not estimates.
# =============================================================================
source("lib/pub_setup.R")

# u* with its surrogate p, flagged "*" where u* sits on the [1, lag_max] grid edge
# (typeset in the Supplement as a dagger).
u_with_p <- function(u, p, edge) sprintf("%d%s (%.2f)", as.integer(u), ifelse(edge, "*", ""), p)

# Detrended variant: seasonal drift and the 24 h cycle removed from each
# series (harmonic_detrend in lib/study_data.R), so the statistics reflect
# station-to-station timing rather than forcing shared by all stations.
pairs <- prepare_pairs(harmonic_detrend)

tbl <- teopt_results(pairs)$summary %>%   # slow: several minutes
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
