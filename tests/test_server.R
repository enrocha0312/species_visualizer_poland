library(testthat)
library(shinytest2) 
library(DBI)
library(data.table)

test_that("generate map action works", {
  app <- AppDriver$new("../../app.R") 
  
  # generate map by button
  app$set_inputs(generate_map = 1)
  
  # verify the map
  expect_true(!is.null(app$get_value(output = "mapOutput")))
  
  # verify the line graphic
  expect_true(!is.null(app$get_value(output = "timeLinePlot")))
})

test_that("search species action works", {
  app <- AppDriver$new("../../app.R")
  
  # inputs
  app$set_inputs(species_input = "species_name")
  app$set_inputs(vernacular_input = "vernacular_name")
  
  app$set_inputs(search_species = 1)
  
  expect_true(!is.null(app$get_value(output = "mapOutput")))
  
  expect_true(!is.null(app$get_value(output = "timeLinePlot")))
})

test_that("search by date action works", {
  app <- AppDriver$new("../../app.R")
  
  app$set_inputs(from_date = Sys.Date() - 10)
  app$set_inputs(to_date = Sys.Date())
  
  app$set_inputs(search_by_date = 1)
  
  expect_true(!is.null(app$get_value(output = "mapOutput")))
  
  expect_true(!is.null(app$get_value(output = "timeLinePlot")))
})