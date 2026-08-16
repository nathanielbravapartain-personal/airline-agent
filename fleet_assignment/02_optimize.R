
# 02_optimize.R
# Fleet assignment optimization using integer programming (ompr)
#
# Problem: given a set of candidate routes and an airline's fleet,
# find the optimal assignment of aircraft types to routes that
# maximizes total expected passengers, subject to:
#   - each route gets at most one aircraft type
#   - fleet availability (can't assign more planes than you own)
#   - range feasibility (aircraft must reach the destination)


library(tidyverse)
library(here)
library(tidymodels)
library(ompr)
library(ompr.roi)
library(ROI.plugin.glpk)
library(duckdb)

tidymodels_prefer()

load(here("results/scoring_final_fit.rda"))
load(here("data/aircraft_performance.rda"))

# ── Core optimizer function ───────────────────────────────────────────────────
#
# candidate_routes: data frame with columns:
#   origin, dest, avg_distance, est_annual_passengers
#   (output of get_underserved_markets, or user-specified)
#
# fleet: data frame with columns:
#   aircraft_name  (must match aircraft_performance$aircraft_name)
#   count          (how many of that type the airline has available)
#
# departures_per_quarter: assumed flight frequency per quarter
#   91  = once daily
#   182 = twice daily
#   273 = three times daily
#
# quarter: which quarter to predict load factor for (1-4)

optimize_fleet_assignment <- function(candidate_routes,
                                      fleet,
                                      departures_per_quarter = 91,
                                      quarter = 2) {
  
  # ── Step 1: join fleet with performance data ──────────────────────────────
  fleet_perf <- fleet |>
    inner_join(aircraft_performance, by = "aircraft_name")
  
  if (nrow(fleet_perf) == 0) {
    stop(
      "No aircraft names matched aircraft_performance table.\n",
      "Check spelling against aircraft_performance$aircraft_name."
    )
  }
  
  n_routes   <- nrow(candidate_routes)
  n_aircraft <- nrow(fleet_perf)
  
  message("Optimizing: ", n_routes, " candidate routes x ",
          n_aircraft, " aircraft types")
  
  # ── Step 2: build prediction grid ────────────────────────────────────────
  # One row per route-aircraft combination
  pred_grid <- expand_grid(
    route_idx    = seq_len(n_routes),
    aircraft_idx = seq_len(n_aircraft)
  ) |>
    mutate(
      avg_distance           = candidate_routes$avg_distance[route_idx],
      num_operators          = 0,
      total_departures       = departures_per_quarter,
      primary_aircraft_class = fleet_perf$aircraft_class[aircraft_idx],
      quarter                = factor(
        quarter,
        levels = 1:4,
        labels = paste0("Q", 1:4)
      ),
      route_id               = paste0(
        "NEW_",
        candidate_routes$origin[route_idx], "_",
        candidate_routes$dest[route_idx]
      ),
      # FALSE if aircraft range is insufficient for route distance
      feasible               = fleet_perf$range_miles[aircraft_idx] >=
        candidate_routes$avg_distance[route_idx]
    )
  
  # Predict load factors using route scoring model
  preds <- predict(final_fit, new_data = pred_grid) |>
    pull(.pred) |>
    pmax(0.05) |>
    pmin(1.00)
  
  pred_grid <- pred_grid |>
    mutate(predicted_load_factor = preds)
  
  # ── Step 3: build value matrix ────────────────────────────────────────────
  # value[i, j] = expected annual passengers if aircraft j flies route i
  #             = seats x predicted_load_factor x departures_per_quarter x 4
  # Infeasible combinations (insufficient range) get value = 0
  
  value_matrix <- matrix(0, nrow = n_routes, ncol = n_aircraft)
  
  for (k in seq_len(nrow(pred_grid))) {
    i <- pred_grid$route_idx[k]
    j <- pred_grid$aircraft_idx[k]
    if (pred_grid$feasible[k]) {
      value_matrix[i, j] <- fleet_perf$seats[j] *
        pred_grid$predicted_load_factor[k] *
        departures_per_quarter * 4
    }
  }
  
  # ── Step 4: solve integer program ─────────────────────────────────────────
  fleet_count <- fleet_perf$count
  
  model <- MIPModel() |>
    
    # Decision variable: x[i, j] = 1 if aircraft type j assigned to route i
    add_variable(
      x[i, j],
      i    = 1:n_routes,
      j    = 1:n_aircraft,
      type = "binary"
    ) |>
    
    # Objective: maximize total expected annual passengers
    set_objective(
      sum_over(
        value_matrix[i, j] * x[i, j],
        i = 1:n_routes,
        j = 1:n_aircraft
      ),
      sense = "max"
    ) |>
    
    # Constraint 1: each route gets at most one aircraft type
    add_constraint(
      sum_over(x[i, j], j = 1:n_aircraft) <= 1,
      i = 1:n_routes
    ) |>
    
    # Constraint 2: fleet availability — can't assign more than you own
    add_constraint(
      sum_over(x[i, j], i = 1:n_routes) <= fleet_count[j],
      j = 1:n_aircraft
    )
  
  message("Solving...")
  solution <- solve_model(
    model,
    with_ROI(solver = "glpk", verbose = FALSE)
  )
  
  # glpk returns "success" for optimal solves — not "optimal"
  if (!solution$status %in% c("optimal", "success")) {
    warning("Solver did not find optimal solution. Status: ", solution$status)
  }
  
  # ── Step 5: extract results ───────────────────────────────────────────────
  assignments <- get_solution(solution, x[i, j]) |>
    filter(value > 0.5) |>
    mutate(
      origin         = candidate_routes$origin[i],
      dest           = candidate_routes$dest[i],
      avg_distance   = candidate_routes$avg_distance[i],
      est_annual_pax = candidate_routes$est_annual_passengers[i],
      aircraft_name  = fleet_perf$aircraft_name[j],
      aircraft_class = fleet_perf$aircraft_class[j],
      seats          = fleet_perf$seats[j],
      range_miles    = fleet_perf$range_miles[j],
      # mapply for row-wise lookup into pred_grid and value_matrix
      predicted_lf = round(
        mapply(
          function(ri, rj) pred_grid$predicted_load_factor[(ri - 1) * n_aircraft + rj],
          i, j
        ), 3
      ),
      expected_annual_passengers = round(
        mapply(function(ri, rj) value_matrix[ri, rj], i, j)
      )
    ) |>
    select(
      origin, dest, avg_distance, est_annual_pax,
      aircraft_name, aircraft_class, seats, range_miles,
      predicted_lf, expected_annual_passengers
    ) |>
    arrange(desc(expected_annual_passengers))
  
  message("Assigned ", nrow(assignments), " of ", n_routes,
          " candidate routes")
  message("Expected total annual passengers: ",
          format(sum(assignments$expected_annual_passengers), big.mark = ","))
  
  assignments
}

