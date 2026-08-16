# 01_analysis
# Identifies existing routes where deployed capacity exceeds demand,
# producing a ranked list of redeployment candidates.


library(tidyverse)
library(here)
library(tidymodels)
library(duckdb)

tidymodels_prefer()

load(here("results/scoring_final_fit.rda"))

# ── Core redeployment analysis function ──────────────────────────────────────
#
# carrier_code:        IATA carrier code e.g. "UA", "DL", "WN"
#                      NULL = analyze all carriers
# lf_gap_threshold:    minimum gap between predicted and actual LF
#                      to flag a route as underperforming (default 0.10 = 10pp)
# min_seats_deployed:  minimum quarterly seats to be worth redeploying
#                      filters out very thin routes where the math is noisy
# quarter:             which quarter to analyze (1-4)

get_redeployment_candidates <- function(con,
                                        carrier_code      = NULL,
                                        lf_gap_threshold  = 0.10,
                                        min_seats_deployed = 10000,
                                        quarter           = 2) {
  
  # ── Step 1: pull current operations ──────────────────────────────────────
  carrier_filter <- if (!is.null(carrier_code)) {
    glue::glue("AND carrier = '{carrier_code}'")
  } else {
    ""
  }
  
  current_ops <- dbGetQuery(con, glue::glue("
    SELECT
      origin,
      dest,
      year,
      quarter,
      carrier,
      carrier_name,
      aircraft_name,
      aircraft_class,
      seats_approx,
      total_departures,
      total_seats_deployed,
      total_passengers_t100,
      load_factor,
      avg_distance
    FROM t100_route_summary
    WHERE quarter = {quarter}
      AND aircraft_class NOT IN ('small', 'helicopter')
      AND total_passengers_t100 > 0
      AND load_factor BETWEEN 0.01 AND 1.0
      AND total_seats_deployed >= {min_seats_deployed}
      {carrier_filter}
  ")) |>
    as_tibble()
  
  if (nrow(current_ops) == 0) {
    message("No operations found matching filters.")
    return(tibble())
  }
  
  message("Analyzing ", nrow(current_ops), " carrier-route-quarter records")
  
  # ── Step 2: predict expected load factor ─────────────────────────────────
  # Build prediction input matching route scoring model's feature set
  pred_input <- current_ops |>
    mutate(
      # num_operators: count distinct carriers on each route
      # using current_ops itself as a proxy — more carriers = more competition
      num_operators = 1L,   # placeholder — will join actual count below
      primary_aircraft_class = aircraft_class,
      quarter = factor(quarter, levels = 1:4, labels = paste0("Q", 1:4)),
      route_id = paste(origin, dest, sep = "_")
    )
  
  # Get actual carrier counts per route for competition signal
  route_carrier_counts <- current_ops |>
    group_by(origin, dest) |>
    summarise(num_operators = n_distinct(carrier), .groups = "drop")
  
  pred_input <- pred_input |>
    select(-num_operators) |>
    left_join(route_carrier_counts, by = c("origin", "dest"))
  
  # Predict expected load factor
  predicted_lf <- predict(final_fit, new_data = pred_input) |>
    pull(.pred) |>
    pmax(0.05) |>
    pmin(1.00)
  
  # ── Step 3: calculate performance gap ────────────────────────────────────
  results <- current_ops |>
    mutate(
      predicted_load_factor  = round(predicted_lf, 3),
      actual_load_factor     = load_factor,
      lf_gap                 = round(predicted_load_factor - actual_load_factor, 3),
      excess_seats_quarterly = round(
        (predicted_load_factor - actual_load_factor) * total_seats_deployed
      ),
      
      # Annualized excess passenger-opportunity being lost
      annual_passenger_gap = round(excess_seats_quarterly * 4),
      
      # Flag: is this route underperforming significantly?
      redeployment_flag = lf_gap >= lf_gap_threshold
    ) |>
    filter(redeployment_flag) |>
    select(
      carrier, carrier_name,
      origin, dest,
      quarter,
      aircraft_name, aircraft_class, seats_approx,
      total_departures, total_seats_deployed,
      actual_load_factor, predicted_load_factor, lf_gap,
      excess_seats_quarterly, annual_passenger_gap
    ) |>
    arrange(desc(lf_gap))
  
  message("Found ", nrow(results), " underperforming carrier-route records")
  message("Total excess seats (quarterly): ",
          format(sum(results$excess_seats_quarterly), big.mark = ","))
  
  results
}

# ── Network-level summary function ───────────────────────────────────────────


get_redeployment_summary <- function(redeployment_candidates) {
  
  if (nrow(redeployment_candidates) == 0) {
    message("No candidates to summarize.")
    return(tibble())
  }
  
  redeployment_candidates |>
    group_by(carrier, carrier_name) |>
    summarise(
      underperforming_routes   = n(),
      total_excess_seats_qtrly = sum(excess_seats_quarterly),
      total_annual_pax_gap     = sum(annual_passenger_gap),
      avg_lf_gap               = round(mean(lf_gap), 3),
      worst_route              = paste(
        origin[which.max(lf_gap)],
        dest[which.max(lf_gap)],
        sep = "-"
      ),
      worst_route_lf_gap       = max(lf_gap),
      .groups = "drop"
    ) |>
    arrange(desc(total_excess_seats_qtrly))
}

