
# \plumber.R
# Each endpoint becomes a tool the Claude agent can call

library(plumber)

#* @apiTitle Airline Route Intelligence API
#* @apiDescription Analytical endpoints for route recommendation,
#*   competitor analysis, fleet assignment, and network redeployment

# ── CORS filter — needed for browser-based frontend ──────────────────────────
#* @filter cors
function(req, res) {
  res$setHeader("Access-Control-Allow-Origin",  "*")
  res$setHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
  res$setHeader("Access-Control-Allow-Headers", "Content-Type")
  if (req$REQUEST_METHOD == "OPTIONS") {
    res$status <- 200
    return(list())
  }
  plumber::forward()
}

# ── 1. Demand Forecasting ─────────────────────────────────────────────────────
#* Predict quarterly passenger demand for a route
#* @param origin     Origin airport IATA code (e.g. ORD)
#* @param dest       Destination airport IATA code (e.g. LAX)
#* @param avg_fare   Expected average fare in USD
#* @param avg_distance Route distance in miles
#* @param num_carriers Number of carriers currently serving the route
#* @param quarter    Quarter to predict for (1-4)
#* @get /demand/predict
function(origin, dest,
         avg_fare, avg_distance,
         num_carriers = 1,
         quarter = 2) {
  
  tryCatch({
    input <- tibble(
      avg_fare     = as.numeric(avg_fare),
      num_carriers = as.numeric(num_carriers),
      avg_distance = as.numeric(avg_distance),
      quarter      = factor(as.integer(quarter),
                            levels = 1:4,
                            labels = paste0("Q", 1:4)),
      route_id     = paste(origin, dest, sep = "_")
    )
    
    pred <- predict(route_stack_final, new_data = input) |>
      pull(.pred) |>
      round()
    
    list(
      origin                   = origin,
      dest                     = dest,
      quarter                  = as.integer(quarter),
      predicted_passengers_qtr = pred,
      predicted_passengers_ann = pred * 4,
      inputs                   = as.list(input |> select(-route_id))
    )
    
  }, error = function(e) {
    list(error = conditionMessage(e))
  })
}

# ── 2. Route Scoring ──────────────────────────────────────────────────────────
#* Predict expected load factor for a proposed route
#* @param avg_distance           Route distance in miles
#* @param num_operators          Number of current nonstop operators (0 = new route)
#* @param total_departures       Expected quarterly departures
#* @param primary_aircraft_class Aircraft class: narrowbody, widebody, regional_jet
#* @param quarter                Quarter to predict for (1-4)
#* @get /route/score
function(avg_distance,
         num_operators          = 0,
         total_departures       = 91,
         primary_aircraft_class = "narrowbody",
         quarter                = 2) {
  
  tryCatch({
    input <- tibble(
      avg_distance           = as.numeric(avg_distance),
      num_operators          = as.numeric(num_operators),
      total_departures       = as.numeric(total_departures),
      primary_aircraft_class = factor(primary_aircraft_class,
                                      levels = c("narrowbody", "regional_jet",
                                                 "regional_turboprop",
                                                 "widebody")),
      quarter                = factor(as.integer(quarter),
                                      levels = 1:4,
                                      labels = paste0("Q", 1:4)),
      route_id               = "NEW_ROUTE"
    )
    
    pred <- predict(final_fit, new_data = input) |>
      pull(.pred) |>
      pmax(0.05) |>
      pmin(1.00) |>
      round(3)
    
    interpretation <- case_when(
      pred >= 0.85 ~ "Excellent — strong load factor expected",
      pred >= 0.75 ~ "Good — commercially viable",
      pred >= 0.65 ~ "Moderate — marginal viability, review carefully",
      TRUE         ~ "Poor — route unlikely to be commercially viable"
    )
    
    list(
      predicted_load_factor = pred,
      interpretation        = interpretation,
      inputs = list(
        avg_distance           = as.numeric(avg_distance),
        num_operators          = as.numeric(num_operators),
        total_departures       = as.numeric(total_departures),
        primary_aircraft_class = primary_aircraft_class,
        quarter                = as.integer(quarter)
      )
    )
    
  }, error = function(e) {
    list(error = conditionMessage(e))
  })
}

# ── 3. Competitor Analysis ────────────────────────────────────────────────────
#* Get competitor breakdown for an existing route
#* @param origin Origin airport IATA code
#* @param dest   Destination airport IATA code
#* @param year   Year to analyze (default 2022)
#* @get /competitors/route
function(origin, dest, year = 2022) {
  tryCatch({
    result <- get_route_competitors(con, origin, dest, as.integer(year))
    if (nrow(result) == 0) {
      list(message = paste("No nonstop service found for", origin, "-", dest))
    } else {
      list(
        route    = paste(origin, dest, sep = "-"),
        year     = as.integer(year),
        carriers = result
      )
    }
  }, error = function(e) list(error = conditionMessage(e)))
}

#* Get market concentration (HHI) for a route
#* @param origin Origin airport IATA code
#* @param dest   Destination airport IATA code
#* @param year   Year to analyze (default 2022)
#* @get /competitors/concentration
function(origin, dest, year = 2022) {
  tryCatch({
    result <- get_market_concentration(con, origin, dest, as.integer(year))
    if (nrow(result) == 0) {
      list(message = paste("No data found for", origin, "-", dest))
    } else {
      list(route = paste(origin, dest, sep = "-"), data = result)
    }
  }, error = function(e) list(error = conditionMessage(e)))
}

#* Get network profile for a specific carrier
#* @param carrier_code IATA carrier code e.g. UA, DL, WN
#* @get /competitors/carrier
function(carrier_code) {
  tryCatch({
    result <- get_carrier_profile(con, carrier_code)
    list(carrier = carrier_code, data = result)
  }, error = function(e) list(error = conditionMessage(e)))
}

#* Find underserved route markets
#* @param min_passengers  Minimum quarterly DB1B passengers (default 500)
#* @param max_carriers    Maximum current nonstop carriers (default 0)
#* @param max_results     Number of results to return (default 20)
#* @get /competitors/underserved
function(min_passengers = 500,
         max_carriers   = 0,
         max_results    = 20) {
  tryCatch({
    result <- get_underserved_markets(
      con,
      min_passengers = as.numeric(min_passengers),
      max_carriers   = as.integer(max_carriers),
      max_results    = as.integer(max_results)
    )
    list(
      filters = list(
        min_passengers = as.numeric(min_passengers),
        max_carriers   = as.integer(max_carriers)
      ),
      routes = result
    )
  }, error = function(e) list(error = conditionMessage(e)))
}

#* Find routes where two carriers compete head to head
#* @param carrier_a First carrier IATA code
#* @param carrier_b Second carrier IATA code
#* @get /competitors/overlap
function(carrier_a, carrier_b) {
  tryCatch({
    result <- get_carrier_overlap(con, carrier_a, carrier_b)
    list(
      carrier_a = carrier_a,
      carrier_b = carrier_b,
      overlap   = result
    )
  }, error = function(e) list(error = conditionMessage(e)))
}

# ── 4. Fleet Assignment ───────────────────────────────────────────────────────
#* Optimize fleet assignment across candidate routes
#* @param fleet_json              JSON array of {aircraft_name, count} objects
#* @param departures_per_quarter  Assumed quarterly departures per route
#* @param quarter                 Quarter to optimize for (1-4)
#* @param min_passengers          Min demand for candidate routes
#* @post /fleet/optimize
function(req,
         departures_per_quarter = 91,
         quarter                = 2,
         min_passengers         = 500) {
  
  tryCatch({
    body <- jsonlite::fromJSON(req$postBody)
    fleet <- as_tibble(body$fleet)
    
    candidate_routes <- get_underserved_markets(
      con,
      min_passengers = as.numeric(min_passengers),
      max_carriers   = 0
    ) |>
      rename(avg_distance = distance_miles)
    
    result <- optimize_fleet_assignment(
      candidate_routes       = candidate_routes,
      fleet                  = fleet,
      departures_per_quarter = as.numeric(departures_per_quarter),
      quarter                = as.integer(quarter)
    )
    
    list(
      routes_evaluated         = nrow(candidate_routes),
      routes_assigned          = nrow(result),
      expected_annual_passengers = sum(result$expected_annual_passengers),
      assignments              = result
    )
    
  }, error = function(e) list(error = conditionMessage(e)))
}

# ── 5. Network Redeployment ───────────────────────────────────────────────────
#* Find underperforming routes where capacity could be redeployed
#* @param carrier_code       IATA carrier code (optional — omit for all carriers)
#* @param lf_gap_threshold   Minimum LF gap to flag route (default 0.10)
#* @param min_seats_deployed Minimum quarterly seats to include (default 10000)
#* @param quarter            Quarter to analyze (1-4)
#* @get /redeployment/candidates
function(carrier_code       = NULL,
         lf_gap_threshold   = 0.10,
         min_seats_deployed = 10000,
         quarter            = 2) {
  
  tryCatch({
    carrier <- if (is.null(carrier_code) ||
                   carrier_code == "" ||
                   carrier_code == "NULL") NULL else carrier_code
    
    candidates <- get_redeployment_candidates(
      con,
      carrier_code       = carrier,
      lf_gap_threshold   = as.numeric(lf_gap_threshold),
      min_seats_deployed = as.numeric(min_seats_deployed),
      quarter            = as.integer(quarter)
    )
    
    summary <- get_redeployment_summary(candidates)
    
    list(
      total_underperforming_routes   = nrow(candidates),
      total_excess_seats_quarterly   = sum(candidates$excess_seats_quarterly),
      carrier_summary                = summary,
      route_detail                   = candidates
    )
    
  }, error = function(e) list(error = conditionMessage(e)))
}
