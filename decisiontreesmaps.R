# Step 1: Load libraries
library(raster)
library(dplyr)
library(mlr)
library(rpart)  # using rpart instead of randomForest
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

# Writing the new data frame with labels
write.csv(training, file = "training_rpart.csv")

# Converting the class labels to categorical
training$Class_Id <- as.factor(training$Class_Id)

# Creating the task
classification.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Setting up parameter tuning for rpart
ps.rpart <- makeParamSet(
  makeDiscreteParam("cp", values = c(0.01, 0.05, 0.1)),
  makeIntegerParam("maxdepth", lower = 2, upper = 29),
  makeIntegerParam("minsplit", lower = 1, upper = 50)
)

ctrl <- makeTuneControlRandom(maxit = 100)  # Using random search for tuning
rdesc <- makeResampleDesc("CV", iters = 10)
res <- tuneParams("classif.rpart", task = classification.task, resampling = rdesc,
                  par.set = ps.rpart, measures = mmce, control = ctrl)
res

# Setting hyperparameters and training the model
learner <- setHyperPars(makeLearner("classif.rpart", predict.type = "prob"),
                        par.vals = res$x)
model.rpart <- train(learner, classification.task)

# Printing on screen model information
print(model.rpart$learner.model)

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
pred.rpart <- predict(model.rpart, newdata = new_data)
map.rpart <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
map.rpart[] <- pred.rpart$data$response
map.rpart
plot(map.rpart)

# Saving models
save(model.rpart, file = "Results/Rpart_model.RData")

# Saving the map in tif format
writeRaster(map.rpart, filename = "Results/Rpart.tif",
            format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
