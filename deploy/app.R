# The synthcheck app for a server: Posit Connect Cloud (or shinyapps.io).
#
# This file is not part of the R package. It is the entry point a server runs.
# On your own computer, use synthcheck::run_synthcheck_app() instead: It runs
# the full app, with Ollama and keys from .Renviron.
#
# Hosted mode (switched on below) leaves Ollama out, never uses API keys from
# the server's environment, keeps each visitor's keys in their browser
# session's memory only, and deletes each session's files when it ends.
#
# The library() calls tell the server which packages to install. See the
# article "Hosting the app" (vignettes/articles/hosting.Rmd) for the steps.

library(shiny)
library(bslib)
library(synthcheck)
library(ellmer)    # Anthropic and OpenAI calls
library(callr)     # runs in the background, so the Stop button works
library(jsonlite)
library(cicerone)  # the guided tour
library(writexl)   # Excel downloads
library(readxl)    # Excel uploads
library(later)     # parallel calls
library(promises)
library(polycor)   # polychoric correlations

options(synthcheck.hosted = TRUE)

synthcheck_app(hosted = TRUE)
