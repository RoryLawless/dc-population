library(shiny)
library(bslib)
library(bsicons)
library(tidyverse)
library(scales)
library(here)
library(conflicted)

conflicts_prefer(dplyr::filter)

# ---- Data (loaded once at startup) -------------------------------------

dc_population <- read_csv(
	here("data/processed/dc-population-1990-2025.csv"),
	show_col_types = FALSE
) |>
	mutate(year = as.integer(year)) |>
	select(year, value)

dc_births <- read_csv(
	here("data/processed/dc-births-1995-2025.csv"),
	show_col_types = FALSE
) |>
	select(year, value = births, status)

year_bounds <- range(c(dc_population$year, dc_births$year))

# ---- Helper for value box metrics --------------------------------------

summarize_series <- function(data) {
	data <- data |>
		arrange(year) |>
		summarise(
			latest = last(value),
			percent = last(value) / first(value) - 1
		)

	list(
		latest = scales::label_comma()(data$latest),
		change = scales::label_percent(
			style_positive = "plus",
			accuracy = 0.1
		)(data$percent)
	)
}

# ---- Theme -------------------------------------------------------------

# Single source of truth for the app's palette. Any hex literal used in a
# ggplot geom, scale, or bs_theme() slot should come from here — if you add a
# color, add it here and wire it into bs_theme() so Bootstrap components pick
# it up too.
palette_dc <- c(
	paper = "#fbf5f5", # app background
	ink = "#070a0c", # body text
	accent = "#b46466", # primary / "provisional" series
	sand = "#d9cfc4", # secondary / smoother ribbon fill
	slate = "#2f3a4a", # info / trendlines & "final" series
	sage = "#6b8f78" # success / smoother line
)

theme_dc <- bs_theme(
	version = 5,
	bg = palette_dc[["paper"]],
	fg = palette_dc[["ink"]],
	primary = palette_dc[["accent"]],
	secondary = palette_dc[["sand"]],
	info = palette_dc[["slate"]],
	success = palette_dc[["sage"]],
	base_font = font_google("Lato"),
	heading_font = font_google("Playfair Display")
)

theme_dc_plot <- theme_minimal(
	base_size = 12,
	base_family = "Lato-Regular",
	header_family = "PlayfairDisplayRoman-SemiBold",
	paper = palette_dc[["paper"]],
	ink = palette_dc[["ink"]],
	accent = palette_dc[["accent"]],
) +
	theme(
		plot.title.position = "plot",
		title = element_text(size = 14),
		axis.title = element_text(size = 12),
		axis.text = element_text(size = 10)
	)

theme_set(theme_dc_plot)

# ---- UI ----------------------------------------------------------------

ui <- page_navbar(
	title = "DC Population Explorer",
	theme = theme_dc,
	sidebar = sidebar(
		title = "Filter",
		sliderInput(
			"year_range",
			"Year range",
			min = year_bounds[1],
			max = year_bounds[2],
			value = year_bounds,
			step = 1,
			sep = ""
		),
		helpText(
			"Geography tab shows a 2024 ACS snapshot and is not affected by this filter."
		)
	),

	nav_panel(
		"Population",
		layout_column_wrap(
			width = 1 / 2,
			fill = FALSE,
			value_box(
				title = "Latest population",
				value = textOutput("pop_latest"),
				showcase = bs_icon("people-fill"),
				theme = "primary"
			),
			value_box(
				title = "Change over range",
				value = textOutput("pop_change"),
				showcase = bs_icon("graph-up"),
				theme = "secondary"
			)
		),
		card(
			full_screen = TRUE,
			card_header("Population over time"),
			plotOutput("pop_plot")
		)
	),

	nav_panel(
		"Births",
		layout_column_wrap(
			width = 1 / 2,
			fill = FALSE,
			value_box(
				title = "Latest births",
				value = textOutput("births_latest"),
				showcase = bs_icon("heart-fill"),
				theme = "primary"
			),
			value_box(
				title = "Change over range",
				value = textOutput("births_change"),
				showcase = bs_icon("graph-up"),
				theme = "secondary"
			)
		),
		card(
			full_screen = TRUE,
			card_header("Births over time"),
			plotOutput("births_plot")
		)
	)
)

# ---- Server ------------------------------------------------------------

server <- function(input, output, session) {
	filtered_population <- reactive({
		dc_population |>
			filter(
				year >= input$year_range[1],
				year <= input$year_range[2]
			)
	})

	filtered_births <- reactive({
		dc_births |>
			filter(
				year >= input$year_range[1],
				year <= input$year_range[2]
			)
	})

	pop_summary <- reactive(summarize_series(filtered_population()))
	births_summary <- reactive(summarize_series(filtered_births()))

	output$pop_latest <- renderText(pop_summary()$latest)
	output$pop_change <- renderText(pop_summary()$change)
	output$births_latest <- renderText(births_summary()$latest)
	output$births_change <- renderText(births_summary()$change)

	output$pop_plot <- renderPlot({
		filtered_population() |>
			ggplot(aes(x = year, y = value)) +
			geom_smooth(
				method = "loess",
				color = palette_dc[["sage"]],
				fill = palette_dc[["sand"]]
			) +
			geom_line(
				linewidth = 1,
				color = palette_dc[["slate"]],
				lineend = "round"
			) +
			scale_y_continuous(
				labels = label_number(scale_cut = cut_short_scale())
			) +
			labs(x = "Year", y = "Population")
	})

	output$births_plot <- renderPlot({
		filtered_births() |>
			ggplot(aes(x = year, y = value)) +
			geom_line(
				linewidth = 1,
				color = palette_dc[["slate"]],
				lineend = "round"
			) +
			geom_point(aes(color = status), size = 2.5) +
			scale_color_manual(
				values = c(
					final = palette_dc[["slate"]],
					provisional = palette_dc[["accent"]]
				)
			) +
			scale_y_continuous(labels = label_comma()) +
			labs(x = "Year", y = "Births", color = NULL)
	})
}

shinyApp(ui, server)
