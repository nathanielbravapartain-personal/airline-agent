# 00 data preprocessing - for demand forcasting

# Libraries

library(here)
library(tidymodels)
library(duckdb)
library(tsibble)

tidymodels_prefer()

# Connect to existing DuckDB warehouse
con <- dbConnect(duckdb(), here("data/demand_data", "airline.duckdb"))

# Coupon files

dbExecute(con, "
  CREATE OR REPLACE TABLE db1b_coupon AS
  SELECT * FROM read_csv_auto(
    ['data/demand_data/Origin_and_Destination_Survey_DB1BCoupon_2022_1.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BCoupon_2022_2.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BCoupon_2022_3.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BCoupon_2022_4.csv'],
    union_by_name = true,
    filename = true
  )
")

# Market files

dbExecute(con, "
  CREATE OR REPLACE TABLE db1b_market AS
  SELECT * FROM read_csv_auto(
    ['data/demand_data/Origin_and_Destination_Survey_DB1BMarket_2022_1.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BMarket_2022_2.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BMarket_2022_3.csv',
     'data/demand_data/Origin_and_Destination_Survey_DB1BMarket_2022_4.csv'],
    union_by_name = true,
    filename = true
  )
")

# Building the route summary

dbExecute(con, "
  CREATE OR REPLACE TABLE route_summary AS
  SELECT
    Origin AS origin,
    Dest AS dest,
    Year AS year,
    Quarter AS quarter,
    SUM(Passengers) AS total_passengers,
    AVG(MktFare) AS avg_fare,
    COUNT(DISTINCT OpCarrier) AS num_carriers,
    SUM(Passengers * MktFare) AS total_revenue,
    AVG(MktDistance) AS avg_distance
  FROM db1b_market
  WHERE Origin != Dest
    AND Passengers > 0
    AND MktFare > 0
    AND MktFare < 5000
    AND BulkFare = 0            -- exclude bulk/tour package fares
    AND ItinGeoType = 1         -- domestic itineraries only
  GROUP BY Origin, Dest, Year, Quarter
")

dbGetQuery(con, "SELECT COUNT(*) AS n_routes FROM route_summary")
dbGetQuery(con, "SELECT * FROM route_summary ORDER BY total_passengers DESC LIMIT 10")




















