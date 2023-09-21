
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css?family=Inter"),
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css"),
    tags$title("Kan-Ban")
  ),
  includeCSS('www/styles.css'),
  
  # Application title
  # titlePanel(div(img(src="InQube Logo.png", height = 50),
  #                "Kan Ban",
  #                span(span(textOutput('user', inline = T), ", ",
  #                          a(href = "https://login.shinyapps.io/logout", "Logout"),
  #                          style = "float:right;"), br(),
  #                     span(span('Data Refreshed at: ', style = "font-style: italic;"), 
  #                          textOutput('tm', inline = T),
  #                          style = "float:right;"), br(),
  #                     style = 'font-size: 13px; vertical-align:middle; float:right;')
  # )
  # )
  
)