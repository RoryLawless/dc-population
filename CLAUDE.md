# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project overview

Ad-hoc R data analysis pipeline for District of Columbia population and birth statistics. Raw files from the US Census Bureau and CDC Wonder are normalized by numbered R scripts into tidy CSVs, then analyzed and visualized in notebooks. This is not an R package — there is no `DESCRIPTION`, `NAMESPACE`, or test suite.

## Pipeline architecture

```
data/raw/  →  code/NN_process-*.R  →  data/processed/  ┬→  notebooks/*.qmd  →  outputs/*.png
                                                       └→  dc-population-explorer/app.R    (interactive dashboard)
```

- **`code/`** — Numbered scripts (`01_`, `02_`). The prefix encodes run order; there is no build system tying them together. Each reads multiple heterogeneous sources and writes one tidy CSV.
  - `01_process-population-data.R` stitches DC population 1990–2025 from **four** sources because each Census decade is published differently: a PDF table (1990s), a CSV with a dot-prefixed state label (2000s), an XLSX (2010s), and the live `tidycensus::get_estimates()` API (2020s). Adding new years usually means appending a fifth block in the same style.
  - `02_process-births-data.R` globs `data/raw/Natality*.csv`, map-reads them with unified column types, then row-binds + dedupes. Any year ≥ 2025 is tagged `status = "provisional"`; finalized years are `"final"`.
- **`data/raw/`** is source-of-truth and never mutated by scripts. When files arrive with spaces in names (e.g. `Natality, 1995-2002.csv`), leave them — the globs handle it.
- **`notebooks/`** — Analysis + plotting. `dc-births.ipynb` uses `fable`/`tsibble`/`feasts` for time-series forecasting; `census-data.ipynb` pairs a population trend plot with a tract-level Gini choropleth via `urbnindicators`.
- **`dc-population-explorer/app.R`** — Two-tab bslib dashboard (`page_navbar`: Population, Births) with a single year-range slider in the sidebar driving reactives on both tabs. **Palette is a single source of truth**: the named vector `palette_dc` (lines ~53-60) feeds both `bs_theme()` slots (`bg`/`fg`/`primary`/`secondary`/`info`/`success`) and every ggplot `geom_*(color = ...)` call — if you add a color, add it there and wire it into both consumers. Plot theming is a plain ggplot `theme_dc_plot` applied globally via `theme_set()`; we deliberately do **not** use `thematic::thematic_shiny()` because it is incompatible with ggplot2 4.x + `geom_sf` ([rstudio/thematic#165](https://github.com/rstudio/thematic/issues/165)). Shared `summarize_series()` helper computes the value-box "latest" and percent-change strings off filtered data — keep its contract consistent so the two tabs' value boxes remain comparable.

## Conventions

- **Paths**: Always `here::here("...")` in scripts so they work regardless of RStudio's working directory. Notebooks assume project root as CWD and use bare relative paths.
- **Native pipe** `|>`, never `%>%`.
- **Tidyverse conflicts**: `library(conflicted)` + `conflicts_prefer(dplyr::filter)` near the top of anything that loads `tidyverse`.
- **Cell markers**: Scripts use `# %% Section ====` markers so they can be run chunk-by-chunk in RStudio/Positron.
- **Data citations**: Every data-loading block has a comment naming the Census table ID / package and linking the source URL. Preserve this when adding sources — it is the only provenance record.

## Formatting and linting

- **Air** owns formatting (`air.toml` → tabs, LF line endings). Run via Positron's formatter or `air format .` at the CLI.
- **lintr** owns semantic checks (`.lintr`). `whitespace_linter` and `indentation_linter` are intentionally `NULL` because Air handles those — do not re-enable them.

## Running things

No test suite. Typical loops:

- **Rebuild processed data**: in R, `source(here::here("code/01_process-population-data.R"))` then `source(here::here("code/02_process-births-data.R"))`. Scripts are idempotent — they overwrite `data/processed/*.csv`.
- **Run the dashboard**: `shiny::runApp("dc-population-explorer")` from the project root. Offline-safe — reads only the two processed CSVs.
- **Notebooks**: executed interactively (Positron/Jupyter with an R kernel). Checked-in `.ipynb` files contain the last-rendered outputs.

## Non-obvious dependencies

- `tidycensus` requires a Census API key in `CENSUS_API_KEY` (typically set in `.Renviron`, which is gitignored).
- `urbnindicators` is an Urban Institute package, **not on CRAN** — install from GitHub. Used only by `notebooks/census-data.ipynb` for `compile_acs_data()` (which needs `CENSUS_API_KEY`) and theme helpers (`set_theme`, `theme_sub_panel`, `theme_sub_axis`). Not a Shiny-app dependency.
- `ragg` + `systemfonts` power PNG output; `theme_rory` references **Lato** and **Playfair Display** — these must be installed at the OS level or plots will fall back silently.

## Notebook plotting helpers

Defined inline at the top of each notebook (not extracted to a shared file):

- `rlsave(...)` — `ggsave` wrapper that writes a retina-DPI PNG via `ragg::agg_png()` at a golden-ratio aspect (1000 × 1000/φ px, `scale = 2`). Use this instead of `ggsave` directly so outputs stay consistent.
- `theme_rory` — extends `theme_minimal` with a custom paper/ink/accent palette (`#fbf5f5` / `#070a0c` / `#b46466`) and the fonts above. Applied globally via `set_theme(theme_rory)`.
