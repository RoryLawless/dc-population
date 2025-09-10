# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a DC population analysis project that uses Quarto and R to analyze population data from various time periods. The project combines historical census data from multiple sources to track DC's population trends.

## Development Commands

- **Render Quarto document**: `quarto render notebooks/census-data.qmd`
- **Preview Quarto document**: `quarto preview notebooks/census-data.qmd`
- **Run R interactively**: `R` (then source the code blocks as needed)

## Project Structure

- `notebooks/census-data.qmd` - Main Quarto document containing R analysis code
- `notebooks/` - Contains analysis notebooks and documents
- `data/` - Contains source data files:
  - `co-est2001-12-00.pdf` - Historical population data (1999 era)
  - `st-est00int-01.csv` - Population estimates 2000-2009
  - `nst-est2020int-pop.xlsx` - Population estimates 2010-2019
  - Census API data retrieved programmatically for 2024 estimates

## R Dependencies

The project uses these R libraries:
- `tidyverse` - Data manipulation and analysis
- `tidycensus` - Interface to Census Bureau APIs
- `readxl` - Reading Excel files
- `pdftools` - Reading PDF files

## Data Analysis Pattern

The code follows a pattern of:
1. Loading different data sources (PDF, CSV, Excel, API)
2. Filtering for District of Columbia data
3. Standardizing column names and data structure
4. Combining data across time periods
