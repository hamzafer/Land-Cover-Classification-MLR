# Land Cover Classification Using MLR

## Project Overview

This GitHub repository hosts the R scripts, analysis, and documentation for the project on land cover classification.
The project utilizes a series of machine learning models implemented exclusively with the `mlr` package in R to analyze
multi-seasonal Landsat images and Digital Terrain Models of a Mediterranean landscape.

## Objective

The goal of this project is to compare the effectiveness of several machine learning techniques, namely Classification
Trees, Artificial Neural Networks (ANNs), Support Vector Machines (SVMs), and Random Forest, in classifying land cover
types based on satellite imagery and terrain data.

## Models and Analysis

Each model was carefully tuned and evaluated based on Mean Misclassification Error (MMCE), Accuracy, and Kappa
statistics:

- **Classification Trees**: Tuned for complexity, depth, and minimum split criteria.
- **ANNs**: Evaluated across different configurations ranging from 1 to 20 hidden units.
- **SVMs**: Explored with multiple kernels including linear and radial basis functions.
- **Random Forest**: Analyzed with variations in the number of trees and features.

### Key Results

- **SVMs** provided the highest accuracy (89.7%) and Kappa (0.882), making them the most effective model in our tests.
- **Random Forest** followed with robust performance metrics (Accuracy: 85.5%, Kappa: 0.834).
- **ANNs** with 12 hidden units showed a good balance between complexity and performance (Accuracy: 81.4%, Kappa:
  0.787).
- **Classification Trees** demonstrated the least effectiveness but still performed reasonably well (Accuracy: 77.1%,
  Kappa: 0.738).

## Repository Contents

- **Scripts**: Contains the R scripts for each model's setup, execution, and evaluation.
- **Data**: Instructions for accessing and preprocessing the Landsat and DTM data.
- **Results**: Summaries and detailed performance metrics for each model.
- **Report.pdf**: A comprehensive report detailing the methodologies, results, and conclusions.

## Getting Started

### Prerequisites

Ensure you have R installed on your system, along with the required packages:

- R packages:
    - `raster`
    - `dplyr`
    - `mlr`
    - `randomForest`
    - `ggplot2`
    - `clue`

```R
install.packages(c("raster", "dplyr", "mlr", "randomForest", "ggplot2", "clue"))
```

### Installation

Clone the repository to get started with your own analysis:

```bash
git clone https://github.com/yourusername/land-cover-classification.git
```

## Acknowledgments

- Thanks to Professor Victor Francisco Rodriguez-Galiano for guidance and oversight throughout the project.
