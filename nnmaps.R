# Step 1: Load libraries
library(raster)
library(dplyr)
library(mlr)
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

# Creating the classification task for mlr
classification.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Initialize a list to store results
results <- list()

# Loop to train ANN models with different sizes of the hidden layer from 1 to 20
results <- list()  # Ensure results list is initialized correctly

for (size in 1:20) {
  # Creating a neural network learner with a single hidden layer of varying size
  learner <- makeLearner("classif.nnet", predict.type = "prob", size = size, maxit = 10000, decay = 0.01)

  # Set up 10-fold cross-validation
  rdesc <- makeResampleDesc("CV", iters = 10, stratify = TRUE)

  # Define performance measures: MMCE, accuracy, and kappa
  measures <- list(mmce, acc, kappa)

  # Perform cross-validation and save models
  res <- resample(learner, classification.task, rdesc, measures = measures, models = TRUE)
  results[[paste("HiddenUnits", size)]] <- res
  print(paste("Completed for size:", size))
}

# Extract MMCE values correctly from the results list using numeric indexing
mmce_values <- sapply(results, function(x) {
  if (is.vector(x$aggr) && !is.null(x$aggr["mmce.test.mean"])) {
    return(x$aggr["mmce.test.mean"])
  } else {
    return(NA)  # Return NA if the expected structure isn't met
  }
})

# Find the index of the minimum MMCE
if (any(!is.na(mmce_values))) {
  index_min_mmce <- which.min(mmce_values)
  # Retrieve the best model from the results
  best_model <- results[[index_min_mmce]]$models[[1]]
  print(paste("Best model hidden units:", index_min_mmce))
  print(best_model)
} else {
  print("MMCE values are not properly calculated or are all NA.")
}


# Print the results to find the best configuration based on the defined measures
for (size in names(results)) {
  cat("\nResults for", size, ":\n")
  print(results[[size]]$aggr)
}

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
pred.nn <- predict(best_model, newdata = new_data)
map.nn <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
map.nn[] <- pred.nn$data$response
plot(map.nn)

# Saving the best model
save(best_model, file = "Results/ANN_best_model.RData")

# Saving the map in tif format
writeRaster(map.nn, filename = "Results/ANN.tif", format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
