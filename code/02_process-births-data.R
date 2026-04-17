# Process birth data downloaded from the CDC Wonder database -------------

# %% Setup ---------------------------------------------------------------

library(tidyverse)
library(conflicted)
library(fs)
library(here)
library(glue)

conflicts_prefer(dplyr::filter)

# %% Load data -----------------------------------------------------------
# Citation: Centers for Disease Control and Prevention, National Center for
# Health Statistics (NCHS). National Vital Statistics System, Natality on CDC
# WONDER Online Database. Data are from the Natality Records 1995-2024, as
# compiled from data provided by the 57 vital statistics jurisdictions through
# the Vital Statistics Cooperative Program. <https://wonder.cdc.gov/natality.html>

path_list <- dir_ls(here("data/raw"), regexp = "Natality")

data_list <- map(path_list, \(x) {
	read_csv(
		x,
		name_repair = str_to_snake,
		col_types = cols_only(
			state_of_residence = col_character(),
			state = col_character(),
			year_code = col_character(),
			births = col_character()
		)
	)
})

# %% Process data --------------------------------------------------------

data_list <- map(data_list, \(x) {
	x |>
		drop_na() |>
		mutate(across(everything(), \(col) {
			parse_guess(col, guess_integer = TRUE)
		})) |>
		rename(any_of(c(state = "state_of_residence")))
})

births_tbl <- list_rbind(data_list) |>
	distinct() |>
	mutate(
		status = recode_values(year_code, 1995:2024 ~ "final", 2025 ~ "provisional")
	)

births_tbl <- births_tbl |>
	rename(year = year_code)

# %% Save data ----------------------------------------------------------

year_range <- range(births_tbl$year)
write_csv(
	births_tbl,
	here(glue("data/processed/dc-births-{year_range[1]}-{year_range[2]}.csv"))
)
