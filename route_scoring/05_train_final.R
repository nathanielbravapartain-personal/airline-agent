# 05_train_final.R — route scoring

library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

load(here("splits/scoring_train.rda"))
load(here("splits/scoring_test.rda"))
load(here("results/scoring_rf_tune_res.rda"))

# Extract best parameters
best_params <- select_best(rf_tune_res, metric = "rmse")

# Rebuild recipe and spec
scoring_recipe <- recipe(load_factor ~ ., data = scoring_train) |>
  step_rm(route_id) |>
  step_normalize(all_numeric_predictors()) |>
  step_dummy(all_nominal_predictors()) |>
  step_nzv(all_predictors())

rf_spec <- rand_forest(
  mtry  = best_params$mtry,
  min_n = best_params$min_n,
  trees = best_params$trees
) |>
  set_engine("ranger") |>
  set_mode("regression")

final_wflow <- workflow() |>
  add_model(rf_spec) |>
  add_recipe(scoring_recipe)

# Fit on full training data
final_fit <- fit(final_wflow, data = scoring_train)

# Evaluate on held-out test set
test_preds <- scoring_test |>
  bind_cols(predict(final_fit, new_data = scoring_test)) |>
  mutate(.pred = pmax(0.05, pmin(1.0, .pred)))  # clip to valid range

final_metrics <- test_preds |>
  metrics(truth = load_factor, estimate = .pred)

final_metrics

save(final_fit, file = here("results/scoring_final_fit.rda"))
save(test_preds, file = here("results/scoring_test_preds.rda"))

