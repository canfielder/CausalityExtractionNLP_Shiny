#' The following script is used to load and install all libraries used.
install_packages <- function(){
  
  install.packages("DT")
  install.packages("fastTextR")
  install.packages("lime")
  install.packages("readxl")
  install.packages("tidyverse")
  install.packages("reticulate")
  
}




import_packages <- function(){
  library(DT)
  library(fastTextR)
  library(lime)
  library(readxl)
  library(reticulate)
  library(shiny)
}
