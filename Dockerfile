# ------------------------------------------------------------------------------
# STAGE 1: Main {renv} image with all packages + Stan
# ------------------------------------------------------------------------------
FROM rocker/rstudio:4.4.0 AS renv-base

ARG PROJECT="datavizs24"

# Install system dependencies
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
    # Determined by {pak} with ./misc/determine-sysreqs.R
    make zlib1g-dev pandoc libssl-dev libicu-dev libcurl4-openssl-dev libnode-dev python3 libpng-dev libcairo2-dev libfontconfig1-dev libfreetype6-dev libjpeg-dev libtiff-dev libfribidi-dev libharfbuzz-dev libxml2-dev libgdal-dev gdal-bin libgeos-dev libproj-dev libsqlite3-dev libudunits2-dev libglpk-dev imagemagick libmagick++-dev gsfonts \
    # For compiling things
    build-essential \
    clang-3.6 \
    # For downloading things
    curl \
    # For Python
    python3 python3-dev python3-venv python3-pip \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Configure R globally
RUN mkdir -p /usr/local/lib/R/etc/ /usr/lib/R/etc/
RUN echo "options(renv.config.pak.enabled = FALSE, \
    repos = c(CRAN = 'https://packagemanager.posit.co/cran/latest'), \
    download.file.method = 'libcurl', \
    Ncpus = 4)" | tee /usr/local/lib/R/etc/Rprofile.site | tee /usr/lib/R/etc/Rprofile.site
RUN R -e 'install.packages("rstudioapi")'

# Copy core {renv} things into the container
RUN mkdir -p /home/rstudio/${PROJECT}/renv/cache && chown rstudio:rstudio /home/rstudio/${PROJECT}
WORKDIR /home/rstudio/${PROJECT}
COPY --chown=rstudio:rstudio ./${PROJECT}/renv.lock renv.lock
RUN echo 'source("renv/activate.R")' >> .Rprofile
COPY --chown=rstudio:rstudio ./${PROJECT}/renv/activate.R renv/activate.R
COPY --chown=rstudio:rstudio ./${PROJECT}/renv/settings.json renv/settings.json

# Change location of {renv} cache to project folder
ENV RENV_WATCHDOG_ENABLED FALSE
ENV RENV_PATHS_CACHE renv/cache

# Install all {renv} packages
RUN R -e 'renv::restore()'
RUN chown -R rstudio:rstudio renv/

# Install Quarto
ARG QUARTO_VERSION="1.5.29"
RUN curl -L -o /tmp/quarto-linux-amd64.deb https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-amd64.deb && \
    dpkg -i /tmp/quarto-linux-amd64.deb || true && \
    apt-get install -fy && \
    rm /tmp/quarto-linux-amd64.deb

# Set up Python
COPY --chown=rstudio:rstudio ./${PROJECT}/_config_python.R _config_python.R
USER rstudio
RUN Rscript _config_python.R
USER root


# # Add fonts
# COPY ./misc/fonts/libre-franklin/*.ttf /usr/share/fonts/
# RUN fc-cache -f -v

# ------------------------------------------------------------------------------
# STAGE 2: Use the pre-built image for the actual analysis + {targets} pipeline
# ------------------------------------------------------------------------------
FROM renv-base

# This .Rprofile contains commands that force RStudio server to load the analysis project by default
COPY --chown=rstudio:rstudio ./misc/Rprofile.R /home/rstudio/.Rprofile

WORKDIR /home/rstudio/${PROJECT}
