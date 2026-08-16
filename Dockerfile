
FROM rocker/r-ver:4.5

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libglpk-dev \
    && rm -rf /var/lib/apt/lists/*

RUN R -e "install.packages(c( \
  'plumber', 'tidyverse', 'duckdb', 'tidymodels', \
  'stacks', 'ompr', 'ompr.roi', 'ROI.plugin.glpk', \
  'glue', 'here', 'jsonlite' \
), repos='https://cran.rstudio.com/', Ncpus=4)"

WORKDIR /app
COPY . .

EXPOSE 8000
CMD ["Rscript", "plumber/run.R"]
