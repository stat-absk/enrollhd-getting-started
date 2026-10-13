# HDClarity: a first look

A 20-minute reveal.js deck for statisticians opening an HDClarity release for the first time.
It covers the data, the cohort by HDClarity category, the composite UHDRS (cUHDRS), CSF sample
quality, and Olink Explore 3072 proteomics in CSF and serum. Each analysis slide gives:

- the question it answers;
- the **reason** for the analysis;
- the figure or table;
- a result line computed from the data;
- speaker notes with the method (press `S` in the browser).

**View the slides:** download [`hdclarity_slides_synthetic.html`](hdclarity_slides_synthetic.html)
and open it in a browser. It is one self-contained file.

## Disclaimer

The deck is built **only from publicly available information**: the HDClarity documents on the
Enroll-HD website (protocol, lab manual, PDS4 data dictionary, dataset-structure guide, PDS
overviews) and published summaries.

The rendered copy here was run on a **synthetic** HDClarity release, simulated from those
public documents. **No real participant data are used, shown or summarised anywhere in the
slides or in this repository.** No number in the deck is a finding about Huntington's disease.

## Rendering

The slides recompute everything from an HDClarity release at render time. No data are
included here, so put a release in `data/` (it is git-ignored) or point the `params` at the
top of `hdclarity_slides.qmd` to where it lives:

| Setting | What it is |
|---|---|
| `data_dir` | Folder with the nine PDS4 files (`profile.csv`, `visits.csv`, …) |
| `olink_csf`, `olink_serum` | Olink long-format files, one per matrix; `""` skips a matrix |
| `olink_manifest` | Sample → `subjid` and visit day; only needed if the Olink files lack them |
| `data_label` | `"synthetic"` or `"real"`; `"real"` puts the data-use warning on the slides |
| `min_cell` | Smallest count shown in a table (default 5) |

To render:

```bash
quarto render hdclarity_slides.qmd
```

Requires R with `tidyverse`, `vroom`, `gt`, `patchwork`, `ggrepel` and `broom`; `ragg` is
optional for sharper figures.

**A copy rendered on real HDClarity data is governed by the data use agreement and must not be
committed or published.** The default output name, `hdclarity_slides.html`, is git-ignored for
that reason. Only the synthetic render is kept, under its own name.
