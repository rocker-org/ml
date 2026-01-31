
This folder illustrates how a user would typically extend this image with additional dependencies. 

The user edits the `install.r` script in this folder to add desired R
packages, and the `requirements.txt` adds the desired Python packages.
Building the `Dockerfile` in this repo then adds these both to the image,
automatically resolving any system dependencies as needed.

For instance, in this example we add an extensive collection of commonly
used geospatial packages in R and Python.

By using `rocker/cuda` as the base image, we ensure our base image has support for NVIDIA GPUs. For non-GPU use, use `rocker/ml:cpu` as the base image instead to generate a smaller image.
 
