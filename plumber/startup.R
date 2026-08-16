
# startup.R
# Runs once at API startup

library(tidyverse)
library(tidymodels)
library(duckdb)
library(ompr)
library(ompr.roi)
library(ROI.plugin.glpk)
library(glue)
library(here)

tidymodels_prefer()

message("Loading models...")

# Demand forecasting ensemble
load(here("results", "route_stack_final.rda"))

# Route scoring model
load(here("results", "scoring_final_fit.rda"))

# Aircraft reference data
load(here("data", "aircraft_performance.rda"))

message("Connecting to database...")

# Single shared DuckDB connection
# Plumber handles requests sequentially by default so this is safe
con <- dbConnect(duckdb(), here("data", "airline_prod.duckdb"))

message("Sourcing analysis functions...")
source(here("competitor_analysis", "02_queries.R"))
source(here("fleet_assignment",    "02_optimize.R"))
source(here("network_redeployment","01_analysis.R"))

message("API ready")
