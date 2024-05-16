# Step 1: Load libraries
library(mlr)
library(kernlab)
library(raster)
library(dplyr)
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

# Converting the class labels to factors as required by mlr
training$Class_Id <- as.factor(training$Class_Id)

# Creating the classification task for mlr
classification.task <- makeClassifTask(data = training, target = "Class_Id")

# Define a parameter set for tuning
param_set <- makeParamSet(
  makeDiscreteParam("kernel", values = c("vanilladot", "rbfdot", "polydot", "tanhdot")),
  makeNumericParam("C", lower = log(0.1), upper = log(100), trafo = function(x) exp(x)),  # Log scale for C
  makeNumericParam("sigma", lower = log(0.05), upper = log(1), trafo = function(x) exp(x), requires = quote(kernel == "rbfdot")),  # Only for RBF kernel
  makeIntegerParam("degree", lower = 1, upper = 10, requires = quote(kernel == "polydot")),  # Only for polynomial kernel
  makeNumericParam("scale", lower = 1, upper = 10, requires = quote(kernel %in% c("polydot", "tanhdot")))  # Bias for poly/sigmoid
)


# Setup a tuning method, here using random search for demonstration
tune.ctrl <- makeTuneControlRandom(maxit = 100)

# Cross-validation setup
rdesc <- makeResampleDesc("CV", iters = 10, stratify = TRUE)

# Train the SVM model with tuning
tuned.result <- tuneParams("classif.ksvm", task = classification.task, resampling = rdesc,
                           par.set = param_set, control = tune.ctrl, measures = list(mmce, acc, kappa))

# Best tuned model parameters
print(tuned.result)

# Train the best model on the full dataset
svm_model <- setHyperPars(makeLearner("classif.ksvm", predict.type = "prob"), par.vals = tuned.result$x)
svm_model <- train(svm_model, classification.task)

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
pred_svm <- predict(svm_model, newdata = new_data, type = "response")
map.svm <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
map.svm[] <- as.numeric(pred_svm)  # Assign predicted values
plot(map.svm)

# Saving the trained model
save(svm_model, file = "Results/SVM_best_model.RData")

# Saving the map in tif format
writeRaster(map.svm, filename = "Results/SVM.tif", format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
