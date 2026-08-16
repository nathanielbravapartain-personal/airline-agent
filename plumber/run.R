

library(plumber)
library(here)

source(here("plumber/startup.R"))

port <- as.integer(Sys.getenv("PORT", 8000))

pr <- plumb(here("plumber", "plumber.R"))
pr$run(host = "0.0.0.0", port = port, docs = TRUE)

