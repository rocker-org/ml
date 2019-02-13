# rocker/cuda images



`rocker/cuda-9.0`
`rocker/cuda-10.0`


These Dockerfiles add the Nvidia CUDA libraries to the `rocker-versioned`
stack (building on `rocker/tidyverse`). 

## Getting started

**CUDA images require nvidia-docker** runtime to run!  

Run a bash shell or R command line:

```
nvidia-docker run --rm -ti rocker/cuda-9.0 bash
nvidia-docker run --rm -ti rocker/cuda-9.0 R
```

Or run in RStudio instance:

```
nvidia-docker run -e PASSWORD=gpu -p 8787:8787 rocker/cuda-9.0
```



## Context

These images are inspire by and comparable to
`nvidia/cuda:9.0-cuddn7-devel` and  `nvidia/cuda:10.0-cuddn7-devel`.
The official NVIDIA cuda Dockerfiles break this into a stack of images:
`base`, `runtime`, `devel`, and `cuddn7-devel`, building on `ubuntu16.04` and
`ubuntu18.04`.  Including the devel libraries is only necessary for packages
that must be compiled from source (such as xgboost with GPU support), and does
make these images much larger than they would be otherwise.  The devel
libraries are not needed for tensflow/keras GPU use in R, and may be separated
out later on.




