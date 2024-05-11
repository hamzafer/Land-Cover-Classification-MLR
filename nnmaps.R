# Step 1: Load libraries
library(raster)
library(dplyr)
library(mlr)
library(neuralnet)  # using neuralnet for ANN
library(ggplot2)
library(clue)

# Defining the seed
set.seed(123, "L'Ecuyer")

# Load the shapefile with training areas
ROIS <- shapefile("ROIS.shp")
plot(ROIS)

# Loading the CSV with the training areas
training <- read.table("training.csv", header = TRUE, sep = ",")

# Removing the column with row IDs
training <- dplyr::select(training, -X)

# Incorporating the class labels from the vectorial file into the training data frame
training <- cbind(training, Class_Id = ROIS$Class_Id)

# Converting the class labels to factors as required by mlr
training$Class_Id <- as.factor(training$Class_Id)

# Writing the new data frame with labels
write.csv(training, file = "training_ann.csv")

# Creating the task for mlr (using factor Class_Id)
classification.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Prepare data for neuralnet (encode class labels as 0-based integers)
training_nn <- training
training_nn$Class_Id <- as.numeric(as.character(training$Class_Id)) - 1

# Training a neural network model
nn <- neuralnet(Class_Id ~ ., data = training_nn, hidden = c(5, 3), linear.output = FALSE, lifesign = "minimal")

# Printing on screen model information
print(nn)

# Opening the multiband tif
multiseasonal <- brick("multiseasonal.tif")

# Renaming the bands
names(multiseasonal) <- c("BlueV", "GreenV", "RedV", "RedEdge1V", "RedEdge2V",
                          "RedEdge3V", "NIRV", "NIR2V", "SWIR1V", "SWIR2V",
                          "BlueP", "GreenP", "RedP", "RedEdge1P", "RedEdge2P",
                          "RedEdge3P", "NIRP", "NIR2P", "SWIR1P", "SWIR2P",
                          "BlueO", "GreenO", "RedO", "RedEdge1O", "RedEdge2O",
                          "RedEdge3O", "NIRO", "NIR2O", "SWIR1O", "SWIR2O")

# Applying the model to predict the map
new_data <- as.data.frame(as.matrix(multiseasonal))
pred.nn <- compute(nn, new_data)
map.nn <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
map.nn[] <- max.col(pred.nn$net.result) - 1  # convert probabilities to class labels (0-based)
map.nn
plot(map.nn)

# Saving models
save(nn, file = "Results/ANN_model.RData")

# Saving the map in tif format
writeRaster(map.nn, filename = "Results/ANN.tif",
            format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
