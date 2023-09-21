library(shiny)
library(tidyverse)
library(lubridate)
library(janitor)
library(arrow)
library(shinyWidgets)
library(shinyjs)
library(shinycssloaders)
library(reactable)
library(scales)
library(shinythemes)
library(RMySQL)
library(rsconnect)
library(readxl)
library(qrcode)
library(rsvg)
library(utils)
library(fs)
library(ggplot2)
library(openxlsx)
library(glue)
library(shinyalert)
library(shinydashboard)
library(vecsets)
library(tippy)
library(stringr)


killDbConnections <- function () {
  
  all_cons <- dbListConnections(MySQL())
  
  print(all_cons)
  
  for(con in all_cons)
    +  dbDisconnect(con)
  
  print(paste(length(all_cons), " connections killed."))
  
}

killDbConnections()

conQCL <-dbConnect(RMySQL::MySQL(), dbname='production', host='172.33.2.5', port=3306, user='admin', password='78dc9f95e20637c7bcfd86b94685e800c7998cb97cc2321d')

conMINU <-dbConnect(RMySQL::MySQL(), dbname='productionminu', host='172.33.2.5', port=3306, user='admin', password='78dc9f95e20637c7bcfd86b94685e800c7998cb97cc2321d')

conPOL <-dbConnect(RMySQL::MySQL(), dbname='polonnaruwa', host='172.33.2.5', port=3306, user='admin', password='78dc9f95e20637c7bcfd86b94685e800c7998cb97cc2321d')

conGIR <-dbConnect(RMySQL::MySQL(), dbname='girithale', host='172.33.2.5', port=3306, user='admin', password='78dc9f95e20637c7bcfd86b94685e800c7998cb97cc2321d')


con <- conPOL

source('server.R')
source('ui.R')
source('indentUI.R')
source('mainUI.R')


shinyApp(ui = ui, server = server)