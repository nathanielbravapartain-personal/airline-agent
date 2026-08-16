
FROM rocker/r-ver:4.5

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libglpk-dev \
    libgmp-dev \
    libsodium-dev \
    && rm -rf /var/lib/apt/lists/*

# Install packages individually so failures are visible
RUN R -e "install.packages('plumber',     repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('tidyverse',   repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('duckdb',      repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('tidymodels',  repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('stacks',      repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('ompr',        repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('ompr.roi',    repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('ROI.plugin.glpk', repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('glue',        repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('here',        repos='https://cran.rstudio.com/')"
RUN R -e "install.packages('jsonlite',    repos='https://cran.rstudio.com/')"

WORKDIR /app
COPY . .

EXPOSE 8000
CMD ["Rscript", "plumber/run.R"]