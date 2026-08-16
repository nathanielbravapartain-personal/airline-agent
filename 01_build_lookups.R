# 00_build_lookups.R
# Defines all lookup tables from source and writes to DuckDB

library(tidyverse)
library(here)
library(duckdb)

con <- dbConnect(duckdb(), here("data", "airline.duckdb"))

# ── Aircraft Lookup ───────────────────────────────────────────────────────────

aircraft_lookup <- tribble(
  ~aircraft_type, ~aircraft_name,                          ~seats_approx, ~aircraft_class,
  
  # ── Small GA / Commuter ────────────────────────────────────────────────────
  "026", "Small Piston/Turboprop",                                  9,  "small",
  "030", "Cessna 180",                                               1,  "small",
  "033", "Cessna 185",                                               1,  "small",
  "034", "Helio H-250",                                              5,  "small",
  "035", "Cessna C206/207",                                          6,  "small",
  "036", "Cessna 172",                                               4,  "small",
  "039", "Cessna 182",                                               4,  "small",
  "040", "de Havilland DHC-2 Beaver",                               10,  "small",
  "042", "de Havilland DHC-3 Otter",                                14,  "small",
  "079", "Piper PA-32",                                              6,  "small",
  "091", "Float/Amphibious Turbine",                                12,  "small",
  "094", "Land Turbine",                                            12,  "small",
  "102", "Small Aircraft (Unknown)",                                15,  "small",
  "110", "Beechcraft 18",                                           11,  "small",
  "125", "Cessna C-402",                                            10,  "small",
  "131", "Britten-Norman Islander",                                  9,  "small",
  "133", "Beech Queen Air",                                         11,  "small",
  "150", "Curtiss C-46 Commando",                                   40,  "small",
  "194", "Piper PA-31 Navajo",                                       9,  "small",
  "201", "Britten-Norman Trislander",                               18,  "small",
  "218", "McDonnell Douglas DC-6A",                                 54,  "small",
  
  # ── Helicopters ───────────────────────────────────────────────────────────
  "317", "Bell Helicopter",                                          6,  "helicopter",
  "325", "Agusta A-119 Koala",                                       8,  "helicopter",
  "339", "Helicopter (Unknown)",                                     6,  "helicopter",
  "340", "Eurocopter AS350 AStar",                                   6,  "helicopter",
  "355", "Hughes 500/530",                                           5,  "helicopter",
  "359", "Helicopter (Unknown)",                                     6,  "helicopter",
  "360", "Robinson R44",                                             4,  "helicopter",
  "362", "Helicopter (Unknown)",                                     6,  "helicopter",
  "364", "Helicopter (Unknown)",                                     6,  "helicopter",
  "366", "Helicopter (Unknown)",                                     6,  "helicopter",
  "368", "Helicopter (Unknown)",                                     6,  "helicopter",
  "370", "Helicopter (Unknown)",                                     6,  "helicopter",
  "390", "Sikorsky S-76",                                           12,  "helicopter",
  "393", "AgustaWestland AW139",                                    15,  "helicopter",
  "395", "Helicopter (Unknown)",                                     8,  "helicopter",
  
  # ── Regional Turboprops ───────────────────────────────────────────────────
  "403", "Beechcraft 1900",                                         19,  "regional_turboprop",
  "404", "Beechcraft 1900C",                                        19,  "regional_turboprop",
  "405", "Beechcraft 1900D",                                        19,  "regional_turboprop",
  "406", "Beechcraft King Air 200/350",                             14,  "regional_turboprop",
  "412", "de Havilland DHC-6 Twin Otter",                          19,  "regional_turboprop",
  "415", "Saab 340",                                                34,  "regional_turboprop",
  "416", "Saab 2000",                                               50,  "regional_turboprop",
  "430", "ATR 42",                                                  48,  "regional_turboprop",
  "431", "ATR 72",                                                  70,  "regional_turboprop",
  "441", "Bombardier Dash 8-100",                                   37,  "regional_turboprop",
  "442", "Bombardier Dash 8-200",                                   37,  "regional_turboprop",
  "449", "Bombardier Dash 8-300",                                   50,  "regional_turboprop",
  "455", "Bombardier Q400 (Dash 8-400)",                            78,  "regional_turboprop",
  "456", "CASA/IPTN CN-235",                                        36,  "regional_turboprop",
  "458", "Turboprop (Unknown)",                                     30,  "regional_turboprop",
  "459", "Turboprop (Unknown)",                                     30,  "regional_turboprop",
  "479", "Pilatus PC-12",                                            9,  "regional_turboprop",
  "482", "Let L-410 Turbolet",                                      19,  "regional_turboprop",
  "483", "Cessna 208 Caravan",                                       9,  "regional_turboprop",
  "484", "Cessna 208B Grand Caravan",                               14,  "regional_turboprop",
  "485", "CASA C-212",                                              24,  "regional_turboprop",
  "489", "Turboprop (Unknown)",                                     30,  "regional_turboprop",
  "515", "Turboprop (Unknown)",                                     19,  "regional_turboprop",
  "530", "Turboprop (Unknown)",                                     19,  "regional_turboprop",
  "556", "Turboprop (Unknown)",                                     30,  "regional_turboprop",
  "575", "Turboprop (Unknown)",                                     30,  "regional_turboprop",
  
  # ── Regional Jets ─────────────────────────────────────────────────────────
  "609", "Bombardier Challenger 300",                               19,  "regional_jet",
  "629", "Canadair CRJ-200",                                        50,  "regional_jet",
  "631", "Canadair CRJ-700",                                        70,  "regional_jet",
  "632", "Dornier 328JET",                                          32,  "regional_jet",
  "635", "McDonnell Douglas DC-9-15",                               90,  "regional_jet",
  "636", "Cessna Citation II",                                      10,  "regional_jet",
  "638", "Canadair CRJ-900",                                        90,  "regional_jet",
  "639", "Cessna CitationJet",                                       8,  "regional_jet",
  "641", "Gulfstream III/IV",                                       19,  "regional_jet",
  "642", "Raytheon Hawker 400XP",                                   10,  "regional_jet",
  "646", "Cessna Citation X",                                       12,  "regional_jet",
  "647", "Cessna Citation X CE750",                                 12,  "regional_jet",
  "648", "Gulfstream G200",                                         10,  "regional_jet",
  "651", "Gulfstream G150",                                          8,  "regional_jet",
  "652", "Bombardier Challenger 601",                               19,  "regional_jet",
  "653", "Cessna Citation Sovereign",                               12,  "regional_jet",
  "658", "Bombardier Global Express",                               16,  "regional_jet",
  "665", "Hawker Siddeley 125",                                     14,  "regional_jet",
  "667", "Gulfstream V/550",                                        18,  "regional_jet",
  "669", "Bombardier Challenger 604/605",                           19,  "regional_jet",
  "671", "Gulfstream G450",                                         16,  "regional_jet",
  "673", "Embraer ERJ-175",                                         76,  "regional_jet",
  "674", "Embraer ERJ-135",                                         37,  "regional_jet",
  "675", "Embraer ERJ-145",                                         50,  "regional_jet",
  "677", "Embraer 170",                                             70,  "regional_jet",
  "678", "Embraer 190",                                             97,  "regional_jet",
  "681", "Dassault Falcon 20",                                      14,  "regional_jet",
  "682", "Dassault Falcon 2000EX",                                  10,  "regional_jet",
  "685", "Cessna Citation Mustang/Excel",                           12,  "regional_jet",
  "770", "Dassault Falcon 900",                                     15,  "regional_jet",
  "771", "Dassault Falcon 50",                                      12,  "regional_jet",
  "774", "Dassault Falcon 2000",                                    10,  "regional_jet",
  "775", "Dassault Falcon 7X",                                      14,  "regional_jet",
  
  # ── Narrowbody Jets ───────────────────────────────────────────────────────
  "608", "Boeing 717-200",                                         110,  "narrowbody",
  "612", "Boeing 737-700",                                         125,  "narrowbody",
  "614", "Boeing 737-800",                                         162,  "narrowbody",
  "616", "Boeing 737-500",                                         100,  "narrowbody",
  "617", "Boeing 737-400",                                         150,  "narrowbody",
  "619", "Boeing 737-300",                                         128,  "narrowbody",
  "620", "Boeing 737-100/200",                                     100,  "narrowbody",
  "622", "Boeing 757-200",                                         176,  "narrowbody",
  "623", "Boeing 757-300",                                         220,  "narrowbody",
  "634", "Boeing 737-900",                                         177,  "narrowbody",
  "640", "McDonnell Douglas DC-9-30",                              100,  "narrowbody",
  "655", "McDonnell Douglas MD-80 Series",                         142,  "narrowbody",
  "694", "Airbus A320",                                            150,  "narrowbody",
  "698", "Airbus A319",                                            120,  "narrowbody",
  "699", "Airbus A321",                                            185,  "narrowbody",
  "715", "Boeing 727-200",                                         150,  "narrowbody",
  "721", "Airbus A319neo",                                         130,  "narrowbody",  # post-2021 code
  "722", "Airbus A320neo",                                         150,  "narrowbody",  # post-2021 code
  "723", "Airbus A321neo",                                         185,  "narrowbody",  # post-2021 code
  "724", "Airbus A321neo LR/XLR",                                  200,  "narrowbody",  # post-2021 code
  "833", "Airbus A220-100/300",                                    130,  "narrowbody",  # post-2021 code
  "837", "Boeing 737 MAX 8",                                       162,  "narrowbody",  # post-2021 code
  "838", "Boeing 737 MAX 9",                                       178,  "narrowbody",  # post-2021 code
  "839", "Boeing 737 MAX 10",                                      188,  "narrowbody",  # post-2021 code
  "888", "Boeing 737-900ER",                                       180,  "narrowbody",
  
  # ── Widebody Jets ─────────────────────────────────────────────────────────
  "624", "Boeing 767-400ER",                                       245,  "widebody",
  "625", "Boeing 767-200ER",                                       224,  "widebody",
  "626", "Boeing 767-300ER",                                       218,  "widebody",
  "627", "Boeing 777-200ER",                                       290,  "widebody",
  "637", "Boeing 777-300ER",                                       350,  "widebody",
  "683", "Boeing 777F (Freighter)",                                  0,  "widebody",
  "687", "Airbus A330-300",                                        290,  "widebody",
  "688", "Airbus A330-900neo",                                     260,  "widebody",
  "691", "Airbus A300-600",                                        250,  "widebody",
  "695", "Airbus A300-B2",                                         250,  "widebody",
  "696", "Airbus A330-200",                                        250,  "widebody",
  "732", "McDonnell Douglas DC-10-30",                             270,  "widebody",
  "740", "McDonnell Douglas MD-11",                                285,  "widebody",
  "748", "Widebody (Unknown)",                                     250,  "widebody",
  "750", "Widebody (Unknown)",                                     250,  "widebody",
  "751", "Widebody (Unknown)",                                     250,  "widebody",
  "788", "Boeing 787-10",                                          330,  "widebody",
  "819", "Boeing 747-400",                                         416,  "widebody",
  "820", "Boeing 747-400F (Freighter)",                              0,  "widebody",
  "821", "Boeing 747-8F (Atlas Air Cargo)",                        467,  "widebody",
  "887", "Boeing 787-8",                                           242,  "widebody",
  "889", "Boeing 787-9",                                           296,  "widebody"
)

# Write to DuckDB
dbWriteTable(con, "aircraft_lookup", aircraft_lookup, overwrite = TRUE)
message("aircraft_lookup written: ", nrow(aircraft_lookup), " rows")

# ── Verify coverage against T-100 segment data ────────────────────────────
unmatched <- dbGetQuery(con, "
  SELECT DISTINCT t.AIRCRAFT_TYPE
  FROM t100_segment t
  LEFT JOIN aircraft_lookup a ON t.AIRCRAFT_TYPE = a.aircraft_type
  WHERE a.aircraft_type IS NULL
  ORDER BY CAST(t.AIRCRAFT_TYPE AS INTEGER)
")

if (nrow(unmatched) == 0) {
  message("✓ All aircraft type codes matched")
} else {
  message("⚠ Unmatched codes: ", paste(unmatched$AIRCRAFT_TYPE, collapse = ", "))
}

dbDisconnect(con, shutdown = TRUE)




# Connect to your full database
con_full <- dbConnect(duckdb(), here("data/airline.duckdb"))

# Create a new slim production database
con_prod <- dbConnect(duckdb(), here("data/airline_prod.duckdb"))

# Tables the API actually needs — copy each one
api_tables <- c(
  "route_summary",
  "route_summary_nonstop",
  "t100_route_summary",
  "route_scoring_data",
  "carrier_route_summary",
  "route_competition_summary",
  "carrier_network_profile",
  "aircraft_lookup",
  "aircraft_performance"
)

for (tbl in api_tables) {
  message("Copying: ", tbl)
  data <- dbGetQuery(con_full, paste("SELECT * FROM", tbl))
  dbWriteTable(con_prod, tbl, data, overwrite = TRUE)
}

dbDisconnect(con_full, shutdown = TRUE)
dbDisconnect(con_prod, shutdown = TRUE)

# Check the new size
cat("Production DB size:",
    round(file.size(here("data", "airline_prod.duckdb")) / 1e6, 1), "MB\n")
