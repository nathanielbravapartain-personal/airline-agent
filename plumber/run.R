
# run.R
# Launches the Plumber API

library(plumber)
library(here)

# Source startup — loads models and database connection
source(here("plumber", "startup.R"))

# Create and run the API
pr <- plumb(here("plumber", "plumber.R"))

pr$run(
  host = "0.0.0.0",
  port = 8000,
  docs = TRUE    # enables Swagger UI at localhost:8000/__docs__
)