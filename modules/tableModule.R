tableModuleUI <- function(id) {
  ns <- NS(id)
  DTOutput(ns("species_table"))
}

tableModule <- function(input, output, session, con) {
  output$species_table <- renderDT({
    species_summary <- dbGetQuery(con, 
                                  "SELECT scientificName, vernacularName, COUNT(*) as count
                                   FROM occurences_db
                                   WHERE scientificName IS NOT NULL AND vernacularName IS NOT NULL
                                   GROUP BY scientificName, vernacularName
                                   ORDER BY count DESC")
    datatable(species_summary, options = list(pageLength = 10), rownames = FALSE)
  })
}