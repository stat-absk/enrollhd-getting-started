# Getting started with Enroll-HD data

A tutorial slide deck for statisticians who are about to open an Enroll-HD periodic dataset
(PDS) for the first time. Sixty reveal.js slides built with Quarto and R:

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
11. HDClarity, the CSF and blood study nested in Enroll-HD, and simulated releases for testing code

**View the slides:** <https://stat-absk.github.io/slides/enrollhd-getting-started.html>

## Disclaimer

This deck is built **only from publicly available information**: the Enroll-HD documentation
published for researchers, the *Analyzing Data* articles at enroll-hd.org, and the public
HDClarity documents (protocol, lab manual, PDS4 dictionary, dataset-structure guide, PDS overviews). **No Enroll-HD
participant data are used, shown or summarised anywhere in the slides or in this repository.**
All printed tables come from the illustrative generator described below; all plots are synthetic
or approximate redrawings of figures already published on enroll-hd.org and are labelled as such.
Nothing here replaces the official documentation or the data use agreement that governs access
to a periodic dataset.

## No participant data

Every code chunk runs on small illustrative tables produced by [`R/make_toy_pds.R`](R/make_toy_pds.R).
They are shaped like the real PDS files (`profile`, `participation`, `enroll`, `pharmacotx`) and
reproduce the conventions that trip people up: recoded IDs, day offsets instead of dates,
`seq` ordering, aggregated values arriving as text (`">70"`, `"<18"`), the 9996 to 9999 missing
codes, a duplicate prescription row and a zero-day duration from partial-date imputation.
Nothing in them is calibrated to real data. `make_toy_hdclarity()` in the same file does the
same for the HDClarity PDS: three participants, five visit packages, the negative-day source
visit, the samples array, a failed lumbar puncture, a missing cycle and a carried `hdcat`.

## Rendering

```bash
quarto render enrollhd-getting-started.qmd
```

Requires R with `tidyverse`, `gt`, `scales`, `here` and `knitr`. The modelling slides show code
for `lme4`, `broom.mixed` and `survival` without executing it, so those packages are optional.
The deck is rendered as a single self-contained HTML file. Its look comes from
`signature-reveal.scss`, the reveal.js form of the design system used across
<https://stat-absk.github.io>, with `custom.scss` holding the few deck-specific rules.

## Sources

Built from the Enroll-HD documentation set (protocol, data dictionary, annotated CRFs,
data-collection guidelines, PDS overview, "understand and interpret" and coding-systems guides)
and the *Analyzing Data* articles at <https://www.enroll-hd.org/for-researchers/analyzing-data/>.
Figures redrawn from those articles are marked approximate and are not for analysis.

## Style

R code follows tidy design principles and the tidyverse: pipelines that read top to bottom,
small single-purpose functions, names that say what and comments that say why. Corrections and
additions are welcome as issues or pull requests.
