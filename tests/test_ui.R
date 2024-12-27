library(testthat)
library(shinytest2)

test_that("UI elements exist", {
  app <- AppDriver$new("../../app.R")
  

  expect_true(app$has_input("species_input"))
  expect_true(app$has_input("vernacular_input"))
  expect_true(app$has_input("from_date"))
  expect_true(app$has_input("to_date"))
  

  expect_true(app$has_input("generate_map"))
  expect_true(app$has_input("search_species"))
  expect_true(app$has_input("search_by_date"))

  expect_true(app$has_output("mapOutput"))
  expect_true(app$has_output("timeLinePlot"))
})