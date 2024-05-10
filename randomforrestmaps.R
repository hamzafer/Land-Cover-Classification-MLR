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

#loading the csv with the training areas
training <- read.table("training.csv", header = TRUE, sep = ",")

#removing the column with row IDs
training <- dplyr::select(training, -X)

training <- cbind(training, Class_Id = ROIS$Class_Id)
