#05 training final model - demand forecasting

# libraries

library(tidyverse)
library(here)
library(tidymodels)
library(stacks)

tidymodels_prefer()

# loading objects

load(here("splits/route_train.rda"))
load(here("splits/route_test.rda"))
load(here("results/route_stack_final.rda"))

# Predict on test set

test_preds <- route_test |>
  bind_cols(predict(route_stack_final, new_data = route_test))

# Final held-out metrics

final_metrics <- test_preds |>
  metrics(truth = total_passengers, estimate = .pred)

final_metrics

# Residual plot — look for systematic bias

test_preds |>
  mutate(residual = total_passengers - .pred) |>
  ggplot(aes(x = .pred, y = residual)) +
  geom_point(alpha = 0.3) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  labs(
    title = "Residuals vs Predicted — Demand Forecasting Ensemble",
    x = "Predicted Passengers",
    y = "Residual (Actual - Predicted)"
  )

# Predicted vs actual plot

test_preds |>
  ggplot(aes(x = total_passengers, y = .pred)) +
  geom_point(alpha = 0.3) +
  geom_abline(color = "red", linetype = "dashed") +
  labs(
    title = "Predicted vs Actual Passengers — Test Set",
    x = "Actual Passengers",
    y = "Predicted Passengers"
  )

save(test_preds, file = here("results/test_preds.rda"))



























