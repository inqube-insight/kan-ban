mainUI <- tags$div(
  id = "mainUI",
  class = "container-fluid",
  
  
  # tabsetPanel(type = 'pills', id = "main",
  #     tabPanel('Kan Ban',
  fluidRow(
    column(4,
        pickerInput("plant", label = "Plant",
              choices = c('QCL', 'BIAM','BALP','BALG'),
              selected = '',
              options = pickerOptions(actionsBox = F, liveSearch = T),
              multiple = F)
    )
  ),
        reactableOutput('data.tbl') 
      
  #     )
  # )
  
  
)
