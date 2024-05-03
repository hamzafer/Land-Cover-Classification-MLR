# Step 1: Load libraries
#load libraries
library(raster)
library(dplyr)
library(mlr)
library(randomForest)
library(ggplot2)
library(clue)

#defining the seed
set.seed(123, "L'Ecuyer")

# Load the shapefile with training areas
ROIS <- shapefile("ROIS.shp")
plot(ROIS)
