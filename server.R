server <- function(input, output, session) {
  
  output$user <- renderText(session$user)
  
  usr <- ifelse(is.null(session$user), 'datai', gsub('@.*', '', session$user))
  usr.id <- ifelse(is.null(session$user), 'datai@inqube.com', session$user)
  usr.filter <- glue("(User_x002e_Id eq '{usr.id}')") %>% URLencode()
  
  scr_width <- system("wmic desktopmonitor get screenwidth", intern=TRUE)
  screenWidth <- as.numeric(c(
    scr_width[-c(1)]
  ))  
  
  scr_height <- system("wmic desktopmonitor get screenheight", intern=TRUE)
  screenHeight <- as.numeric(c(
    scr_height[-c(1)]
  )) 
  
  next_whole <- lubridate::ceiling_date(Sys.time(), "10 seconds")
  print(format(Sys.time(), "%H:%M:%S"))
  go_singal <- reactiveVal(FALSE)

  observe({ 
    query <- parseQueryString(session$clientData$url_search)
      
      insertUI(selector = "body",
               where = 'beforeEnd',
               ui = mainUI,
               immediate = T,
               session = session)

  })
  
  observeEvent(input$gen.guide.customer, {
    
    products$gen.guide <- get_data_from_s3('General_Guidelines.parquet', 'All')
    
  })
  
  
  first_check <- observe({
    invalidateLater(10000)
    req(next_whole - Sys.time() < 0)
    go_singal(TRUE)
    first_check$destroy()
    print("destroy")
  })
  
  
  getDetails = function(){
    
    req(input$plant)
    
    if(input$plant == "QCL"){
      con <<- conQCL
    }
    else if(input$plant == "BIAM"){
      con <<- conMINU
    }
    else if(input$plant == "BALP"){
      con <<- conPOL
    }
    else if(input$plant == "BALG"){
      con <<- conGIR
    }
    else{
      print("PLEASE SELECT A PLANT TO CONTINUE")
    }
    
    now.time = Sys.time() #created.at = as.POSIXct(now('Asia/Kolkata'), format = "%Y-%m-%d %H:%M:%S")
    
    queryTodayTeams = glue::glue("SELECT t.code AS Line, SUM(dtst.planned) AS Plan_Qty FROM daily_shifts ds JOIN daily_shift_teams dst ON dst.daily_shift_id = ds.id JOIN 
                  daily_scanning_slots dss ON dss.daily_shift_id = ds.id JOIN daily_team_slot_targets dtst ON
                  dtst.daily_scanning_slot_id = dss.id AND dtst.daily_shift_team_id = dst.id
                  JOIN teams t ON t.id = dst.team_id WHERE ds.start_date_time < '{now.time}'
                  AND ds.end_date_time > '{now.time}' GROUP BY t.code")
    teamData = fetch(dbSendQuery(con,queryTodayTeams), -1)
    dbClearResult(dbListResults(con)[[1]])
    
    querySlots = glue::glue("SELECT dss.seq_no AS Slot, dss.from_date_time AS FromTime, dss.to_date_time AS ToTime FROM daily_shifts ds JOIN
                  daily_scanning_slots dss ON dss.daily_shift_id = ds.id
                  WHERE ds.start_date_time < '{now.time}'
                  AND ds.end_date_time > '{now.time}'")
    slotData = fetch(dbSendQuery(con,querySlots), -1)
    dbClearResult(dbListResults(con)[[1]])
    
    # Slot <- c(1,2,3,4,5,6,7,8,9,10,11,12)
    # slotData = data.frame(Slot)
    
    teamData <- teamData %>% filter(Line != "SAMPLE") %>% mutate(UPH = ceiling(Plan_Qty/nrow(slotData)))
    
    queryWIP = glue::glue("SELECT SUM(jcb.original_quantity) AS WIP_SMT, t.code AS Line FROM job_cards jc JOIN job_card_bundles jcb ON jcb.job_card_id = jc.id
                          JOIN teams t ON t.id = jc.team_id JOIN trim_stores ts ON ts.job_card_id = jc.id WHERE jc.status = 'Finalized' 
                          and ts.trim_status = 'Ready' GROUP BY t.code")
    WIPData = fetch(dbSendQuery(con,queryWIP), -1)
    dbClearResult(dbListResults(con)[[1]])
    
    teamData <- teamData %>% inner_join(WIPData, by = c('Line'))
    
    teamData <- teamData %>% mutate(Hours = floor(WIP_SMT/UPH), Input_Qty = 0)
    
    index = 1
    for(y in teamData$Hours){
      
      indexSlot = 1
      for(x in slotData$Slot){
        z = glue::glue("H{x}")
        
        if(x <= y){ 
          teamData[index,z] <- " "
        } 
        else{
          teamData[index,z] <- ""
        }
        
        indexSlot = indexSlot + 1
      }
      
      index = index + 1
      
    }
    
    teamData <- teamData %>% relocate(Hours,Input_Qty, .after = last_col())
    
    return (teamData)
  } 
  
  data.tbl.df <-reactive({
    getDetails()
  })
  
  output$data.tbl <- renderReactable({
    
    # req(input$plant)
    
      df = data.tbl.df()
      
      cols <- list();
      
      index = 1
      for(i in colnames(df)){
        
        if(str_detect(i, "[0-9]")){
          x = list(colDef(
            width = screenWidth[2]/(ncol(data.tbl.df())+0.5),
            align = "center",
            style = function(value) {
              color <- if_else(value == " ","#2F7D00", "#B90000")
              list(background = color, color="black",border = "0.25px solid black")
            }))
        }
        else{
          x = list(colDef(
            width = screenWidth[2]/(ncol(data.tbl.df())+0.4),
            align = "center",
            style = function(value) {
              color <- "#00052F"
              list(background = color, color="white",border = "0.25px solid black")
            }))
          
        }
        
        
        cols[index] = (x)
        index = index + 1
      }
      
      cols <- setNames(cols, names(df))
      
      reactable(df, searchable = F, highlight = T,
                filterable = F, wrap = T, outlined = T,
                showPageSizeOptions = FALSE,
                pageSizeOptions = c(10, 25, 50, 100), defaultPageSize = 50,
                sortable = T, resizable = T,
                rowStyle = list(cursor = "pointer",height=(screenHeight[[2]]-200)/nrow(df[1])),compact=T,
                theme = reactableTheme(
                  headerStyle = list(background = "#00052F", color = "white", fontWeight = "normal",border = "0.25px solid black"),
                  rowSelectedStyle = list(backgroundColor = "#AEF311", boxShadow = "inset 2px 0 0 0 #AEF311")
                ),
                style = list(fontSize = "10.5px"),
                columns = cols
      )
      
  })
  
}
  
  
  