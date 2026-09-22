# make_toy_pds.R
#
# Small, hand-sized tables shaped like the Enroll-HD periodic dataset (PDS).
# They exist so that the tutorial slides can run real tidyverse code without
# any real participant data. Every convention that trips people up in the
# real files is reproduced on purpose:
#
#   * subjid is a recoded ID of the form R + 9 digits
#   * no calendar dates: visdy is days since the Enroll-HD baseline (0 at baseline)
#   * seq numbers visits within subjid x studyid, chronologically
#   * aggregated values arrive as text ("<18", ">70"), so those columns are character
#   * user-defined missing codes 9996 to 9999 sit inside otherwise numeric columns
#   * system-missing values are blank (NA)
#
# Nothing here is calibrated; the numbers are illustrative only.

library(tidyverse)

make_toy_pds <- function(n_participants = 8, seed = 2026) {
  set.seed(seed)

  # ---- participant-level: profile ------------------------------------------
  profile <- tibble(
    subjid  = sprintf("R%09d", seq_len(n_participants)),
    sex     = sample(c("f", "m"), n_participants, replace = TRUE),
    region  = sample(c("Europe", "Northern America", "Australasia"),
                     n_participants, replace = TRUE, prob = c(.6, .3, .1)),
    # 36+ repeats = HD gene expansion carrier; keep as character because the
    # real file aggregates large values to ">70"
    caghigh = c("42", "44", "17", "40", "47", "19", "39", ">70")[seq_len(n_participants)],
    caglow  = c("17", "19", "15", "18", "20", "16", "17", ">28")[seq_len(n_participants)],
    # HDCC: age at clinical HD diagnosis (blank for controls and undiagnosed)
    hddiagn = c(48, 41, NA, NA, 35, NA, NA, 30)[seq_len(n_participants)],
    momhd   = c(1, 1, 0, 1, 9999, 0, 1, 1)[seq_len(n_participants)]
  )

  # ---- study-level: participation (one row per participant x study) --------
  participation <- profile |>
    select(subjid) |>
    mutate(
      studyid  = "ENR",
      study    = "Enroll-HD",
      hdcat_0  = c(3, 3, 5, 2, 3, 4, 2, 3)[seq_len(n_participants)],
      hdcat_l  = c(3, 3, 5, 3, 3, 4, 2, 3)[seq_len(n_participants)],
      age_0    = c("52", "45", "38", "31", "40", "60", "27", "<18")[seq_len(n_participants)],
      subjstat = c("enrolled", "enrolled", "withdrawn", "enrolled",
                   "completed", "enrolled", "enrolled", "enrolled")[seq_len(n_participants)],
      visitnum = c(3, 2, 1, 3, 2, 2, 3, 1)[seq_len(n_participants)]
    )

  # ---- visit-level: enroll (one row per Enroll-HD visit) -------------------
  visit_days <- participation |>
    select(subjid, visitnum) |>
    mutate(seq = map(visitnum, seq_len)) |>
    unnest(seq) |>
    mutate(
      visit = if_else(seq == 1, "Baseline", "Follow Up"),
      # annual visits with realistic slippage; baseline is day 0 by definition
      visdy = if_else(seq == 1, 0L,
                      as.integer(365 * (seq - 1) + round(rnorm(n(), 10, 25))))
    ) |>
    select(-visitnum)

  enroll <- visit_days |>
    left_join(participation |> select(subjid, hdcat_0), by = "subjid") |>
    group_by(subjid) |>
    mutate(
      studyid  = "ENR",
      hdcat    = if_else(subjid == "R000000004" & seq == 3, 3, hdcat_0),
      # total motor score: carriers progress, controls stay near zero
      motscore = case_when(
        hdcat_0 %in% c(4, 5) ~ pmax(0, round(rnorm(n(), 1, 1.5))),
        hdcat_0 == 2         ~ pmax(0, round(rnorm(n(), 3 + 2 * seq, 2))),
        TRUE                 ~ pmin(124, round(rnorm(n(), 20 + 5 * seq, 4)))
      ),
      diagconf = case_when(
        hdcat_0 %in% c(4, 5) ~ 0,
        hdcat == 3           ~ 4,
        TRUE                 ~ pmin(3, seq)
      ),
      tfcscore = case_when(
        hdcat_0 %in% c(2, 4, 5) ~ 13,
        TRUE                    ~ pmax(0, 12 - seq - (subjid == "R000000005") * 4)
      ),
      sdmt1 = round(rnorm(n(), if_else(hdcat_0 == 3, 32, 50), 6)),
      # one visit where the participant refused the cognitive battery:
      # user-defined missing code instead of a blank
      sdmt1 = if_else(subjid == "R000000002" & seq == 2, 9998, sdmt1),
      # age is an integer at each visit, aggregated below 18
      age = as.character(as.integer(age_from(subjid, seq)))
    ) |>
    ungroup() |>
    mutate(age = if_else(subjid == "R000000008", "<18", age)) |>
    select(subjid, studyid, seq, visit, visdy, age, hdcat,
           motscore, diagconf, tfcscore, sdmt1)

  # ---- participant-level, repeating rows: pharmacotx -----------------------
  pharmacotx <- tribble(
    ~subjid,      ~seq, ~cmtrt__modify,  ~cmtrt__decod, ~cmtrt__atc,      ~cmindc__modify, ~cmstdy, ~cmendy, ~cmenrf,
    "R000000001",    1, "Tetrabenazine", "RX000000101", "N07XX06",        "Chorea",          -400,      NA,       1,
    "R000000001",    2, "Sertraline",    "RX000000202", "N06AB06",        "Depression",      -120,     380,       0,
    "R000000002",    1, "Citalopram",    "RX000000203", "N06AB04",        "Depression",       -15,     -15,       0,
    "R000000002",    2, "Citalopram",    "RX000000203", "N06AB04",        "Depression",       -15,     -15,       0,
    "R000000004",    1, "Ibuprofen",     "RX000000301", "M01AE01,C01EB16","Headache",         200,     190,       0,
    "R000000005",    1, "Olanzapine",    "RX000000401", "N05AH03",        "Irritability",    -800,      NA,       1,
    "R000000006",    1, "Atorvastatin",  "RX000000501", "C10AA05",        "Hyperlipidaemia", -1500,     NA,       1
  )

  list(
    profile       = profile,
    participation = participation,
    enroll        = enroll,
    pharmacotx    = pharmacotx
  )
}

# Age at each visit for the toy cohort: baseline age plus elapsed years.
# Kept separate so the intent (age is derived, never stored as a date) is clear.
age_from <- function(subjid, seq) {
  baseline_age <- c(52, 45, 38, 31, 40, 60, 27, 17)
  id <- as.integer(str_remove(subjid, "^R"))
  baseline_age[id] + (seq - 1)
}
