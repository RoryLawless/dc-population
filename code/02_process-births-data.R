# Process birth data downloaded from the CDC Wonder database -------------

# %% Setup ---------------------------------------------------------------

library(tidyverse)
library(conflicted)
library(fs)

# %% Load data -----------------------------------------------------------

path_list <- dir_ls("data/raw", regexp = "Natality")

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

data_list <- map(data_list, drop_na)

data_list <- map(data_list, \(x) {
	x |> mutate(across(everything(), \(x) parse_guess(x, guess_integer = )))
})

data_list <- map(data_list, \(x) {
	x |> rename(any_of(c(state = "state_of_residence")))
})

births_tbl <- list_rbind(data_list)

births_tbl <- births_tbl |>
	distinct()

births_tbl <- births_tbl |>
	mutate(
		status = recode_values(year_code, 1995:2024 ~ "final", 2025 ~ "provisional")
	)

# %% Save data ----------------------------------------------------------

write_csv(births_tbl, "data/processed/dc-births-1995-2025.csv")
