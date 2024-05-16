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
write.csv(training, file = "training_svm.csv")

# Creating the classification task for mlr
classification.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Define SVM learner using the 'vanilladot' kernel and appropriate cost parameter
learner <- makeLearner("classif.ksvm", predict.type = "prob", kernel = "vanilladot")
learner <- setHyperPars(learner, C = 62.8)

# Setup cross-validation
rdesc <- makeResampleDesc("CV", iters = 10, stratify = TRUE)

# Define performance measures
measures <- list(mmce, acc, kappa)

# Perform the cross-validation
# Perform the cross-validation with model saving
res <- resample(learner, classification.task, rdesc, measures = measures, models = TRUE)
print(res)

# Check if models are saved
if (!is.null(res$models)) {
  # Extract the index of the model with the minimum MMCE
  index_min_mmce <- which.min(res$measures.test$mmce)
  # Extract the best model based on the minimum MMCE
  best_model <- res$models[[index_min_mmce]]
  print(best_model)
} else {
  stop("No models were saved during resampling.")
}
print(res)

# Extract the trained model (best model from cross-validation)
best_model <- getLearnerModel(res$models[[which.min(res$measures.test$mmce)]])

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
pred_svm <- predict(best_model, newdata = new_data, type = "response")
map.svm <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
map.svm[] <- as.numeric(pred_svm)  # Assign predicted values
plot(map.svm)

# Saving the trained model
save(best_model, file = "Results/SVM_best_model.RData")

# Saving the map in tif format
writeRaster(map.svm, filename = "Results/SVM.tif",
            format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
