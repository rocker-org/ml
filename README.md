# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation in R.  **EDIT** Dockerfiles are now built in modular build system at https://github.com/rocker-org/rocker-versioned2 .  This repo remains for documentation around the ML part of the stack.  




The dependency stack looks like so: 

```
-| rocker/r-ver:cuda10.1
  -| rocker/ml
    -| rocker/ml-verse
```

All three are CUDA compatible and will optionally take CUDA specific version tags as well as R version tags.


## Quick start

**Note: `gpu` use requires [nvidia-docker](https://github.com/NVIDIA/nvidia-docker/)** runtime to run!  

Run a bash shell or R command line:

```
# CPU-only
docker run --rm -ti rocker/ml R
# Machines with nvidia-docker and GPU support
docker run --gpus all --rm -ti rocker/ml R
```

Or run in RStudio instance:

```
docker run --gpus all -e PASSWORD=mu -p 8787:8787 rocker/ml
```


## Versioning

See [current `ml` tags](https://hub.docker.com/r/rocker/ml/tags?page=1&ordering=last_updated)
See [current `ml-verse` tags](https://hub.docker.com/r/rocker/ml-verse/tags?page=1&ordering=last_updated)



All images are based on the current Ubuntu LTS (ubuntu 20.04) and based on the official [NVIDIA CUDA docker build recipes](https://gitlab.com/nvidia/container-images/cuda/)

**PLEASE NOTE**: older images, `rocker/ml-gpu`, `rocker/tensorflow` and `rocker/tensorflow-gpu`, built with cuda 9.0, are deprecated and no longer supported.  


