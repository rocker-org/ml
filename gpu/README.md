gpu
=============

A Docker image based on [rocker/tidyverse](https://github.com/rocker-org/rocker-versioned) including GPU support via CUDA. Based on [work](zhttps://github.com/ecohealthalliance/reservoir/blob/master/Dockerfile.gpu) done by [Noam Ross](https://github.com/noamross) and extended by [Sam Abbott](https://github.com/seabbs). The Docker image contains `xgboost` built for GPU's in both R and Python as well as the latest stable release of `h2o`. If you wanted to use a different version of CUDA to the one currently installed then changethe relevant environment variables in the `Dockerfile` and rebuild the image.

Usage
-----

Use as [rocker/tidyverse](https://github.com/rocker-org/rocker-versioned) but replace all `docker` commands with [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker) commands (must have installed [`nvidia-docker`](https://github.com/NVIDIA/nvidia-docker) on the host system).

-   Pull/Build

``` bash
docker pull rocker/gpu
## Or build 
## Clone repo and navigate into the repo in the terminal
docker build . -t gpu
```

-   Run

``` bash
nvidia-docker run -d -p 8787:8787 -e USER=gpu -e PASSWORD=gpu --name gpu rocker/gpu
## Or build 
nvidia-docker run -d -p 8787:8787 -e USER=gpu -e PASSWORD=gpu --name gpu gpu
```

-   Login: Go to `localhost:8787` and sign in using the password and username given with the `docker run` command

Nvidia Test
-----------

Run `nvidia-smi` in a bash shell. If GPU support is working correctly it should return GPU usage and temperature information.

``` bash
nvidia-smi
```

Xgboost GPU Test
----------------

If the following runs without errors `xgboost` is installed and using the GPU.

``` r
library(xgboost)
# load data
data(agaricus.train, package = 'xgboost')
data(agaricus.test, package = 'xgboost')
train <- agaricus.train
test <- agaricus.test
# fit model
bst <- xgboost(data = train$data, label = train$label, max_depth = 5, eta = 0.001, nrounds = 100,
               nthread = 2, objective = "binary:logistic", tree_method = "gpu_hist")
# predict
pred <- predict(bst, test$data)
```

Xgboost via H2O Test
--------------------

`h2o` provides a nice interface to `xgboost`, along with some great tools for hyper-parameter tuning. (*Note: This is not an install of `h2o4gpu` so only `h2o.xgboost` supports GPU acceleration.*)

``` r
# Init h2o
library(h2o)
h2o.init()

# Load test data
australia_path <- system.file("extdata", "australia.csv", package = "h2o")
australia <- h2o.uploadFile(path = australia_path)
independent <- c("premax", "salmax","minairtemp", "maxairtemp", "maxsst",
                 "maxsoilmoist", "Max_czcs")
dependent <- "runoffnew"

# Run xgboost without GPU
h2o.xgboost(y = dependent, x = independent, training_frame = australia,
        ntrees = 1000, backend = "cpu")

# Run xgboost with GPU
h2o.xgboost(y = dependent, x = independent, training_frame = australia,
            ntrees = 1000, backend = "gpu")
```
