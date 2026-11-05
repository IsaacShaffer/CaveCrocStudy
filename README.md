# CaveCrocStudy: publication tables and figures

Code that regenerates every code-derived table and figure in the three
publication documents, with one script per output:

- **MS**: the manuscript (`Wynne-etal_CaveCrocs.docx`, JJW 23 Jul 2026 version)
- **SM2**: Supplemental Material File 2 (`SM_File2_SupportingTables_RawData_jjw13aug26.xlsx`)
- **SI**: the Supplement (`Supplement_v3.tex`)

Regenerating the tables turned up several places where the manuscript's numbers,
captions or definitions disagree with the code or with each other. They are
listed under [Discrepancies with the manuscript](#discrepancies-with-the-manuscript)
and need a decision before submission.

## Running

The repository holds only the R code for now. Before running, put the inputs in
`data/`:

- `all_cave_temp_data_ext.xlsx`: hourly Tw, one sheet per logger
- `logger_placement.csv`: columns `Serial,Cave,Logger,Location,Placement`, with
  the location and placement text exactly as printed in MS Table 1

R ≥ 4.6 and these packages are required: tidyverse, readxl, openxlsx,
lubridate, scales, tseries, RTransferEntropy, future, patchwork, gridExtra.
Published results were produced with R 4.6.2. The manuscript cites 4.5.2.

From this directory:

```bash
Rscript run_all.R              # everything in dependency order, ~35 min
Rscript run_all.R MS_          # only scripts matching a pattern (inputs must exist)
Rscript run_all.R --keep-cache # reuse cached TE-optimal results
Rscript tables/publication/MS_Table2_winter_night_by_cave.R   # any single script
```

Every script expects this directory as the working directory. Each one reads
only its listed inputs and writes exactly one output under `output/`. Logs go
to `output/logs/`.

## Layout

| Path | Contents |
|---|---|
| `lib/analysis_kernels.R`, `lib/L2_*.R`, `lib/analysis_processes.R` | Support libraries copied **unchanged** from the analysis repo. |
| `lib/pub_setup.R` | Timezone pin, every reported constant, paths, read/write helpers. |
| `lib/pub_builders.R` | `build_*()` functions behind the analysis tables. They reuse the library's per-pair functions, seeds and rounding. |
| `tables/analysis/A*.R` | 19 analysis tables, which are intermediate and unpublished → `output/tables/analysis/*.csv` |
| `tables/publication/*.R` | 14 publication tables → `output/tables/publication/*.csv` |
| `figures/*.R` | 14 publication figures → `output/figures/*.png` + `.pdf` |
| `run_all.R` | Runs all 47 scripts in dependency order, each in a fresh R process. |

## Outputs and their inputs

### Analysis tables (from the data)

| Script / output | Contents |
|---|---|
| `A01_logger_record_span` | First/last timestamp per logger, over the full deployment |
| `A02_diel_cave_month` | Day and night medians, day/night counts with ≥1 obs ≥ 24.25 °C, median nightly range, by cave × month |
| `A03_diel_logger_month` | Same, by logger × month |
| `A04_nightly_minimum_winter` | Minimum Tw of each logger-night, winter |
| `A05_daily_cave_summary` | Daily median/quartiles per cave |
| `A06_detrend_df_sweep` | Spline-df sweep (residual SD, variance removed, KPSS passes) |
| `A07_ccf_summary_{raw,detrended}` | CCF peak lag and correlation per pair |
| `A08_coherence_summary_{raw,detrended}` | Peak coherency, period, phase delay per pair |
| `A09_coherence_spectra_detrended` | Coherency and delay at every frequency |
| `A10_te_summary_{raw,detrended}` | Effective TE each way, net, p-values |
| `A11_teopt_summary_{raw,detrended}` | Delay-optimized TE: u*, surrogate p, ETE at u* |
| `A12_teopt_profiles_detrended` | TE versus delay u per pair and direction |
| `A13_lagboot_{raw,detrended}` | Per-lag bootstrap interval of the CCF |
| `A14_variant_comparison` | Raw vs detrended for each statistic. Reads A07, A08, A10, A11, A13. Not published, but backs the Supplement's robustness text. |

### Publication tables

| Output | Built from |
|---|---|
| `MS_Table1_logger_inventory` | `data/logger_placement.csv` + A01 |
| `MS_Table2_winter_night_by_cave` | A02 (Nov–Feb rows, night columns) |
| `MS_Table3_winter_nightly_minimum` | A04 |
| `MS_Table4_winter_night_by_logger` | A03 (Nov–Feb rows, night columns) |
| `MS_Table5_coherence_raw` | A08 raw |
| `SM2_TableS1_day_by_cave` | A02 (day columns) |
| `SM2_TableS2_day_by_logger` | A03 (day columns) |
| `SM2_TableS3_coherence_complete` | A08 raw |
| `SI_TableS1_logger_inventory` | `data/logger_placement.csv` + A01 |
| `SI_TableS2_detrend_df_sweep` | A06 |
| `SI_TableS3_ccf_detrended` | A07 detrended |
| `SI_TableS4_coherence_detrended` | A08 detrended |
| `SI_TableS5_te_detrended` | A10 detrended |
| `SI_TableS6_teopt_detrended` | A11 detrended (`*` marks u* on a grid edge; typeset as a dagger) |

### Figures

| Output | Built from |
|---|---|
| `MS_Fig2_daily_median_by_cave` | A05 |
| `MS_Fig3_winter_nightly_minimum_boxplot` | A04 |
| `MS_Fig4_coherence_delay_matrix_raw` | A08 raw |
| `SI_FigS1_ccf_peaklag_matrix_detrended` | A07 detrended |
| `SI_FigS2/S3_lagboot_{Croc2,KHC}_detrended` | A13 detrended |
| `SI_FigS4/S5_coherence_delay_{Croc2,KHC}_detrended` | A09 |
| `SI_FigS6_coherence_delay_matrix_detrended` | A08 detrended |
| `SI_FigS7_te_matrix_detrended` | A10 detrended |
| `SI_FigS8/S9_teopt_profile_{Croc2,KHC}_detrended` | A12 |
| `SI_FigS10_teopt_matrix_detrended` | A11 detrended |
| `SI_FigS11_variant_comparison` | A07, A08, A10, A11, both variants |

MS Fig. 1 (map) and Fig. 5 (camera stills) are not code-generated. Neither are
the raw-data sheets of SM2.

## Definitions used here

- **Night** = 18:30–05:30 on the logger clock, as in the manuscript Methods. A
  night is dated by the evening it starts. A night or day counts as "above
  threshold" when at least one hourly reading is ≥ 24.25 °C.
- **Day** = [05:50, 18:00), the definition behind the published SM2 daytime
  tables. To change either window, edit `NIGHT_*_MIN` / `DAY_*_MIN` in
  `lib/pub_setup.R`.
- **Calendar dates** come from the local clock (`lubridate::date()`).
- **Timezone** is pinned to America/Phoenix, the zone that produced the
  published results, so outputs don't depend on the machine.

## What reproduces exactly

- All directional tables (CCF, coherence, transfer entropy, TE-optimal, lag
  bootstrap, raw and detrended) and the spline-df sweep match the analysis
  repo's workbooks cell for cell.
- SM2 Table S3 matches the published workbook exactly. SI Table S6 matches the
  Supplement.
- MS Table 1 "Last Logged" dates match.

## Discrepancies with the manuscript

Values below refer to `Wynne-etal_CaveCrocs.docx`. "Regenerated" means the
output of this code.

### 1. The manuscript uses four different night windows

| Where | Night window stated |
|---|---|
| Methods, Table 3 caption, Fig. 3 caption | 18:30–05:30 |
| Table 2 caption | 16:30–05:30 |
| Table 4 caption | 19:00–06:00 |
| Code that produced the published Tables 2 and 4 | 18:00–05:50 |

This code uses 18:30–05:30. The captions should be made to agree.

The day window has the same problem. Methods say 06:30–15:30. The published SM2
day tables, and this code, use 05:50–18:00.

### 2. Published tables the code does not reproduce, and why

- **MS Tables 2 and 4 (night statistics).** They change when the Methods night
  window is applied. Examples:

  | Cell | Published | Regenerated |
  |---|---|---|
  | Table 2, Croc 2 Dec, % nights | 93.55 | 90.32 |
  | Table 2, Croc 2 Feb, % nights | 94.44 | 100.00 |
  | Table 2, KHC Jan, median / range | 24.75 / 0.26 | 24.79 / 0.21 |
  | Table 2, KHC Feb, median / % / range | 24.45 / 94.44 / 0.43 | 24.41 / 100.00 / 0.34 |
  | Table 4, KHC L1 Feb, % nights | 27.78 | 12.50 |
  | Table 4, KHC L2 Dec, % nights | 87.10 | 83.87 |

  The February percentages also change because of the analysis window, below.

- **MS Table 3 holds daily minima, not nightly minima.** The published values
  are exact minima of whole calendar days (all 24 h), 1 Nov–18 Feb. The caption
  and Methods describe nightly minima. For example, KHC L1's published T_min of
  19.35 °C was recorded at 08:00. The nightly minimum is 19.60 °C. Every cell but
  Croc 2 L3's T_min changes (Croc 2 L2 T_min 23.46 → 23.59; median nightly
  minima rise by 0.03–0.18 °C). Either the table or its caption must change. MS Fig. 3 has
  the same issue, since it plots the same quantity.

- **MS Table 5 has three cells that differ from the R output** and from SM2
  Table S3:

  | Pair | Published | R output |
  |---|---|---|
  | Croc 2 L1–L3 | 0.69 | 0.68 |
  | Croc 2 L1–L4 | 0.85 | 0.84 (0.845 to three places) |
  | Croc 2 L2–L3 | 0.90 | 0.87 |

- **SM2 Tables S1 and S2 (day statistics).** The original pipeline built dates
  with `as.Date()`, which converts to UTC, so a "day" rolled over at 17:00
  local time. With local dates, February has 17 days instead of 18 and some
  December counts move by one.

- **The analysis window is not the one the Methods state.** The original loader
  compared local clock times with a window built in UTC. Under the timezone
  that produced the results, the effective window is 31 Jul 2022 17:00 →
  17 Feb 2023 17:00, not 1 Aug 2022 → 18 Feb 2023. February therefore has 16
  analysed nights, not 18. Every published result carries this. This code keeps
  the original window so the directional tables stay identical. To use the
  stated window, set this in `lib/pub_setup.R`:

  ```r
  WINDOW <- as.POSIXct(c("2022-08-01 00:00", "2023-02-18 23:59"), tz = "America/Phoenix")
  ```

  Every analysis output then changes slightly.

### 3. Numbers in the text that change with the regenerated tables

| Location | Manuscript says | Regenerated |
|---|---|---|
| Abstract; 3.1 | Median winter nighttime Tw 24.45–25.69 °C (KHC 24.45–25.69) | 24.41–25.69 °C |
| Abstract; 3.1; 3.2; 4.3 | Median nightly ranges 0.09–0.43 °C; KHC rises to 0.43 in Feb | 0.09–0.34 °C; KHC Feb 0.34 |
| 3.1 | >93% of winter nights above threshold | >90% (Croc 2 Dec 90.32%) |
| 3.1 | Croc 2 median nightly minima 24.66–24.79 °C | 24.84–24.86 °C |
| 3.1 | Croc 2 5th percentiles 24.00–24.17 °C | 23.97–24.21 °C |
| 3.1; 3.2 | KHC L1 lowest nighttime Tw 19.35 °C | 19.60 °C |
| 3.1 | KHC L1 5th percentile 22.02 °C; other stations 22.94–23.39 °C | 22.08 °C; 23.09–23.57 °C |
| 3.2 | Croc 2 stations: 83.33–100% of nights above threshold | 87.10–100% |
| 3.2 | KHC station medians 23.16–25.78 °C | 23.08–25.78 °C |
| 3.2 | KHC February nights above threshold 27.78–94.44% | 12.50–93.75% |

### 4. Claims that disagree with the published tables themselves

These are wrong whichever version of the tables is used.

- **3.2, "The lowest Tw occurred in February (19.35–21.88 °C)."** The published
  KHC T_min values span 19.35–22.78 °C, not 19.35–21.88. In the regenerated
  nightly minima, L2 and L4 reached their lows on 15 Jan, not in February.
- **3.3, "Strongest coupling occurred among L1–L4 (0.84–0.93)."** Pairs within
  Croc 2 L1–L4 include L1–L3 at 0.69 published (0.68 regenerated), so the range
  is 0.68–0.93.
- **3.3, "(0.392–0.82)."** Table 5 gives two decimals; this should read
  0.39–0.82.
- **4.2, "median winter nighttime temperatures differing by approximately 1 to
  2 °C among monitoring stations within each cave."** In Croc 2, station medians
  within a month differ by at most 0.13 °C (Table 4). KHC reaches 1.8 °C
  (1.9 regenerated), but only in February.
- **4.3, "median nighttime monthly ranges between 0.09 and 0.43 °C
  (Tables 2-3)."** Ranges appear only in Table 2.
- **Table 2 caption** describes "the percentage of daytime and nighttime
  observations exceeding the 24.25 °C." The table has no daytime column. The
  column is the percentage of *nights* with at least one hourly reading above
  threshold, as Results 3.1 says. The Table 4 caption says "nighttime
  observations" and has the same problem.
- **Table 5 caption** says "adjacent datalogger pairs." The table lists all 10
  pairs per cave.
- **Fig. 2 caption** says the envelope shows "the range of temperature values
  among monitoring sites." The original code, and this code, shade the
  25th–75th percentile of hourly Tw. The published image also has hand-added
  artwork.
- **Fig. 3 caption** says "nighttime water temperatures." The boxplots show
  nightly minima.

### 5. Statements the data file cannot confirm

- **Deployment dates.** The Methods say the Croc 2 loggers ran from 28 June 2022
  and the KHC loggers from 24 June 2022. The first records in
  `all_cave_temp_data_ext.xlsx` are 28–29 July 2022. Either the month is wrong
  or the data file omits June–July.
- **Logger failures.** Table 1 caption says Croc 2 L1 and L5 failed after about
  78 and 41 days. Counted from 1 Aug, the records give 77.7 and 40.4 days.
  Counted from their first records, 79.7 and 43.5 days.
