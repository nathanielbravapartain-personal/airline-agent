# 03 recipes

# libraries

library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

load(here("splits/scoring_train.rda"))

scoring_recipe <- recipe(load_factor ~ ., data = scoring_train) |>
  step_rm(route_id) |>
  step_normalize(all_numeric_predictors()) |>
  step_dummy(all_nominal_predictors()) |> 
  step_nzv(all_predictors())

scoring_recipe |>
  prep() |>
  bake(new_data = NULL)

save(scoring_recipe, file = here("recipes/scoring_recipe.rda"))



