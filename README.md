# Getting started with Enroll-HD data

A tutorial slide deck for statisticians who are about to open an Enroll-HD periodic dataset
(PDS) for the first time. Fifty reveal.js slides built with Quarto and R:

1. Huntington's disease in five minutes: CAG, penetrance, onset, CAP
2. The Enroll-HD platform and its periodic datasets
3. Anatomy of a PDS: the eleven files, keys, studies and visits
4. Loading and merging with the tidyverse
5. De-identification conventions and the two kinds of missing
6. Disease definitions and derived scores
7. Special characteristics of HD data: floors, ceilings, behaviour, follow-up
8. Age, CAG and time in cross-sectional, longitudinal and survival models
9. Coded therapies and comorbidities
10. Data quality and a pre-analysis checklist

**View the slides:** <https://stat-absk.github.io/slides/enrollhd-getting-started.html>

## No participant data

Every code chunk runs on small illustrative tables produced by [`R/make_toy_pds.R`](R/make_toy_pds.R).
They are shaped like the real PDS files (`profile`, `participation`, `enroll`, `pharmacotx`) and
reproduce the conventions that trip people up: recoded IDs, day offsets instead of dates,
`seq` ordering, aggregated values arriving as text (`">70"`, `"<18"`), the 9996 to 9999 missing
codes, a duplicate prescription row and a zero-day duration from partial-date imputation.
Nothing in them is calibrated to real data.

## Rendering

```bash
quarto render enrollhd-getting-started.qmd
```

Requires R with `tidyverse`, `gt`, `scales`, `here` and `knitr`. The modelling slides show code
for `lme4`, `broom.mixed` and `survival` without executing it, so those packages are optional.
The deck is rendered as a single self-contained HTML file.

## Sources

Built from the Enroll-HD documentation set (protocol, data dictionary, annotated CRFs,
data-collection guidelines, PDS overview, "understand and interpret" and coding-systems guides)
and the *Analyzing Data* articles at <https://www.enroll-hd.org/for-researchers/analyzing-data/>.
Figures redrawn from those articles are marked approximate and are not for analysis.

## Style

R code follows tidy design principles and the tidyverse: pipelines that read top to bottom,
small single-purpose functions, names that say what and comments that say why. Corrections and
additions are welcome as issues or pull requests.
