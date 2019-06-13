# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation
in R.  




The dependency stack looks like so: 

```
-| rocker/tidyverse
  -| rocker/tensorflow
    -| rocker/ml
  -| rocker/cuda 
    -| rocker/tensorflow-gpu
      -| rocker/ml-gpu
    -| rocker/cuda-dev
```


Nvidia CUDA libraries to the `rocker-versioned`
stack (building on `rocker/tidyverse`). 

## Quick start

Begin with the `ml` or `ml-gpu` version for a batteries-included setup


**Note: `gpu` images require nvidia-docker** runtime to run!  

Run a bash shell or R command line:

```
docker run --rm -ti rocker/ml R
nvidia-docker run --rm -ti rocker/ml-gpu R
```

Or run in RStudio instance:

```
docker run -e PASSWORD=mu -p 8787:8787 rocker/ml
nvidia-docker run -e PASSWORD=mu -p 8787:8787 rocker/ml-gpu
```


## Versioning

GPU-based images are built with CUDA 9.0 (on `latest` / `3.5.2` tags, where
tags track the current R release, as in the rest of the
[rocker-versioned](https://github.com/rocker-org/rocker-versioned) stack).



