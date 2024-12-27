library(testthat)
library(shiny)

test_that("UI elements exist", {
  app <- shinyApp(
    ui = source("../app.R")$value,
    server = function(input, output, session) {}
  )
  

  expect_true("species_input" %in% names(app$ui))
  expect_true("vernacular_input" %in% names(app$ui))
  expect_true("from_date" %in% names(app$ui))
  expect_true("to_date" %in% names(app$ui))
  expect_true("generate_map" %in% names(app$ui))
  expect_true("search_species" %in% names(app$ui))
  expect_true("search_by_date" %in% names(app$ui))

  expect_true("mapOutput" %in% names(app$ui))
  expect_true("timeLinePlot" %in% names(app$ui))
})