#06 analysis of final model

# libraries

library(tidyverse)
library(here)
library(tidymodels)

tidymodels_prefer()

# loading objects

load(here("results/test_preds.rda"))
load(here("results/route_stack_final.rda"))

# Final metrics summary

test_preds |>
  metrics(truth = total_passengers, estimate = .pred)

# Where does the model struggle most?
# Look at routes with largest absolute errors

test_preds |>
  mutate(abs_error = abs(total_passengers - .pred)) |>
  arrange(desc(abs_error)) |>
  select(origin, dest, quarter, total_passengers, .pred, abs_error) |>
  head(20)

# Underpredict vs overpredict breakdown

test_preds |>
  mutate(
    residual = total_passengers - .pred,
    direction = if_else(residual > 0, "Underpredicted", "Overpredicted")
  ) |>
  count(direction) |>
  mutate(pct = n / sum(n))

# Residual plot

test_preds |>
  mutate(residual = total_passengers - .pred) |>
  ggplot(aes(x = .pred, y = residual)) +
  geom_point(alpha = 0.2, size = 0.8) +
  geom_hline(yintercept = 0, color = "red", linetype = "dashed") +
  geom_smooth(se = FALSE, color = "steelblue") +
  labs(
    title = "Residuals vs Predicted — Demand Forecasting Ensemble",
    subtitle = "Test set | RMSE: 362 | RSQ: 0.730 | MAE: 64",
    x = "Predicted Passengers",
    y = "Residual (Actual - Predicted)")

# Predicted vs actual

test_preds |>
  ggplot(aes(x = total_passengers, y = .pred)) +
  geom_point(alpha = 0.2, size = 0.8) +
  geom_abline(color = "red", linetype = "dashed") +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title = "Predicted vs Actual Passengers — Test Set",
    subtitle = "Log scale to handle right tail",
    x = "Actual Passengers",
    y = "Predicted Passengers")






