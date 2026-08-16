# route_scoring 02

library(tidyverse)
library(here)
library(tidymodels)
library(duckdb)

tidymodels_prefer()

con <- dbConnect(duckdb(), here("data", "airline.duckdb"))

route_scoring <- dbGetQuery(con, "SELECT * FROM route_scoring_data") |>
  as_tibble()

dbDisconnect(con, shutdown = TRUE)

# Clean up types
route_scoring <- route_scoring |>
  mutate(
    quarter = factor(quarter, levels = 1:4, labels = paste0("Q", 1:4)),
    primary_aircraft_class = factor(primary_aircraft_class),
    route_id = paste(origin, dest, sep = "_")
  ) |>
  select(-origin, -dest, -year, -quarter_chr) 

glimpse(route_scoring)
summary(route_scoring$load_factor)

# Grouped split — same logic as demand model
# Hold out entire routes so model generalizes to unseen route pairs
set.seed(90)
scoring_split <- group_initial_split(route_scoring, group = route_id, prop = 0.8)
scoring_train <- training(scoring_split)
scoring_test  <- testing(scoring_split)

save(scoring_train, file = here("splits/scoring_train.rda"))
save(scoring_test,  file = here("splits/scoring_test.rda"))

# Grouped CV resamples
scoring_folds <- group_vfold_cv(scoring_train, group = route_id, v = 10)
save(scoring_folds, file = here("splits/scoring_folds.rda"))

# Quick sanity check
nrow(scoring_train)
nrow(scoring_test)
scoring_folds
