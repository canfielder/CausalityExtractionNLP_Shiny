#' The following script is used to load and install all libraries used.

install_packages <- function(){
  
  if (!require("DT")) install.packages("DT")
  if (!require("fastTextR")) install.packages("fastTextR")
  if (!require("lime")) install.packages("lime")
  if (!require("readxl")) install.packages("readxl")
  if (!require("dplyr")) install.packages("tidyverse")
  if (!require("reticulate")) install.packages("reticulate")
  if (!require("shinycssloaders")) install.packages("shinycssloaders")
  if (!require("shiny")) install.packages("shiny")
}

import_packages <- function(){
  library(DT)
  library(fastTextR)
  library(lime)
  library(readxl)
  library(reticulate)
  library(shiny)
}
