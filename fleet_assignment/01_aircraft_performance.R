
# 01_aircraft_performance
# Aircraft performance data for fleet assignment optimization
# Range in statute miles, seats are typical single-class max config
# Sources: manufacturer specs, OAG fleet data

library(tidyverse)
library(here)
library(duckdb)

aircraft_performance <- tribble(
  ~aircraft_name, ~seats, ~range_miles, ~aircraft_class,
  # ── Regional Jets ────────────────────────────────────────────────────────
  "Embraer ERJ-135", 37, 1600, "regional_jet",
  "Embraer ERJ-145", 50, 1800, "regional_jet",
  "Canadair CRJ-200", 50, 1650, "regional_jet",
  "Embraer 170",                70,         2400,   "regional_jet",
  "Canadair CRJ-700",           70,         2100,   "regional_jet",
  "Embraer ERJ-175",            76,         2200,   "regional_jet",
  "Canadair CRJ-900",           90,         1800,   "regional_jet",
  "Embraer 190",                97,         2400,   "regional_jet",
  
  # ── Narrowbody Jets ───────────────────────────────────────────────────────
  "Boeing 717-200",            110,         2060,   "narrowbody",
  "Airbus A319",               120,         3700,   "narrowbody",
  "Airbus A319neo",            130,         3750,   "narrowbody",
  "Airbus A220-100/300",       130,         3600,   "narrowbody",
  "Boeing 737-700",            125,         3400,   "narrowbody",
  "Boeing 737-800",            162,         3100,   "narrowbody",
  "Boeing 737 MAX 8",          162,         3550,   "narrowbody",
  "Airbus A320",               150,         3300,   "narrowbody",
  "Airbus A320neo",            150,         3500,   "narrowbody",
  "Boeing 737-900ER",          180,         3200,   "narrowbody",
  "Boeing 737 MAX 9",          178,         3550,   "narrowbody",
  "Boeing 737 MAX 10",         188,         3300,   "narrowbody",
  "Airbus A321",               185,         3100,   "narrowbody",
  "Airbus A321neo",            185,         4000,   "narrowbody",
  "Airbus A321neo LR/XLR",    200,         4700,   "narrowbody",
  "Boeing 757-200",            176,         3900,   "narrowbody",
  "Boeing 757-300",            220,         3400,   "narrowbody",
  
  # ── Widebody Jets ─────────────────────────────────────────────────────────
  "Boeing 767-300ER",          218,         6100,   "widebody",
  "Boeing 767-400ER",          245,         5600,   "widebody",
  "Airbus A330-200",           250,         7250,   "widebody",
  "Airbus A330-300",           290,         6350,   "widebody",
  "Airbus A330-900neo",        260,         8150,   "widebody",
  "Boeing 777-200ER",          290,         7700,   "widebody",
  "Boeing 777-300ER",          350,         7370,   "widebody",
  "Boeing 787-8",              242,         8500,   "widebody",
  "Boeing 787-9",              296,         7600,   "widebody",
  "Boeing 787-10",             330,         6430,   "widebody"
)

# Write to DuckDB for reference
con <- dbConnect(duckdb(), here("data", "airline.duckdb"))
dbWriteTable(con, "aircraft_performance", aircraft_performance, overwrite = TRUE)
message("aircraft_performance written: ", nrow(aircraft_performance), " rows")
dbDisconnect(con, shutdown = TRUE)

save(aircraft_performance, file = here("data/aircraft_performance.rda"))
