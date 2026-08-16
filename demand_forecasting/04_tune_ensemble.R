#04 tuning ensemble model

# libraries

library(tidyverse)
library(here)
library(tidymodels)
library(stacks)

tidymodels_prefer()

# loading objects

load(here("splits/route_train.rda"))
load(here("splits/route_folds.rda"))
load(here("results/xgb_tune_res.rda"))
load(here("results/rf_tune_res.rda"))

# Building the stack

route_stack <- stacks() |>
  add_candidates(xgb_tune_res) |>
  add_candidates(rf_tune_res)

# Fitting the model

route_stack_fit <- route_stack |>
  blend_predictions(
    penalty = 10^seq(-5, -0.5, length = 20),
    metrics = metric_set(rmse))

# Inspect blend weights

autoplot(route_stack_fit)
autoplot(route_stack_fit, type = "weights")

# Fit the member models on the full training data

route_stack_final <- route_stack_fit |>
  fit_members()

save(route_stack_final, file = here("results/route_stack_final.rda"))



