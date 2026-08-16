# competitor_analysis/01_build_tables.R

library(tidyverse)
library(here)
library(duckdb)
library(glue)



con <- dbConnect(duckdb(), here("data", "airline.duckdb"))

# Read back from DuckDB
aircraft_lookup <- dbGetQuery(con, "SELECT * FROM aircraft_lookup") |>
  as_tibble()

# Fix the neo family codes
aircraft_lookup <- aircraft_lookup |>
  mutate(
    aircraft_name = case_when(
      aircraft_type == "721" ~ "Airbus A319neo",
      aircraft_type == "722" ~ "Airbus A320neo",
      aircraft_type == "723" ~ "Airbus A321neo",
      aircraft_type == "724" ~ "Airbus A321neo LR/XLR",
      TRUE ~ aircraft_name
    ),
    aircraft_class = case_when(
      aircraft_type %in% c("721", "722", "723", "724") ~ "narrowbody",
      TRUE ~ aircraft_class
    )
  )

# Verify before writing back
aircraft_lookup |>
  filter(aircraft_type %in% c("721", "722", "723", "724")) |>
  select(aircraft_type, aircraft_name, aircraft_class)

# Write corrected version back to DuckDB
dbWriteTable(con, "aircraft_lookup", aircraft_lookup, overwrite = TRUE)

con <- dbConnect(duckdb(), here("data", "airline.duckdb"))

# Step 1: rebuild t100_route_summary with corrected lookup
dbExecute(con, "
  CREATE OR REPLACE TABLE t100_route_summary AS
  SELECT
    t.ORIGIN AS origin, t.DEST AS dest,
    t.YEAR AS year, t.QUARTER AS quarter,
    t.CARRIER AS carrier, t.CARRIER_NAME AS carrier_name,
    a.aircraft_name, a.aircraft_class, a.seats_approx,
    SUM(t.DEPARTURES_PERFORMED) AS total_departures,
    SUM(t.SEATS)                AS total_seats_deployed,
    SUM(t.PASSENGERS)           AS total_passengers_t100,
    ROUND(SUM(t.PASSENGERS) / NULLIF(SUM(t.SEATS), 0), 3) AS load_factor,
    AVG(t.DISTANCE)             AS avg_distance
  FROM t100_segment t
  LEFT JOIN aircraft_lookup a ON t.AIRCRAFT_TYPE = a.aircraft_type
  WHERE t.DEPARTURES_PERFORMED > 0
    AND t.PASSENGERS >= 0
    AND a.aircraft_class != 'helicopter'
    AND t.DISTANCE >= 100
    AND t.ORIGIN_STATE_ABR NOT IN ('TT', 'VI', 'GU', 'MP', 'AS')
    AND t.DEST_STATE_ABR   NOT IN ('TT', 'VI', 'GU', 'MP', 'AS')
  GROUP BY
    t.ORIGIN, t.DEST, t.YEAR, t.QUARTER,
    t.CARRIER, t.CARRIER_NAME,
    a.aircraft_name, a.aircraft_class, a.seats_approx
")
message("t100_route_summary rebuilt")

# Step 2: rebuild carrier_route_summary
dbExecute(con, "
  CREATE OR REPLACE TABLE carrier_route_summary AS
  SELECT *
  FROM t100_route_summary
  WHERE aircraft_class NOT IN ('small', 'helicopter')
    AND total_passengers_t100 > 0
    AND load_factor BETWEEN 0.01 AND 1.0
")
message("carrier_route_summary rebuilt")

# Step 3: rebuild route_competition_summary
dbExecute(con, "
  CREATE OR REPLACE TABLE route_competition_summary AS
  WITH route_totals AS (
    SELECT
      origin, dest, year, quarter,
      SUM(total_passengers_t100) AS route_total_passengers,
      SUM(total_departures)      AS route_total_departures,
      COUNT(DISTINCT carrier)    AS num_carriers
    FROM carrier_route_summary
    GROUP BY origin, dest, year, quarter
  ),
  carrier_shares AS (
    SELECT
      c.origin, c.dest, c.year, c.quarter,
      c.carrier, c.carrier_name,
      c.total_passengers_t100,
      c.total_departures,
      c.load_factor,
      c.aircraft_class,
      r.route_total_passengers,
      r.num_carriers,
      ROUND(100.0 * c.total_passengers_t100 /
            NULLIF(r.route_total_passengers, 0), 1) AS market_share_pct,
      POWER(100.0 * c.total_passengers_t100 /
            NULLIF(r.route_total_passengers, 0), 2) AS hhi_contribution
    FROM carrier_route_summary c
    JOIN route_totals r
      ON  c.origin  = r.origin
      AND c.dest    = r.dest
      AND c.year    = r.year
      AND c.quarter = r.quarter
  )
  SELECT
    origin, dest, year, quarter,
    num_carriers,
    route_total_passengers,
    ROUND(SUM(hhi_contribution), 1) AS hhi,
    STRING_AGG(carrier, '/' ORDER BY market_share_pct DESC) AS carrier_codes,
    STRING_AGG(CAST(ROUND(market_share_pct, 1) AS VARCHAR), '/'
               ORDER BY market_share_pct DESC) AS market_shares
  FROM carrier_shares
  GROUP BY origin, dest, year, quarter, num_carriers, route_total_passengers
")
message("route_competition_summary rebuilt")

# Step 4: rebuild carrier_network_profile
dbExecute(con, "
  CREATE OR REPLACE TABLE carrier_network_profile AS
  SELECT
    carrier,
    carrier_name,
    COUNT(DISTINCT origin || '_' || dest) AS routes_operated,
    COUNT(DISTINCT origin)                AS origins_served,
    COUNT(DISTINCT aircraft_class)        AS aircraft_classes_used,
    SUM(total_departures)                 AS total_annual_departures,
    SUM(total_passengers_t100)            AS total_annual_passengers,
    ROUND(AVG(load_factor), 3)            AS avg_load_factor,
    ROUND(AVG(avg_distance), 0)           AS avg_route_distance,
    FIRST(aircraft_class ORDER BY total_departures DESC) AS primary_aircraft_class
  FROM carrier_route_summary
  GROUP BY carrier, carrier_name
  ORDER BY total_annual_passengers DESC
")
message("carrier_network_profile rebuilt")

# Verify the fix
dbGetQuery(con, "
  SELECT
    carrier_name, aircraft_class, aircraft_name,
    SUM(total_departures) AS total_departures
  FROM carrier_route_summary
  WHERE carrier IN ('NK', 'F9', 'B6')
  GROUP BY carrier_name, aircraft_class, aircraft_name
  ORDER BY carrier_name, total_departures DESC
")

