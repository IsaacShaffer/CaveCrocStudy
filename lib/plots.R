# =============================================================================
# plots.R -- figure helpers used by more than one figure script
# =============================================================================

# Write a figure as a 300 dpi PNG and a PDF. cairo_pdf embeds Unicode glyphs
# (e.g. the >= in Fig. S11's legend) that the default pdf() device cannot draw.
save_figure <- function(plot, name, width, height) {
  png_path <- file.path(FIG_DIR, paste0(name, ".png"))
  pdf_path <- file.path(FIG_DIR, paste0(name, ".pdf"))
  ggsave(png_path, plot, width = width, height = height, dpi = 300)
  ggsave(pdf_path, plot, width = width, height = height,
         device = if (capabilities("cairo")) grDevices::cairo_pdf else "pdf")
  cat(sprintf("Figure written: %s (.png, .pdf)\n", file.path(FIG_DIR, name)))
  invisible(plot)
}

# Height (in) of a figure with one panel per pair laid out in two columns.
facet_height <- function(n_pairs) 2 + 1.5 * max(1L, ceiling(n_pairs / 2))

# Pair-by-pair heatmap of a SIGNED pairwise value (lag or delay, positive =
# first logger of the pair leads). Cell (row a, column b) holds the value and
# cell (b, a) its negative, so each row reads "how far this logger leads each
# other logger". Blue-grey-orange diverging scale centred on 0; diagonal blank.
plot_pair_matrix <- function(summary, cave, value_col, fill_lab, label_fmt = "%.2f", limits = NULL) {
  d <- summary %>%
    filter(Cave == cave) %>%
    transmute(a = sub("-.*", "", Pair), b = sub(".*-", "", Pair), val = .data[[value_col]])
  cells <- bind_rows(transmute(d, from = a, to = b, val),
                     transmute(d, from = b, to = a, val = -val))
  lv <- sort(unique(c(cells$from, cells$to)))
  cells <- cells %>% mutate(from = factor(from, levels = rev(lv)), to = factor(to, levels = lv))

  ggplot(cells, aes(x = to, y = from, fill = val)) +
    geom_tile(color = "white", linewidth = 1.2) +
    geom_text(aes(label = sprintf(label_fmt, val)), size = 3, color = "gray10") +
    coord_equal() +
    labs(x = "to (target)", y = "from (source / leader)", fill = fill_lab) +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(), axis.ticks = element_blank()) +
    scale_fill_gradient2(low = "#56B4E9", mid = "grey92", high = "#E69F00", midpoint = 0,
                         limits = limits)
}

# Pair-by-pair heatmap of a DIRECTED quantity (e.g. ETE a->b and ETE b->a).
# Unlike plot_pair_matrix the two triangles are independent estimates, not
# mirror images. Cells whose own p-value is >= 0.05 are greyed out with a muted
# label, so colour marks only the statistically supported transfers.
plot_pair_matrix_directional <- function(summary, cave, col_ab, col_ba, pcol_ab, pcol_ba, fill_lab) {
  d <- summary %>%
    filter(Cave == cave) %>%
    transmute(a = sub("-.*", "", Pair), b = sub(".*-", "", Pair),
              ab = .data[[col_ab]], ba = .data[[col_ba]],
              pab = .data[[pcol_ab]], pba = .data[[pcol_ba]])
  cells <- bind_rows(transmute(d, from = a, to = b, val = ab, p = pab),
                     transmute(d, from = b, to = a, val = ba, p = pba))
  lv <- sort(unique(c(cells$from, cells$to)))
  cells <- cells %>% mutate(from     = factor(from, levels = rev(lv)),
                            to       = factor(to, levels = lv),
                            sig      = p < 0.05,
                            fill_val = ifelse(sig, val, NA_real_))

  ggplot(cells, aes(x = to, y = from)) +
    geom_tile(aes(fill = fill_val), color = "white", linewidth = 1.2) +
    geom_text(aes(label = sprintf("%.3f", val), colour = sig), size = 3) +
    coord_equal() +
    labs(x = "to (target)", y = "from (source / leader)", fill = fill_lab) +
    scale_fill_gradient(low = "#D6E6F4", high = "#0072B2", na.value = "grey85") +
    scale_colour_manual(values = c(`TRUE` = "gray10", `FALSE` = "gray55"), guide = "none") +
    theme_minimal(base_size = 11) +
    theme(panel.grid = element_blank(), axis.ticks = element_blank())
}
