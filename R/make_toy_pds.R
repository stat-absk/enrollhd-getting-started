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

# ---- HDClarity ---------------------------------------------------------------
#
# The same idea for the HDClarity PDS, which nests on Enroll-HD: three
# participants, a few visit packages, and the conventions that differ from
# the Enroll-HD files:
#
#   * visdy is days since the participant's FIRST HDClarity screening, so the
#     Enroll-HD source visit of cycle 1 has a negative day
#   * cycle numbers the visit packages; seq numbers every visit chronologically
#   * participation has one row per participant x cycle, with visit arrays and
#     a samples array (vis1smpl ...)
#   * hdcat is set at screenings 1 and 5 and carried forward, so a premanifest
#     participant can show DCL 4 at a later sampling visit
#   * a package without CSF is not released, which leaves a gap in cycle
#
# Nothing here is calibrated; the numbers are illustrative only.

make_toy_hdclarity <- function() {
  profile <- tribble(
    ~subjid,      ~caghigh, ~caglow, ~sex, ~region,   ~fhx, ~hdcsf, ~proteomic,
    "R000000001", "42",     "17",    "f",  "Europe",  1,    "no",   "yes",
    "R000000003", "17",     "15",    "m",  "Europe",  0,    "no",   "no",
    "R000000004", "40",     "18",    "f",  "Northern America", 1, "yes", "yes"
  )

  visits <- tribble(
    ~subjid, ~cycle, ~seq, ~studyid, ~visit, ~visdy, ~age, ~hdcat, ~dbs, ~motscore, ~diagconf, ~tfcscore, ~lbres1, ~csfpdy,
    # a manifest carrier: two packages, a repeat sampling in cycle 1, a gap at cycle 2
    "R000000001", 1, 1, "ENR", "Follow Up",   -41, 52, NA,      NA, 24, 4, 11, NA, NA,
    "R000000001", 1, 2, "CLR", "Screening",     0, 52,  3, 340.86, NA, NA, NA, 1, NA,
    "R000000001", 1, 3, "CLR", "Sampling",     14, 52,  3, 340.86, 27, 4, NA, NA, 14,
    "R000000001", 1, 4, "CLR", "RPT Sampling", 49, 52,  3, 340.86, 25, 4, NA, NA, 49,
    "R000000001", 3, 5, "CLR", "Screening",   735, 54,  3, 353.86, 31, 4, 10, 2, NA,   # no Enroll-HD visit inside 90 days: forms done here
    "R000000001", 3, 6, "CLR", "Sampling",    752, 54,  3, 353.86, 30, 4, NA, NA, 752,
    # a healthy control: one package
    "R000000003", 1, 1, "ENR", "Baseline",    -12, 38, NA,      NA,  1, 0, 13, NA, NA,
    "R000000003", 1, 2, "CLR", "Screening",     0, 38,  6,     NA, NA, NA, NA, 1, NA,
    "R000000003", 1, 3, "CLR", "Sampling",      7, 38,  6,     NA,  0, 0, NA, NA, 7,
    # early premanifest at screening 1, DCL 4 by cycle 2: hdcat is carried forward
    "R000000004", 1, 1, "ENR", "Follow Up",   -20, 31, NA,      NA,  6, 2, 13, NA, NA,
    "R000000004", 1, 2, "CLR", "Screening",     0, 31,  1, 139.50, NA, NA, NA, 1, NA,
    "R000000004", 1, 3, "CLR", "Sampling",     21, 31,  1, 139.50,  8, 3, NA, NA, 21,
    "R000000004", 2, 4, "ENR", "Follow Up",   340, 32, NA,      NA, 15, 4, 13, NA, NA,
    "R000000004", 2, 5, "CLR", "Screening",   371, 32,  1, 144.00, NA, NA, NA, 1, NA,
    "R000000004", 2, 6, "CLR", "Sampling",    380, 32,  1, 144.00, 16, 4, NA, NA, 380
  ) |>
    mutate(study = if_else(studyid == "ENR", "Enroll-HD", "HDClarity"),
           capscore = round(age * (parse_number(profile$caghigh[match(subjid, profile$subjid)]) - 30) / 6.49, 1),
           capscore = if_else(subjid == "R000000003", NA_real_, capscore))

  participation <- tribble(
    ~subjid, ~cycle, ~subjstat, ~age, ~hdcat, ~visitcnt, ~visit1, ~visit2, ~visit3, ~visit4, ~vis1dy, ~vis2dy, ~vis3dy, ~vis4dy, ~vis1smpl, ~vis2smpl, ~vis3smpl, ~vis4smpl,
    "R000000001", 1, "enrolled", 52, 3, 4, "ENR/FUP", "SCR", "BS", "BS2", -41, 0, 14, 49, NA, NA, "Plasma, Serum", "CSF, Plasma, Serum",
    "R000000001", 3, "enrolled", 54, 3, 2, "SCR", "BS", NA, NA, 735, 752, NA, NA, NA, "CSF, Plasma, Serum", NA, NA,
    "R000000003", 1, "enrolled", 38, 6, 3, "ENR/BL", "SCR", "BS", NA, -12, 0, 7, NA, NA, NA, "CSF, Plasma, Serum", NA,
    "R000000004", 1, "enrolled", 31, 1, 3, "ENR/FUP", "SCR", "BS", NA, -20, 0, 21, NA, NA, NA, "CSF, Plasma, Serum", NA,
    "R000000004", 2, "enrolled", 32, 1, 3, "ENR/FUP", "SCR", "BS", NA, 340, 371, 380, NA, NA, NA, "CSF, Plasma, Serum", NA
  )
  # the cycle-1 lumbar puncture of R000000001 failed; the repeat supplied the CSF
  visits <- visits |> mutate(csfpdy = if_else(subjid == "R000000001" & visit == "Sampling" & cycle == 1, NA_real_, csfpdy))

  csfquality <- tribble(
    ~subjid, ~cycle, ~studyid, ~visit, ~visdy, ~row, ~erycnt1, ~erycnt2, ~erycnt3, ~eryflag, ~leukcnt1, ~leukcnt2, ~leukcnt3, ~leukflag,
    "R000000001", 1, "CLR", "RPT Sampling",  49, 1,    3,    5,    4, 0, 1, 0, 2, 0,
    "R000000001", 3, "CLR", "Sampling",     752, 1, 1450, 1380, 1520, 1, 2, 1, 2, 0,
    "R000000003", 1, "CLR", "Sampling",       7, 1,    0,    0,    1, 0, 0, 1, 0, 0,
    "R000000004", 1, "CLR", "Sampling",      21, 1,   12,    9,   14, 0, 6, 5, 7, 1,
    "R000000004", 2, "CLR", "Sampling",     380, 1,    2,    1,    2, 0, 1, 2, 1, 0
  )

  list(profile = profile, participation = participation, visits = visits, csfquality = csfquality)
}
