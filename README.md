# Color Mapping Project

## Overview

This project uses K-means clustering to analyze multiseasonal imagery data for color mapping. The main objective is to
classify different geographical areas based on spectral signatures, allowing us to identify and distinguish unique
patterns and features in the data. This process is implemented in RStudio using several packages to manage and analyze
spatial data.

## Getting Started

### Prerequisites

- RStudio
- R packages:
    - `raster`
    - `dplyr`
    - `mlr`
    - `randomForest`
    - `ggplot2`
    - `clue`

### Installation

1. Install the necessary R packages if you haven't already:
    ```R
    install.packages(c("raster", "dplyr", "mlr", "randomForest", "ggplot2", "clue"))
    ```

2. Clone this repository or download the source code:
    ```bash
    git clone [repository-url]
    ```

### Usage

1. Load the project in RStudio.
2. Open the `Color_Mapping.R` script.
3. Set the working directory to the location of your project data:
    ```R
    setwd("path/to/your/data")
    ```
4. Execute the script to perform the analysis.

## Data

The data used in this project includes multiseasonal raster images stored in CSV format. Ensure that your data directory
is structured as follows:

```
data/
└── training.csv
```

## Scripts

- `Color_Mapping.R`: Main script for loading libraries, setting up the environment, and executing the clustering and
  mapping.

## Results

Results are saved in the `Results` directory, including:

- K-means model (`model_kmeans.Rdata`)
- Geospatial TIFF map (`kemans_15.tif`)
