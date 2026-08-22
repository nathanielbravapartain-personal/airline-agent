
# Airline Route Intelligence Agent

An end-to-end AI-powered airline strategy tool built on Bureau of Transportation
aviation data from all four quarters of 2022. 

# What it does

Ask natural language questions about airline route strategy and get data-driven 
answers backed by 2022 Bureau of Transportation Statistics data:

- **New route opportunities** — finds markets with high passenger demand and no 
  current nonstop service

- **Competitor analysis** — market share, HHI concentration, carrier profiles

- **Demand forecasting** — predicts quarterly passengers for any US domestic route

- **Fleet assignment** — optimizes aircraft type assignment using integer programming

- **Network redeployment** — identifies under performing routes where capacity 
  could be freed up

# Live Demo

[airline-agent-topaz.vercel.app](https://airline-agent-topaz.vercel.app)

# Architecture

Frontend is done with Vercel, Anthropic API for the AI agent, Plumber REST API,
all data is modeled using RStudio in combination with DuckDB. 

# Data 

- All data from 2022, only US domestic routes

- BTS DB1B Market & Coupon files — 27.8M ticket records

- BTS T-100 Domestic Segment — 408k flight segment records

# Models

- Demand Forecasting: XGBoost + RF Stacked Ensemble ---> RSQ 0.73 — explains 73% 
of variance in route-level passenger demand across unseen routes

- Route Scoring: Random Forest ---> RSQ 0.38 - directional load factor signal.
Limited by single year of data and absence of pricing features 

- Fleet Assignment: Integer Programming (ompr/GLPK) to Exact optimal solution 

# Tech Stack

- **Modeling**: R, tidymodels, stacks, ompr

- **Database**: DuckDB

- **API**: Plumber

- **Agent**: Claude API

- **Frontend**: React

- **Deployment**: Render + Vercel

# Performance

From the 2022 data the agent predicted a DEN-SJU route by United Airlines to be 
a profitable route they should open on a 737-9 MAX aircraft. United officially a
year later in 2023 opened a DEN-SJU route that they operate on a 737-9 MAX 
aircraft they still operate profitably today. 


