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

#loading the csv with the training areas
training <- read.table("training.csv", header = TRUE, sep = ",")

summary(training)

# Step 2: Load the tif images

#removing the column with row identifiers
training <- select(training, -X)

#reading the tif images
summer <- brick("S2A_L1C_20160904_T30SUF_.tif")
spring <- brick("S2A_L1C_20160329_T30SUF_.tif")
autumn <- brick("S2A_L1C_20161220_T30SUF_.tif")

#making a true colour composition
plotRGB(summer, 3, 2, 1, stretch = 'hist')
plotRGB(spring, 3, 2, 1, stretch = 'hist')
plotRGB(autumn, 3, 2, 1, stretch = 'hist')

#making a false colour composition
plotRGB(summer, 7, 3, 2, stretch = 'hist')
plotRGB(spring, 7, 3, 2, stretch = 'hist')
plotRGB(autumn, 7, 3, 2, stretch = 'hist')

# Step 3

#making a stack
multiseasonal <- stack(summer, spring, autumn)
names(multiseasonal) <- c("BlueV", "GreenV", "RedV", "RedEdge1V", "RedEdge2V",
                          "RedEdge3V", "NIRV", "NIR2V", "SWIR1V", "SWIR2V",
                          "BlueP", "GreenP", "RedP", "RedEdge1P", "RedEdge2P",
                          "RedEdge3P", "NIRP", "NIR2P", "SWIR1P", "SWIR2P",
                          "BlueO", "GreenO", "RedO", "RedEdge1O", "RedEdge2O",
                          "RedEdge3O", "NIRO", "NIR2O", "SWIR1O", "SWIR2O")

#saving the stack Geotiff format
writeRaster(multiseasonal, filename = "Results/multiseasonal.tif",
            format = "GTiff", datatype = "FLT4S", overwrite = TRUE)

#applying the K-means algorithm
class.task <- makeClusterTask(data = training)
lrn <- makeLearner("cluster.kmeans", centers = 15, iter.max = 100, nstart = 5)
model.kmeans <- train(lrn, class.task)

#extracting information from the model
names(model.kmeans)
getLearnerModel(model.kmeans)
model.kmeans$learner.model$centers
model.kmeans$learner.model$size
model.kmeans$learner.model$tot.withinss
model.kmeans$learner.model$totss
model.kmeans$learner.model$betweenss
model.kmeans$learner.model$withinss

# Step 4

#applying the model to obtain the map
new_data <- as.data.frame(as.matrix(multiseasonal))
pred.kmeans <- predict(model.kmeans, newdata = new_data)
#generating a multiband image with the same number of rows and
#columns than multiseasonal image
map.kmeans15 <- multiseasonal[[1]]
# replacing the values of the monoband image
#with the dataframe predicted by the model
map.kmeans15[] <- pred.kmeans$data$response
map.kmeans15

#saving models
save(model.kmeans, file = "Results/model_kmeans.Rdata")

#saving map in Geotiff format
writeRaster(map.kmeans15, filename = "Results/kemans_15.tif", format = "GTiff", datatype = "FLT4S", overwrite = TRUE)
