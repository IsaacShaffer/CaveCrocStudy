# =============================================================================
# study_data.R -- loading and shaping the hourly data (shared by tables and figure inputs)
# =============================================================================

# Hourly water temperature inside the analysis window, one row per logger-hour,
# with the roster columns, the threshold flag, the local clock date and the
# minute of the day.
load_study_hourly <- function() {
  purrr::map_dfr(readxl::excel_sheets(DATA_FILE), ~ readxl::read_excel(DATA_FILE, sheet = .x)) %>%
    mutate(date_time = openxlsx::convertToDateTime(Date + Time)) %>%
    # The window bounds are parsed as UTC midnights and compared with local
    # clock times, which shifts the window by the UTC offset. Kept as in the
    # published analysis; see the timezone note in pub_setup.R.
    filter(date_time >= as_datetime(WINDOW[1]), date_time <= as_datetime(WINDOW[2])) %>%
    left_join(LOGGERS, by = c(Location = "Serial")) %>%
    mutate(above_threshold = Temperature >= THRESHOLD,
           # lubridate::date() keeps the local clock date. as.Date() would
           # convert to UTC and roll the date over at 17:00 local time.
           clock_date = lubridate::date(date_time),
           tod_min    = hour(date_time) * 60 + minute(date_time))
}

# Tag each reading as day, night or neither. A night runs 18:30-05:30 and is
# dated by the evening it starts on, so readings after midnight belong to the
# previous date: the night of 1 Nov is 1 Nov 18:30 to 2 Nov 05:30.
diel_tagged <- function() {
  load_study_hourly() %>%
    mutate(is_day     = tod_min >= DAY_START_MIN & tod_min < DAY_END_MIN,
           is_night   = tod_min >= NIGHT_START_MIN | tod_min <= NIGHT_END_MIN,
           night_date = if_else(tod_min >= NIGHT_START_MIN, clock_date, clock_date - 1))
}

# Row indices of the longest run of consecutive readings whose spacing stays
# within `tol` of `spacing`. `gaps` are the n-1 spacings between n readings.
longest_regular_run <- function(gaps, spacing = 1, tol = 0) {
  n <- length(gaps) + 1L
  is_break <- abs(gaps - spacing) > tol
  if (!any(is_break)) return(seq_len(n))
  breaks  <- c(0L, which(is_break), n)
  longest <- which.max(diff(breaks))
  (breaks[longest] + 1L):breaks[longest + 1L]
}

# Remove the slow seasonal drift and the 24 h cycle from one series: residuals of
# a natural cubic spline in time (SPLINE_DF) plus one sine/cosine of PERIOD.
# Lag, coherence and TE methods assume stationary series; without this, the
# shared seasonal cooling and the shared daily cycle dominate every pair and
# hide station-to-station timing. The raw variant skips this step, so the two
# variants show which results depend on it.
harmonic_detrend <- function(x) {
  t <- seq_along(x)
  residuals(lm(x ~ splines::ns(t, df = SPLINE_DF) + sin(2 * pi * t / PERIOD) + cos(2 * pi * t / PERIOD)))
}

# Every within-cave pair, ready for a directional analysis. Each pair is cut to
# the longest stretch where both loggers recorded every hour (gaps within
# 6 min of 1 h), because lag, spectral and TE methods need evenly spaced,
# simultaneous samples. Pairs with fewer than MIN_OVERLAP such hours are
# dropped. `stationarize` is applied to each series after trimming: identity
# for the raw variant, harmonic_detrend for the detrended one.
prepare_pairs <- function(stationarize) {
  hourly <- load_study_hourly()
  pairs <- lapply(PAIRS, function(p) {
    w <- hourly %>%
      filter(Logger_Name %in% c(p$a, p$b)) %>%
      select(date_time, Logger_Name, Temperature) %>%
      pivot_wider(names_from = Logger_Name, values_from = Temperature) %>%
      arrange(date_time) %>%
      filter(complete.cases(.))
    w <- w[longest_regular_run(as.numeric(diff(w$date_time), units = "hours"), spacing = 1, tol = 0.1), ]
    if (nrow(w) < MIN_OVERLAP) return(NULL)
    list(cave = p$cave,
         pair = paste0(sub(".*-Logger", "L", p$a), "-", sub(".*-Logger", "L", p$b)),
         n_overlap = nrow(w),
         a = stationarize(w[[p$a]]),
         b = stationarize(w[[p$b]]))
  })
  Filter(Negate(is.null), pairs)
}

# First and last timestamp, and reading count, of every logger over the WHOLE
# deployment, not the analysis window: Table 1 reports when each logger
# stopped, which shows that Croc 2 L1 and L5 failed before winter and so
# cannot contribute to winter results. Used by MS Table 1 and SI Table S1.
logger_record_span <- function() {
  purrr::map_dfr(readxl::excel_sheets(DATA_FILE), function(sheet) {
    d  <- readxl::read_excel(DATA_FILE, sheet = sheet)
    dt <- openxlsx::convertToDateTime(d$Date + d$Time)
    tibble(Serial       = d$Location[1],
           first_logged = format(min(dt), "%Y-%m-%d %H:%M"),
           last_logged  = format(max(dt), "%Y-%m-%d %H:%M"),
           n_obs        = nrow(d))
  }) %>%
    inner_join(LOGGERS, by = "Serial") %>%
    transmute(Cave, Logger, Logger_Name, Serial = as.character(Serial),
              first_logged, last_logged, n_obs) %>%
    arrange(Cave, Logger)
}

# The minimum water temperature of each logger-night, for winter nights
# (starting 1 Nov 2022 through 18 Feb 2023). Medians describe typical
# conditions, but a crocodile's limit is set by the coldest hours, so each
# night is reduced to its coldest reading per station. Used by MS Table 3
# (percentiles of these minima) and MS Fig. 3 (their distribution).
winter_nightly_minima <- function() {
  diel_tagged() %>%
    filter(is_night, night_date >= WINTER[1], night_date <= WINTER[2]) %>%
    group_by(Cave, Logger, Logger_Name, night_date) %>%
    summarise(n_obs = n(), night_min = min(Temperature), .groups = "drop") %>%
    arrange(Cave, Logger, night_date)
}
