# Step 1: Load libraries
library(raster)
library(dplyr)
library(mlr)
library(randomForest)
library(ggplot2)
library(clue)

# Defining the seed for reproducibility
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

# Converting the class labels into a categorical variable
training$Class_Id <- as.factor(training$Class_Id)

# Creating the classification task
clasificacion.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Define the parameter set for hyperparameter tuning
ps.rf <- makeParamSet(
  makeIntegerParam("mtry", lower = 1, upper = 9),  # Number of variables tried at each split
  makeIntegerParam("ntree", lower = 1, upper = 1000)  # Number of trees
)

# Setup the cross-validation strategy
rdesc <- makeResampleDesc("CV", iters = 10, stratify = TRUE)  # 10-fold cross-validation

# Define the control function for tuning
ctrl <- makeTuneControlGrid()

# Define the performance measures
measures <- list(mmce, acc, kappa)  # MMCE, accuracy, and kappa

# Perform the tuning and cross-validation
res <- tuneParams("classif.randomForest", task = clasificacion.task, resampling = rdesc,
                  par.set = ps.rf, measures = measures, control = ctrl)

# Output the results of tuning
print(res)

# Setting hyperparameters based on the best model found
lrn <- setHyperPars(makeLearner("classif.randomForest", predict.type = "prob"), par.vals = res$x)

# Train the model with the entire dataset using the best parameters
modelo.rf <- train(lrn, clasificacion.task)

# Print model information
print(modelo.rf$learner.model$confusion)
print(modelo.rf$learner.model$importance)

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
pred.rf <- predict(modelo.rf, newdata = new_data)
mapa.rf <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
mapa.rf[] <- pred.rf$data$response
plot(mapa.rf)

# Saving the trained model
save(modelo.rf, file = "Results/RandomForest_model.RData")

# Saving the map in tif format
writeRaster(mapa.rf, filename = "Results/RandomForest.tif", format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
