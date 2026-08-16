# 03_tune_xgb.R — route scoring

# libraries

library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

# loading objects

load(here("splits/scoring_train.rda"))
load(here("splits/scoring_folds.rda"))
load(here("recipes/scoring_recipe.rda"))

# Building model

xgb_spec <- boost_tree(
  min_n = tune(), mtry = tune(),
  learn_rate = tune(), trees = tune(),
  tree_depth = tune(), loss_reduction = tune(),
  sample_size = tune()) |>
  set_engine("xgboost") |>
  set_mode("regression")
     
xgb_wflow <- workflow() |>
  add_model(xgb_spec) |>
  add_recipe(scoring_recipe)

xgb_params <- extract_parameter_set_dials(xgb_spec) |>
  update(
    mtry           = mtry(range = c(1, 9)),
    learn_rate     = learn_rate(range = c(-2, -1)),
    trees          = trees(range = c(200, 1000)),
    tree_depth     = tree_depth(range = c(3, 10)),
    min_n          = min_n(range = c(5, 40)),
    sample_size    = sample_prop(range = c(.6, .9)),
    loss_reduction = loss_reduction(range = c(-5, 1)))

set.seed(90)
xgb_tune_res <- tune_grid(
  xgb_wflow,
  resamples = scoring_folds,
  grid = 25,
  param_info = xgb_params,
  metrics = metric_set(rmse, mae, rsq),
  control = control_grid(save_pred = TRUE, save_workflow = TRUE))

save(xgb_tune_res, file = here("results", "scoring_xgb_tune_res.rda"))

load(here("results/scoring_xgb_tune_res.rda"))
