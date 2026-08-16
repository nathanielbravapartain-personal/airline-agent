# 02 recipes - demand forecasting

# Libraries
library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

# Data loading
load(here("splits/route_train.rda"))

##############################################################
## Boosted Tree(s) ############################################
##############################################################

bt_recipe <- recipe(total_passengers ~ ., data = route_train) |>
  step_rm(origin, dest, route_id, year, total_revenue) |>
  step_normalize(all_numeric_predictors()) |>  
  step_dummy(quarter) |>                         
  step_nzv(all_predictors())

bt_recipe |>
  prep() |>
  bake(new_data = NULL)

save(bt_recipe, file = here("recipes/bt_recipe.rda"))

##############################################################
## Random Forest #############################################
##############################################################

rf_recipe <- recipe(total_passengers ~ ., data = route_train) |>
  step_rm(origin, dest, route_id, year, total_revenue) |>
  step_normalize(all_numeric_predictors()) |>
  step_dummy(quarter) |>
  step_nzv(all_predictors())

rf_recipe |> 
  prep() |> 
  bake(new_data = NULL)

save(rf_recipe, file = here("recipes/rf_recipe.rda"))


