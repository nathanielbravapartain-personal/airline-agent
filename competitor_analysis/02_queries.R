# competitor_analysis/02_queries.R
# Parameterized query functions for competitor analysis

library(duckdb)
library(tidyverse)
library(glue)
library(here)

# ── 1. get_route_competitors ───────────────────────────────────────────────
# Who flies a given route, with market share, load factor, and aircraft type
# Agent uses this to answer: "who are the competitors on this route?"

get_route_competitors <- function(con, origin, dest, year = 2022) {
  
  dbGetQuery(con, glue("
    WITH route_total AS (
      SELECT SUM(total_passengers_t100) AS total_pax
      FROM carrier_route_summary
      WHERE origin = '{origin}' AND dest = '{dest}' AND year = {year}
    )
    SELECT
      c.carrier,
      c.carrier_name,
      c.quarter,
      c.aircraft_name,
      c.aircraft_class,
      c.total_departures,
      c.total_passengers_t100,
      c.load_factor,
      ROUND(100.0 * c.total_passengers_t100 /
            NULLIF(r.total_pax, 0), 1) AS market_share_pct,
      ROUND(c.avg_distance, 0) AS distance_miles
    FROM carrier_route_summary c
    CROSS JOIN route_total r
    WHERE c.origin = '{origin}'
      AND c.dest   = '{dest}'
      AND c.year   = {year}
    ORDER BY c.quarter, market_share_pct DESC
  "))
}

# ── 2. get_market_concentration ───────────────────────────────────────────
# HHI score and competitive summary for a route
# HHI guide: <1500 = competitive, 1500-2500 = moderate, >2500 = concentrated
# Agent uses this to answer: "is this market dominated or contested?"

get_market_concentration <- function(con, origin, dest, year = 2022) {
  
  dbGetQuery(con, glue("
    SELECT
      origin, dest,
      quarter,
      num_carriers,
      route_total_passengers,
      hhi,
      CASE
        WHEN hhi < 1500  THEN 'Competitive'
        WHEN hhi < 2500  THEN 'Moderately Concentrated'
        WHEN hhi < 10000 THEN 'Concentrated'
        ELSE                  'Monopoly'
      END AS market_structure,
      carrier_codes,
      market_shares
    FROM route_competition_summary
    WHERE origin = '{origin}'
      AND dest   = '{dest}'
      AND year   = {year}
    ORDER BY quarter
  "))
}

# ── 3. get_carrier_profile ────────────────────────────────────────────────
# Network summary for a specific carrier
# Agent uses this to answer: "what kind of airline is X and how do they operate?"

get_carrier_profile <- function(con, carrier_code) {
  
  # Overall network summary
  profile <- dbGetQuery(con, glue("
    SELECT *
    FROM carrier_network_profile
    WHERE carrier = '{carrier_code}'
  "))
  
  # Top 10 routes by passengers
  top_routes <- dbGetQuery(con, glue("
    SELECT
      origin, dest,
      aircraft_name,
      SUM(total_departures)      AS annual_departures,
      SUM(total_passengers_t100) AS annual_passengers,
      ROUND(AVG(load_factor), 3) AS avg_load_factor,
      ROUND(AVG(avg_distance), 0) AS distance_miles
    FROM carrier_route_summary
    WHERE carrier = '{carrier_code}'
    GROUP BY origin, dest, aircraft_name
    ORDER BY annual_passengers DESC
    LIMIT 10
  "))
  
  list(profile = profile, top_routes = top_routes)
}

# ── 4. get_underserved_markets ────────────────────────────────────────────
# Routes with high DB1B demand but few nonstop operators — opportunity signal
# Agent uses this to answer: "where should we consider launching new routes?"

get_underserved_markets <- function(con,
                                    min_passengers = 500,
                                    max_carriers   = 0,
                                    max_results    = 20) {
  dbGetQuery(con, glue("
    WITH demand AS (
      SELECT
        origin, dest,
        SUM(total_passengers)  AS db1b_passengers,
        AVG(avg_fare)          AS avg_fare,
        AVG(avg_distance)      AS avg_distance
      FROM route_summary
      GROUP BY origin, dest
    ),
    supply AS (
      SELECT
        origin, dest,
        COUNT(DISTINCT carrier) AS num_nonstop_carriers,
        SUM(total_departures)   AS total_nonstop_departures,
        ROUND(AVG(load_factor), 3) AS avg_load_factor
      FROM carrier_route_summary
      GROUP BY origin, dest
    )
    SELECT
      d.origin,
      d.dest,
      ROUND(d.db1b_passengers * 10)   AS est_annual_passengers,
      ROUND(d.avg_fare, 2)            AS avg_fare,
      ROUND(d.avg_distance, 0)        AS distance_miles,
      COALESCE(s.num_nonstop_carriers, 0)     AS nonstop_carriers,
      COALESCE(s.total_nonstop_departures, 0) AS nonstop_departures,
      s.avg_load_factor                       AS nonstop_load_factor
    FROM demand d
    LEFT JOIN supply s
      ON d.origin = s.origin AND d.dest = s.dest
    WHERE d.db1b_passengers >= {min_passengers}
      AND COALESCE(s.num_nonstop_carriers, 0) <= {max_carriers}
      AND d.avg_distance >= 200
      AND d.origin NOT IN ('STT', 'STX', 'SPB', 'SSB')
      AND d.dest   NOT IN ('STT', 'STX', 'SPB', 'SSB')
    ORDER BY d.db1b_passengers DESC
    LIMIT {max_results}
  "))
}

get_underserved_markets(con, min_passengers = 500, max_carriers = 0)

# ── 5. get_carrier_overlap ────────────────────────────────────────────────
# Routes where two carriers compete head to head
# Agent uses this to answer: "where does carrier A compete with carrier B?"

get_carrier_overlap <- function(con, carrier_a, carrier_b,
                                min_combined_passengers = 100000) {
  dbGetQuery(con, glue("
    WITH a_routes AS (
      SELECT DISTINCT origin, dest
      FROM carrier_route_summary
      WHERE carrier = '{carrier_a}'
    ),
    b_routes AS (
      SELECT DISTINCT origin, dest
      FROM carrier_route_summary
      WHERE carrier = '{carrier_b}'
    ),
    overlap AS (
      SELECT a.origin, a.dest
      FROM a_routes a
      INNER JOIN b_routes b
        ON a.origin = b.origin AND a.dest = b.dest
    )
    SELECT
      o.origin,
      o.dest,
      MAX(CASE WHEN c.carrier = '{carrier_a}'
               THEN c.carrier_name END)          AS carrier_a_name,
      SUM(CASE WHEN c.carrier = '{carrier_a}'
               THEN c.total_passengers_t100 END) AS carrier_a_passengers,
      ROUND(AVG(CASE WHEN c.carrier = '{carrier_a}'
               THEN c.load_factor END), 3)       AS carrier_a_load_factor,
      MAX(CASE WHEN c.carrier = '{carrier_b}'
               THEN c.carrier_name END)          AS carrier_b_name,
      SUM(CASE WHEN c.carrier = '{carrier_b}'
               THEN c.total_passengers_t100 END) AS carrier_b_passengers,
      ROUND(AVG(CASE WHEN c.carrier = '{carrier_b}'
               THEN c.load_factor END), 3)       AS carrier_b_load_factor
    FROM overlap o
    JOIN carrier_route_summary c
      ON c.origin = o.origin AND c.dest = o.dest
      AND c.carrier IN ('{carrier_a}', '{carrier_b}')
    GROUP BY o.origin, o.dest
    HAVING (SUM(CASE WHEN c.carrier = '{carrier_a}'
                     THEN c.total_passengers_t100 END) +
            SUM(CASE WHEN c.carrier = '{carrier_b}'
                     THEN c.total_passengers_t100 END)) >= {min_combined_passengers}
    ORDER BY (carrier_a_passengers + carrier_b_passengers) DESC
    LIMIT 25
  "))
}


