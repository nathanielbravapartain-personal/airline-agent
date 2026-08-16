#01 unzipping files

library(duckdb)
library(here)
library(tidyverse)

zip_files <- list.files(
  here("data", "route_data"), 
  pattern = "\\.zip$", 
  full.names = TRUE
)

for (z in zip_files) {
  # Extract timestamp suffix from zip filename to use as unique identifier
  timestamp <- gsub(".*_(\\d+_\\d+)\\.zip$", "\\1", basename(z))
  
  # Unzip to a temp location first
  tmp <- tempdir()
  unzip(z, exdir = tmp)
  
  # Rename using timestamp so files don't overwrite each other
  src <- file.path(tmp, "T_T100D_SEGMENT_US_CARRIER_ONLY.csv")
  dst <- here("data", "route_data", paste0("t100_segment_", timestamp, ".csv"))
  file.copy(src, dst, overwrite = TRUE)
  
  message("Extracted: ", basename(dst))
}

# Confirm all 12 landed
list.files(here("data", "route_data"), pattern = "\\.csv$")



con <- dbConnect(duckdb(), here("data", "airline.duckdb"))

dbExecute(con, "
  CREATE OR REPLACE TABLE t100_segment AS
  SELECT * FROM read_csv_auto(
    'data/route_data/t100_segment_*.csv',
    union_by_name = true,
    filename = true
  )
")

# checks
dbGetQuery(con, "SELECT COUNT(*) AS n_rows FROM t100_segment")
dbGetQuery(con, "SELECT DISTINCT MONTH FROM t100_segment ORDER BY MONTH")
dbGetQuery(con, "SELECT DISTINCT AIRCRAFT_TYPE FROM t100_segment ORDER BY AIRCRAFT_TYPE LIMIT 20")


aircraft_lookup <- tribble(
  ~aircraft_type, ~aircraft_name,             ~seats_approx, ~aircraft_class,
  # --- Small GA / Commuter (sub-600 codes) ---
  "026", "Small Piston/Turboprop",             9,  "small",
  "030", "Cessna 180",                          1,  "small",
  "033", "Cessna 185",                          1,  "small",
  "034", "Helio H-250",                         5,  "small",
  "035", "Cessna C206/207",                     6,  "small",
  "036", "Cessna 172",                          4,  "small",
  "039", "Cessna 182",                          4,  "small",
  "040", "de Havilland DHC-2 Beaver",          10,  "small",
  "042", "de Havilland DHC-3 Otter",           14,  "small",
  "079", "Piper PA-32",                          6,  "small",
  "091", "Float/Amphibious Turbine",            12,  "small",
  "094", "Land Turbine",                        12,  "small",
  "102", "Small Aircraft (Unknown)",            15,  "small",
  "110", "Beechcraft 18",                       11,  "small",
  "125", "Cessna C-402",                        10,  "small",
  "131", "Britten-Norman Islander",              9,  "small",
  "133", "Beech Queen Air",                     11,  "small",
  "150", "Curtiss C-46 Commando",               40,  "small",
  "194", "Piper PA-31 Navajo",                   9,  "small",
  "201", "Britten-Norman Trislander",           18,  "small",
  "218", "McDonnell Douglas DC-6A",             54,  "small",
  # --- Helicopters ---
  "317", "Bell Helicopter",                      6,  "helicopter",
  "325", "Agusta A-119 Koala",                   8,  "helicopter",
  "339", "Helicopter (Unknown)",                 6,  "helicopter",
  "340", "Eurocopter AS350 AStar",               6,  "helicopter",
  "355", "Hughes 500/530",                       5,  "helicopter",
  "359", "Helicopter (Unknown)",                 6,  "helicopter",
  "360", "Robinson R44",                         4,  "helicopter",
  "362", "Helicopter (Unknown)",                 6,  "helicopter",
  "364", "Helicopter (Unknown)",                 6,  "helicopter",
  "366", "Helicopter (Unknown)",                 6,  "helicopter",
  "368", "Helicopter (Unknown)",                 6,  "helicopter",
  "370", "Helicopter (Unknown)",                 6,  "helicopter",
  "390", "Sikorsky S-76",                       12,  "helicopter",
  "393", "AgustaWestland AW139",                15,  "helicopter",
  "395", "Helicopter (Unknown)",                 8,  "helicopter",
  # --- Regional Turboprops ---
  "403", "Beechcraft 1900",                     19,  "regional_turboprop",
  "404", "Beechcraft 1900C",                    19,  "regional_turboprop",
  "405", "Beechcraft 1900D",                    19,  "regional_turboprop",
  "406", "Beechcraft King Air 200/350",         14,  "regional_turboprop",
  "412", "de Havilland DHC-6 Twin Otter",       19,  "regional_turboprop",
  "415", "Saab 340",                            34,  "regional_turboprop",
  "416", "Saab 2000",                           50,  "regional_turboprop",
  "430", "ATR 42",                              48,  "regional_turboprop",
  "431", "ATR 72",                              70,  "regional_turboprop",
  "441", "Bombardier Dash 8-100",               37,  "regional_turboprop",
  "442", "Bombardier Dash 8-200",               37,  "regional_turboprop",
  "449", "Bombardier Dash 8-300",               50,  "regional_turboprop",
  "455", "Bombardier Q400 (Dash 8-400)",        78,  "regional_turboprop",
  "456", "CASA/IPTN CN-235",                    36,  "regional_turboprop",
  "458", "Turboprop (Unknown)",                 30,  "regional_turboprop",
  "459", "Turboprop (Unknown)",                 30,  "regional_turboprop",
  "479", "Pilatus PC-12",                        9,  "regional_turboprop",
  "482", "Let L-410 Turbolet",                  19,  "regional_turboprop",
  "483", "Cessna 208 Caravan",                   9,  "regional_turboprop",
  "484", "Cessna 208B Grand Caravan",           14,  "regional_turboprop",
  "485", "CASA C-212",                          24,  "regional_turboprop",
  "489", "Turboprop (Unknown)",                 30,  "regional_turboprop",
  "515", "Turboprop (Unknown)",                 19,  "regional_turboprop",
  "530", "Turboprop (Unknown)",                 19,  "regional_turboprop",
  "556", "Turboprop (Unknown)",                 30,  "regional_turboprop",
  "575", "Turboprop (Unknown)",                 30,  "regional_turboprop",
  # --- Regional Jets ---
  "609", "Bombardier Challenger 300",           19,  "regional_jet",
  "629", "Canadair CRJ-200",                    50,  "regional_jet",
  "631", "Canadair CRJ-700",                    70,  "regional_jet",
  "632", "Dornier 328JET",                      32,  "regional_jet",
  "635", "McDonnell Douglas DC-9-15",           90,  "regional_jet",
  "636", "Cessna Citation II",                  10,  "regional_jet",
  "638", "Canadair CRJ-900",                    90,  "regional_jet",
  "639", "Cessna CitationJet",                   8,  "regional_jet",
  "641", "Gulfstream III/IV",                   19,  "regional_jet",
  "642", "Raytheon Hawker 400XP",               10,  "regional_jet",
  "646", "Cessna Citation X",                   12,  "regional_jet",
  "647", "Cessna Citation X CE750",             12,  "regional_jet",
  "648", "Gulfstream G200",                     10,  "regional_jet",
  "651", "Gulfstream G150",                      8,  "regional_jet",
  "652", "Bombardier Challenger 601",           19,  "regional_jet",
  "653", "Cessna Citation Sovereign",           12,  "regional_jet",
  "658", "Bombardier Global Express",           16,  "regional_jet",
  "665", "Hawker Siddeley 125",                 14,  "regional_jet",
  "667", "Gulfstream V/550",                    18,  "regional_jet",
  "669", "Bombardier Challenger 604/605",       19,  "regional_jet",
  "671", "Gulfstream G450",                     16,  "regional_jet",
  "673", "Embraer ERJ-175",                     76,  "regional_jet",
  "674", "Embraer ERJ-135",                     37,  "regional_jet",
  "675", "Embraer ERJ-145",                     50,  "regional_jet",
  "677", "Embraer 170",                         70,  "regional_jet",
  "678", "Embraer 190",                         97,  "regional_jet",
  "681", "Dassault Falcon 20",                  14,  "regional_jet",
  "682", "Dassault Falcon 2000EX",              10,  "regional_jet",
  "685", "Cessna Citation Mustang/Excel",       12,  "regional_jet",
  "770", "Dassault Falcon 900",                 15,  "regional_jet",
  "771", "Dassault Falcon 50",                  12,  "regional_jet",
  "774", "Dassault Falcon 2000",                10,  "regional_jet",
  "775", "Dassault Falcon 7X",                  14,  "regional_jet",
  # --- Narrowbody Jets ---
  "608", "Boeing 717-200",                     110,  "narrowbody",
  "612", "Boeing 737-700",                      125,  "narrowbody",
  "614", "Boeing 737-800",                      162,  "narrowbody",
  "616", "Boeing 737-500",                      100,  "narrowbody",
  "617", "Boeing 737-400",                      150,  "narrowbody",
  "619", "Boeing 737-300",                      128,  "narrowbody",
  "620", "Boeing 737-100/200",                  100,  "narrowbody",
  "634", "Boeing 737-900",                      177,  "narrowbody",
  "640", "McDonnell Douglas DC-9-30",           100,  "narrowbody",
  "645", "McDonnell Douglas DC-9-40",           109,  "narrowbody",
  "650", "McDonnell Douglas DC-9-50",           122,  "narrowbody",
  "655", "McDonnell Douglas MD-80 Series",      142,  "narrowbody",
  "694", "Airbus A320",                         150,  "narrowbody",
  "695", "Airbus A300-B2",                      250,  "narrowbody",
  "698", "Airbus A319",                         120,  "narrowbody",
  "699", "Airbus A321",                         185,  "narrowbody",
  "715", "Boeing 727-200",                      150,  "narrowbody",
  "888", "Boeing 737-900ER",                    180,  "narrowbody",
  "833", "Airbus A220-100/300",                 130,  "narrowbody",  # added post-2021
  "837", "Boeing 737 MAX 8",                    162,  "narrowbody",  # added post-2021
  "838", "Boeing 737 MAX 9",                    178,  "narrowbody",  # added post-2021
  "839", "Boeing 737 MAX 10",                   188,  "narrowbody",  # added post-2021
  # --- Widebody Jets ---
  "622", "Boeing 757-200",                      176,  "widebody",
  "623", "Boeing 757-300",                      220,  "widebody",
  "624", "Boeing 767-400ER",                    245,  "widebody",
  "625", "Boeing 767-200ER",                    224,  "widebody",
  "626", "Boeing 767-300ER",                    218,  "widebody",
  "627", "Boeing 777-200ER",                    290,  "widebody",
  "637", "Boeing 777-300ER",                    350,  "widebody",
  "683", "Boeing 777F (Freighter)",             000,  "widebody",
  "687", "Airbus A330-300",                     290,  "widebody",
  "688", "Airbus A330-900neo",                  260,  "widebody",  # uncertain
  "691", "Airbus A300-600",                     250,  "widebody",
  "696", "Airbus A330-200",                     250,  "widebody",
  "721", "Boeing 757/767 Variant",              200,  "widebody",  # uncertain
  "722", "Boeing 757/767 Variant",              200,  "widebody",  # uncertain
  "723", "Boeing 757/767 Variant",              200,  "widebody",  # uncertain
  "724", "Boeing 757/767 Variant",              200,  "widebody",  # uncertain
  "732", "McDonnell Douglas DC-10-30",          270,  "widebody",
  "740", "McDonnell Douglas MD-11",             285,  "widebody",
  "748", "Widebody (Unknown)",                  250,  "widebody",
  "750", "Widebody (Unknown)",                  250,  "widebody",
  "751", "Widebody (Unknown)",                  250,  "widebody",
  "788", "Boeing 787-10",                       330,  "widebody",  # uncertain
  "819", "Boeing 747-400",                      416,  "widebody",
  "820", "Boeing 747-400F (Freighter)",           0,  "widebody",
  "821", "Boeing 747-8",                        467,  "widebody",
  "887", "Boeing 787-8",                        242,  "widebody",
  "889", "Boeing 787-9",                        296,  "widebody"
)

# Write to DuckDB
dbWriteTable(con, "aircraft_lookup", aircraft_lookup, overwrite = TRUE)

# Verify join coverage — find any codes in T100 not in lookup
dbGetQuery(con, "
  SELECT DISTINCT t.AIRCRAFT_TYPE 
  FROM t100_segment t
  LEFT JOIN aircraft_lookup a ON t.AIRCRAFT_TYPE = a.aircraft_type
  WHERE a.aircraft_type IS NULL
  ORDER BY CAST(t.AIRCRAFT_TYPE AS INTEGER)
")

# fixing errors

aircraft_lookup <- aircraft_lookup |>
  mutate(
    aircraft_class = case_when(
      aircraft_type == "622" ~ "narrowbody",   # 757-200 — single aisle
      aircraft_type == "623" ~ "narrowbody",   # 757-300 — single aisle
      TRUE ~ aircraft_class
    ),
    aircraft_name = case_when(
      aircraft_type == "821" ~ "Boeing 747-8F (Atlas Air Cargo)",
      aircraft_type == "688" ~ "Airbus A330-900neo",
      aircraft_type == "788" ~ "Boeing 787-10",
      TRUE ~ aircraft_name
    )
  )

# Overwrite in DuckDB with corrected version
dbWriteTable(con, "aircraft_lookup", aircraft_lookup, overwrite = TRUE)

# Quick sanity check on the corrected entries
aircraft_lookup |>
  filter(aircraft_type %in% c("622", "623", "688", "788", "821")) |>
  select(aircraft_type, aircraft_name, aircraft_class, seats_approx)

# Building route summary

dbExecute(con, "
  CREATE OR REPLACE TABLE t100_route_summary AS
  SELECT
    t.ORIGIN AS origin,
    t.DEST AS dest,
    t.YEAR AS year,
    t.QUARTER AS quarter,
    t.CARRIER AS carrier,
    t.CARRIER_NAME AS carrier_name,
    a.aircraft_name,
    a.aircraft_class,
    a.seats_approx,
    SUM(t.DEPARTURES_PERFORMED) AS total_departures,
    SUM(t.SEATS) AS total_seats_deployed,
    SUM(t.PASSENGERS) AS total_passengers_t100,
    ROUND(SUM(t.PASSENGERS) / NULLIF(SUM(t.SEATS), 0), 3) AS load_factor,
    AVG(t.DISTANCE) AS avg_distance
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

dbGetQuery(con, "SELECT COUNT(*) AS n_rows FROM t100_route_summary")

# Check by departures AND by passengers to get the full picture
dbGetQuery(con, "SELECT origin, dest, carrier_name, aircraft_name, 
                 total_departures, total_passengers_t100, load_factor, avg_distance
                 FROM t100_route_summary 
                 ORDER BY total_passengers_t100 DESC LIMIT 10")

# Rebuild route_summary for nonstop markets only
# MktCoupons = 1 means the passenger flew nonstop (no connections)
dbExecute(con, "
  CREATE OR REPLACE TABLE route_summary_nonstop AS
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
    AND BulkFare = 0
    AND ItinGeoType = 1
    AND MktCoupons = 1         -- nonstop markets only
  GROUP BY Origin, Dest, Year, Quarter
")

dbGetQuery(con, "SELECT COUNT(*) AS n_rows FROM route_summary_nonstop")

dbExecute(con, "
  CREATE OR REPLACE TABLE route_scoring_data AS

  WITH t100_route AS (
    SELECT
      origin, dest, year, quarter,
      SUM(total_departures)      AS total_departures,
      SUM(total_seats_deployed)  AS total_seats_deployed,
      SUM(total_passengers_t100) AS total_passengers_t100,
      ROUND(SUM(total_passengers_t100) /
            NULLIF(SUM(total_seats_deployed), 0), 3) AS load_factor,
      AVG(avg_distance)          AS avg_distance,
      COUNT(DISTINCT carrier)    AS num_operators,
      FIRST(aircraft_class ORDER BY total_departures DESC) AS primary_aircraft_class
    FROM t100_route_summary
    WHERE aircraft_class NOT IN ('small', 'helicopter')
      AND total_passengers_t100 > 0
    GROUP BY origin, dest, year, quarter
  )

  SELECT
    origin, dest, year, quarter,
    load_factor,                 -- target
    avg_distance,
    num_operators,
    total_departures,
    primary_aircraft_class,
    CAST(quarter AS VARCHAR) AS quarter_chr
  FROM t100_route
  WHERE load_factor BETWEEN 0.05 AND 1.0   -- exclude near-zero and impossible values
")

dbGetQuery(con, "SELECT COUNT(*) AS n_rows FROM route_scoring_data")

dbGetQuery(con, "
  SELECT
    ROUND(AVG(load_factor), 3) AS avg_lf,
    ROUND(PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY load_factor), 3) AS p25,
    ROUND(PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY load_factor), 3) AS p50,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY load_factor), 3) AS p75,
    ROUND(STDDEV(load_factor), 3) AS std_lf
  FROM route_scoring_data
")

# Distribution across aircraft classes
dbGetQuery(con, "
  SELECT
    primary_aircraft_class,
    COUNT(*) AS n_routes,
    ROUND(AVG(load_factor), 3) AS avg_lf
  FROM route_scoring_data
  GROUP BY primary_aircraft_class
  ORDER BY n_routes DESC
")
