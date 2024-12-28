source("modules/tableModule.R")
library(duckdb)
library(shiny)
library(DBI)
library(data.table)
library(leaflet)
library(leaflet.extras)
library(DT)
library(htmltools)
library(shinyalert)
library(sass)
library(shinyjs)

con <- dbConnect(duckdb::duckdb(), ":memory:")
filtered_file_path <- "occurence_poland.csv"
occurences <- fread(filtered_file_path)
dbWriteTable(con, "occurences_db", occurences, append = FALSE, row.names = FALSE)

ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  titlePanel("Species Visualizer"),
  sidebarLayout(
    sidebarPanel(
      actionButton("generate_map", "Generate a map with all species"),
      hr(),
      textInput("species_input", "Search for a species (scientific name):", value = ""),
      textInput("vernacular_input", "Search for a species (vernacular name):", value = ""),
      actionButton("search_species", "Generate map for parameters"),
      hr(),
      dateInput("from_date", "From:", value = Sys.Date() - 30, format = "yyyy-mm-dd"),
      dateInput("to_date", "To:", value = Sys.Date(), format = "yyyy-mm-dd"),
      actionButton("search_by_date", "Do this search by date"),
      hr(),
      tableModuleUI("species_table_module")
    ),
    mainPanel(
      leafletOutput("mapOutput", height = "600px"),
      plotOutput("timeLinePlot", height = "300px")
    )
  )
)

server <- function(input, output) {
  onStop(function() {
    dbDisconnect(con, shutdown = TRUE)
  })
  
  showProgressBar <- function() {
    runjs('
      $("body").append("<div id=\'progress-container\' style=\'position: fixed; top: 50%; left: 50%; transform: translate(-50%, -50%); background-color: rgba(0, 0, 0, 0.7); padding: 20px; border-radius: 8px; z-index: 9999;\'>"+
                     "<div id=\'progress-text\' style=\'color: white; font-size: 16px; font-weight: bold;\'>Loading...</div>"+
                     "<div id=\'progress-bar\' style=\'width: 0%; height: 10px; background-color: green; margin-top: 10px; transition: width 5s ease;\'></div>"+
                     "</div>");
      $("#progress-bar").css("width", "100%");
      setTimeout(function() { 
        $("#progress-container").remove(); 
      }, 5000);  
    ')
  }
  
  hideProgressBar <- function() {
    runjs('$("#progress-container").remove();')
  }
  
  observeEvent(input$generate_map, {
    showProgressBar()
    
    species_data <- dbGetQuery(con, 
                               "SELECT scientificName, vernacularName, latitudeDecimal, longitudeDecimal, COUNT(*) as count
                              FROM occurences_db
                              WHERE latitudeDecimal IS NOT NULL AND longitudeDecimal IS NOT NULL
                              GROUP BY scientificName, vernacularName, latitudeDecimal, longitudeDecimal")
    
    species_summary <- dbGetQuery(con, 
                                  "SELECT scientificName, vernacularName, COUNT(*) as count
                                 FROM occurences_db
                                 WHERE scientificName IS NOT NULL AND vernacularName IS NOT NULL
                                 GROUP BY scientificName, vernacularName
                                 ORDER BY count DESC")
    callModule(tableModule, "species_table_module", species_summary = species_summary)
    
    poland_bounds <- list(
      lng_min = 14.0, lng_max = 24.2,
      lat_min = 49.0, lat_max = 55.0
    )
    
    leaflet(species_data) %>%
      addTiles() %>%
      addCircleMarkers(
        lng = ~longitudeDecimal, lat = ~latitudeDecimal,
        radius = ~sqrt(count) * 3,  
        color = "blue",
        stroke = TRUE,
        fillOpacity = 0.7,
        label = ~htmltools::HTML(
          paste(scientificName, ":", count)
        ),
        popup = ~htmltools::HTML(
          paste(scientificName, ":", count)
        )
      ) %>%
      addGraticule(
        interval = 1,  
        style = list(color = "gray", weight = 0.5, opacity = 0.5)
      ) %>%
      fitBounds(
        lng1 = poland_bounds$lng_min, lat1 = poland_bounds$lat_min,
        lng2 = poland_bounds$lng_max, lat2 = poland_bounds$lat_max
      ) %>%
      {output$mapOutput <- renderLeaflet(.)}
    
    timeline_data <- dbGetQuery(con, 
                                "SELECT eventDate, COUNT(*) as count
                               FROM occurences_db
                               WHERE eventDate IS NOT NULL
                               GROUP BY eventDate
                               ORDER BY eventDate ASC")
    
    output$timeLinePlot <- renderPlot({
      if (nrow(timeline_data) > 0) {
        plot(as.Date(timeline_data$eventDate), timeline_data$count, type = "l", 
             xlab = "Date", ylab = "Count", col = "blue", lwd = 2)
      }
    })
    
    hideProgressBar()
  })
  
  observeEvent(input$search_species, {
    showProgressBar()
    
    species_name <- tolower(trimws(input$species_input))  
    vernacular_name <- tolower(trimws(input$vernacular_input))  
    
    query <- sprintf(
      "SELECT latitudeDecimal, longitudeDecimal, eventDate 
       FROM occurences_db 
       WHERE (LOWER(scientificName) = '%s' OR LOWER(vernacularName) = '%s') 
       AND latitudeDecimal IS NOT NULL 
       AND longitudeDecimal IS NOT NULL 
       AND eventDate IS NOT NULL", 
      species_name, vernacular_name
    )
    
    species_data <- dbGetQuery(con, query)
    
    output$species_table <- renderDT(NULL)
    
    if (nrow(species_data) > 0) {
      leaflet_map <- leaflet(species_data) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~longitudeDecimal, lat = ~latitudeDecimal,
          radius = 5,  
          color = "red",
          stroke = TRUE,
          fillOpacity = 0.7,
          label = ~htmltools::HTML(
            paste("Latitude:", latitudeDecimal, "<br>Longitude:", longitudeDecimal)
          ),
          popup = ~htmltools::HTML(
            paste("Latitude:", latitudeDecimal, "<br>Longitude:", longitudeDecimal)
          )
        ) %>%
        setView(lng = mean(species_data$longitudeDecimal), lat = mean(species_data$latitudeDecimal), zoom = 6)
      
      output$mapOutput <- renderLeaflet(leaflet_map)
      
      timeline_data <- dbGetQuery(con, 
                                  sprintf("SELECT eventDate, COUNT(*) as count
                                           FROM occurences_db
                                           WHERE (LOWER(scientificName) = '%s' OR LOWER(vernacularName) = '%s')
                                           AND eventDate IS NOT NULL
                                           GROUP BY eventDate
                                           ORDER BY eventDate ASC", 
                                          species_name, vernacular_name))
      
      output$timeLinePlot <- renderPlot({
        if (nrow(timeline_data) > 0) {
          plot(as.Date(timeline_data$eventDate), timeline_data$count, type = "l", 
               xlab = "Date", ylab = "Count", col = "red", lwd = 2)
        }
      })
      
    } else {
      shinyalert(
        title = "Species or Vernacular not found!",
        text = "The species or vernacular name you entered could not be found in the dataset. Please try again.",
        type = "error",
        closeOnClickOutside = TRUE
      )
    }
    
    hideProgressBar()
  })
  
  observeEvent(input$search_by_date, {
    showProgressBar()
    
    from_date <- as.Date(input$from_date)
    to_date <- as.Date(input$to_date)
    
    query <- sprintf(
      "SELECT latitudeDecimal, longitudeDecimal, eventDate 
       FROM occurences_db 
       WHERE eventDate BETWEEN '%s' AND '%s'
       AND latitudeDecimal IS NOT NULL 
       AND longitudeDecimal IS NOT NULL", 
      from_date, to_date
    )
    
    species_data <- dbGetQuery(con, query)
    
    output$species_table <- renderDT(NULL)
    
    if (nrow(species_data) > 0) {
      leaflet_map <- leaflet(species_data) %>%
        addTiles() %>%
        addCircleMarkers(
          lng = ~longitudeDecimal, lat = ~latitudeDecimal,
          radius = 5,  
          color = "green",
          stroke = TRUE,
          fillOpacity = 0.7,
          label = ~htmltools::HTML(
            paste("Latitude:", latitudeDecimal, "<br>Longitude:", longitudeDecimal)
          ),
          popup = ~htmltools::HTML(
            paste("Latitude:", latitudeDecimal, "<br>Longitude:", longitudeDecimal)
          )
        ) %>%
        setView(lng = mean(species_data$longitudeDecimal), lat = mean(species_data$latitudeDecimal), zoom = 6)
      
      output$mapOutput <- renderLeaflet(leaflet_map)
      
      timeline_data <- dbGetQuery(con, 
                                  sprintf("SELECT eventDate, COUNT(*) as count
                                           FROM occurences_db
                                           WHERE eventDate BETWEEN '%s' AND '%s'
                                           AND eventDate IS NOT NULL
                                           GROUP BY eventDate
                                           ORDER BY eventDate ASC", 
                                          from_date, to_date))
      
      output$timeLinePlot <- renderPlot({
        if (nrow(timeline_data) > 0) {
          plot(as.Date(timeline_data$eventDate), timeline_data$count, type = "l", 
               xlab = "Date", ylab = "Count", col = "green", lwd = 2)
        }
      })
      
    } else {
      shinyalert(
        title = "No Data Found for Selected Dates!",
        text = "No data was found for the selected date range. Please adjust the dates.",
        type = "error",
        closeOnClickOutside = TRUE
      )
    }
    
    hideProgressBar()
  })
}

shinyApp(ui, server)