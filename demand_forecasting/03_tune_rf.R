# 03 tuning random forest

# libraries

library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

# loading objects

load(here("splits/route_train.rda"))
load(here("splits/route_folds.rda"))
load(here("recipes/rf_recipe.rda"))

# Building model

rf_spec <- rand_forest(
  mtry = tune(), min_n = tune(), trees = tune()) |>
  set_engine("ranger") |>
  set_mode("regression")

rf_wflow <- workflow() |>
  add_model(rf_spec) |>
  add_recipe(rf_recipe)

rf_params <- extract_parameter_set_dials(rf_spec) |>
  update(
    mtry = mtry(range = c(1, 6)),     
    min_n = min_n(range = c(2, 40)),
    trees = trees(range = c(300, 1000)))

set.seed(90)
rf_tune_res <- tune_grid(
  rf_wflow,
  resamples = route_folds,
  grid = 25,
  param_info = rf_params,
  metrics = metric_set(rmse, mae, rsq),
  control = control_grid(save_pred = TRUE, save_workflow = TRUE))

save(rf_tune_res, file = here("results/rf_tune_res.rda"))














