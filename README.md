# Some informations

## About the methods for map visualization

* There are three functions for visualizing the data. One is to see all species and observations in the country Poland. Another is to filter by vernacularName and scientificName, and the other one uses also the date from of the observations
* A plot with timeline is generated for all the observations every time you click the button for a specific observation

## Unit tests

They are in a folder tests. I'm sorry for not having time to explore more the tests, I've just created the basic tests

## Modules

I confess I haven't read that the application should be decomposed into shiny modules. I've had just the time to create a module for table module, but it would be a good practice creating a module for the map functions and other for the progress bar. 

## CSS and JS

I've just created a CSS for a modern design, not so deeply worked. The JS is just to have javascript manipulating DOM elements

## About the file

I've filtered the file for Poland. I had to use Linux due to its speed for this kind of process. My code for generate this command:


file_path = "occurence.csv"
tabela_teste = fread("occurence.csv", nrows=5)
filter_column <- "country"
filter_value <- "Poland"
filtered_file_path <- "occurence_poland.csv"
col_index <- which(colnames(fread(file_path, nrows = 1)) == filter_column)

cmd <- sprintf('awk -F, \'NR==1 || $%d == "%s"\' %s > %s',
               col_index, filter_value, file_path, filtered_file_path)

* By generating this cmd command, I've just used the git bash for filtering the file.

## Host on Shiny Apps

https://enrtechnologyandknowledge.shinyapps.io/speciesinpoland/