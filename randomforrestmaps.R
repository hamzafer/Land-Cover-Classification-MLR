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

# Incorporating the class labels from the vectorial file into the training data frame
training <- cbind(training, Class_Id = ROIS$Class_Id)

# Writing the new data frame with labels
write.csv(training, file = "training_RF.csv")

# converting the class labels in categorical
training$Class_Id <- as.factor(training$Class_Id)

# Creating the task
clasificacion.task <- makeClassifTask(id = "nieves", data = training, target = "Class_Id")

# Tuning the hyperparameters; mtry is typically close to sqrt(number of features)
ps.rf <- makeParamSet(
    makeDiscreteParam("mtry", values = c(3:6)),
    makeDiscreteParam("ntree", values = c(1000, 5000, 10000))
)

ctrl <- makeTuneControlGrid()
rdesc <- makeResampleDesc("CV", iters = 10)
res <- tuneParams("classif.randomForest", task = clasificacion.task, resampling = rdesc,
                  par.set = ps.rf, measures = mmce, control = ctrl)
res

# Setting hyperparameters and training the model
lrn <- setHyperPars(makeLearner("classif.randomForest", predict.type = "prob"),
                    par.vals = res$x, importance = TRUE)
modelo.rf <- train(lrn, clasificacion.task)

# Printing on screen model information
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
pred.rf <- predict(modelo.rf, newdata=new_data)
mapa.rf <- multiseasonal[[1]]  # Using the first layer as a template for dimensions
mapa.rf[] <- pred.rf$data$Response
mapa.rf

# Saving models
save(modelo.rf, file="Results/RandomForest_model.RData")

# Saving the map in tif format
writeRaster(mapa.rf, filename = "Results/RandomForest.tif",
            format="GTiff", datatype = "FLT4S", overwrite = TRUE)
