# Extract DC federal poverty data for Datawrapper visualization ----------

# Setup ------------------------------------------------------------------

library(data.table)
library(urbnindicators)

# Call urbnindicators compile_acs_data -----------------------------------
# Returns a tibble with all columns and 206 rows corresponding to DC census
# tracts

dc_indicators <- compile_acs_data(
	years = 2024,
	geography = "tract",
	states = "DC"
)

# Cleanup and other prep -------------------------------------------------
# Set tibble as data.table
setDT(dc_indicators)

# Extract only the necessary variables
dc_poverty <- dc_indicators[, .(
	GEOID,
	NAME,
	total_population_universe,
	total_population_universe_M,
	federal_poverty_limit_universe_allraces,
	federal_poverty_limit_universe_allraces_M,
	federal_poverty_limit_below_allraces,
	federal_poverty_limit_below_allraces_M,
	federal_poverty_limit_below_allraces_percent,
	federal_poverty_limit_below_allraces_percent_M
)]

# Remove the leading 11 from the GEOID variable
# Datawrapper's corresponding variable does not have it, keeping it in here
# causes the join to fail
dc_poverty[, GEOID := gsub("^11", "", GEOID)]

# Turn proportions in to percentages
pct_cols <- grepv("percent", names(dc_poverty), fixed = TRUE)
dc_poverty[,
	(pct_cols) := lapply(.SD, \(x) round(x * 100, 2)),
	.SDcols = pct_cols
]

# Write data -------------------------------------------------------------

fwrite(dc_poverty, "data/processed/2024-acs5-federal_poverty_limit.csv")
