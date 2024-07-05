# Read the renv.lock file and use {pak} to determine which system dependencies
# Docker needs to install before installing R packages

if (!require("pacman")) {
  install.packages("pacman")
}

pacman::p_load(
  "dockerfiler",
  "renv",
  "pak",
  "here",
  install = TRUE
)

renv_file <- here::here("~/Sites/courses/datavizs23/renv.lock")
# renv_file <- here::here("datavizs24/renv.lock")

# This takes a while...
dock <- dockerfiler::dock_from_renv(
  renv_file,
  FROM = "rocker/rstudio", AS = "renv-base",
  repos = c(
    CRAN = "https://packagemanager.posit.co/cran/latest"
  ),
  use_pak = TRUE
)
dock
