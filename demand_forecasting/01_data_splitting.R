# 01 data splitting script

# libraries

library(tidyverse)
library(here)
library(tidymodels)
library(duckdb)

tidymodels_prefer()

con <- dbConnect(duckdb(), here("data/demand_data", "airline.duckdb"))

route_summary <- dbGetQuery(con, "SELECT * FROM route_summary") |>
  as_tibble()

dbDisconnect(con, shutdown = TRUE)

route_summary <- route_summary |>
  mutate(
    quarter  = factor(quarter, levels = 1:4, labels = paste0("Q", 1:4)),
    route_id = paste(origin, dest, sep = "_")
  )


# Grouped split — entire routes go to train OR test, never both,
# so test performance reflects genuinely unseen routes

set.seed(90)
route_split <- group_initial_split(route_summary, group = route_id, prop = 0.8)
route_train <- training(route_split)
route_test  <- testing(route_split)

save(route_train, file = here("splits/route_train.rda"))
save(route_test,  file = here("splits/route_test.rda"))

# Grouped CV resamples — same logic as the split above
route_folds <- group_vfold_cv(route_train, group = route_id, v = 10)

save(route_folds, file = here("splits/route_folds.rda"))



