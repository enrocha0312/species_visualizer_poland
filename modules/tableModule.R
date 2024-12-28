tableModuleUI <- function(id) {
  ns <- NS(id) 
  DT::DTOutput(ns("species_table"))
}
tableModule <- function(input, output, session, species_summary) {
  output$species_table <- DT::renderDT({
    DT::datatable(species_summary, options = list(pageLength = 10), rownames = FALSE)
  })
}