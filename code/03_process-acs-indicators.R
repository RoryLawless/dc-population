# %% Packages ====
library(here)
library(tidyverse)
library(conflicted)
library(urbnindicators)
library(sf)

conflicts_prefer(dplyr::filter)

# %% Fetch ACS tract indicators for DC (2024) ====
# urbnindicators::compile_acs_data() — https://github.com/UrbanInstitute/urbnindicators
# Source: ACS 5-year estimates, 2024 vintage, Census tract geography
# Requires: CENSUS_API_KEY set in .Renviron (https://api.census.gov/data/key_signup.html)
dc_acs_raw <- compile_acs_data(
	years = 2024,
	geography = "tract",
	states = "DC",
	spatial = TRUE
)

# %% Select indicators for the dashboard ====
dc_acs <- dc_acs_raw |>
	select(
		GEOID,
		NAME,
		race_personofcolor_percent,
		median_household_income_universe_allraces,
		federal_poverty_limit_below_allraces_percent,
		tenure_renter_occupied_percent,
		geometry
	)

# %% Save ====
# Saved as RDS to preserve the sf geometry column
out_path <- here("data", "processed", "dc-acs-tracts-2024.rds")
saveRDS(dc_acs, out_path)
message("Saved: ", out_path)

# Copy to Shiny app data directory so the deployed app can read it offline
app_path <- here("dc-population-explorer", "data", "dc-acs-tracts-2024.rds")
file.copy(out_path, app_path, overwrite = TRUE)
message("Copied to: ", app_path)
