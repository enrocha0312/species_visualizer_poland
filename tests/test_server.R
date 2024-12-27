library(testthat)
library(shiny)

test_that("generate map action works", {

  app <- shinyApp(
    ui = source("../app.R")$value,
    server = function(input, output, session) {}
  )

  app$set_inputs(generate_map = 1)
  

  output_map <- app$values$mapOutput
  expect_true(!is.null(output_map))
  
 
  output_line_plot <- app$values$timeLinePlot
  expect_true(!is.null(output_line_plot))
})

test_that("search species action works", {

  app <- shinyApp(
    ui = source("../app.R")$value,
    server = function(input, output, session) {}
  )
  

  app$set_inputs(species_input = "species_name")
  app$set_inputs(vernacular_input = "vernacular_name")
  

  app$set_inputs(search_species = 1)
  

  output_map <- app$values$mapOutput
  expect_true(!is.null(output_map))
  

  output_line_plot <- app$values$timeLinePlot
  expect_true(!is.null(output_line_plot))
})

test_that("search by date action works", {

  app <- shinyApp(
    ui = source("../app.R")$value,
    server = function(input, output, session) {}
  )
  

  app$set_inputs(from_date = Sys.Date() - 10)
  app$set_inputs(to_date = Sys.Date())
  

  app$set_inputs(search_by_date = 1)
  

  output_map <- app$values$mapOutput
  expect_true(!is.null(output_map))
  

  output_line_plot <- app$values$timeLinePlot
  expect_true(!is.null(output_line_plot))
})
