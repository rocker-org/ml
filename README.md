# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation in R.  

## Pre-Built Images

Four image variants are available, split between GPU and CPU architectures:

### GPU Images (CUDA-enabled)

- `rocker/cuda` - Full ML/data science environment with NVIDIA GPU support. Based on `rapidsai/ci-conda:latest` (Ubuntu 24.04 with CUDA libraries).
- `rocker/cuda-spatial` - GPU image with additional geospatial packages (GDAL, sf, terra, stars).

### CPU Images (smaller, no GPU)

- `rocker/ml` - CPU-only ML/data science environment. Based on `condaforge/miniforge3:latest` (Ubuntu 24.04). **32.7% smaller** than GPU variant.
- `rocker/ml-spatial` - CPU image with geospatial packages. **40.8% smaller** than GPU spatial variant.

To access a stable build, users may refer to specific `sha` hash of either image on the Rocker [GitHub Container Registry](https://github.com/orgs/rocker-org/packages).  Note that hashes are 'frozen' images, and will not have most recent versions of software, possibly including critical security patches.

## Features

- Jupyter Lab IDE
- RStudio Server IDE
- VSCode (code-server) IDE and common extensions
- Tensorboard plugin
- Conda-friendly python installs
- Binary-friendly R package installs (BSPM/R-universe)

See technical details below.

## Deploying images

### JupyterHub

These images are designed to support easy intergration with [JupyterHub]((https://jupyter.org/hub) and related platforms.  (See technical details below).  

### Binder

The Jupyter ecosystem also supports a range of images (and [BinderHub](https://binderhub.readthedocs.io/) / [repo2docker](https://repo2docker.readthedocs.io/) / [fancy-profiles](https://binderhub-service.readthedocs.io/en/latest/tutorials/connect-with-jupyterhub-fancy-profiles.html)) as a leading design principle.  

### Codespaces

These images are also compatible with Jupyterlab in GitHub Codespaces.  

### Docker

These images can be deployed in the usual manner directly with Docker:

```bash
# CPU base image
docker run -ti -p 8888:8888 rocker/ml

# GPU base image (requires NVIDIA GPU and drivers)
docker run --gpus all -p 8888:8888 rocker/cuda

# CPU with geospatial packages
docker run -ti -p 8888:8888 rocker/ml-spatial

# GPU with geospatial packages
docker run --gpus all -p 8888:8888 rocker/cuda-spatial
```

## Customizing images

These images can be easily extended with additional packages from R and python.
An example is provided in the `extend` directory, showing a simple example of a spatial extension.  


## Technical details

Several other popular configurations can be found with R and Python. Rather than provide a comprehensive stack, this project seeks to provide a robust base with sidesteps some of the issues and complexities of alternatives.

### JupyterHub Compatibility

This stack is designed with maximum compatibility with [JupyterHub](https://jupyter.org/hub) deployments. These docker images are simple and transparent extensions on top of [the official JupyterHub Docker Stacks](https://jupyter-docker-stacks.readthedocs.io/).  One notable aspect of JupyterHub compatibility is that most JupyterHub deployments assume the default user ($NB_USER)'s home directory will be bind-mounted.  This provides persistent user storage between restarts of a user's server (typically a kubernetes pod), but means that any software installed into the home directory on the image will be overwritten.  Therefore, this stack takes care to configure standard installation below the user's home directory.  As typical of rocker, R packages are installed in $R_HOME (`/usr/lib/R`), while conda install is inherited from JupyterHub (in `/opt/conda`).  Additional utilities and code-server extensions are put in `/opt/share` (specifically, `XDG_DATA_HOME` is set to `/opt/share`).  This allows pre-installation and avoids unnecessary bloat of users home directory, which can be important when many users access the same JupyterHub.  All JupyterHub images all use `conda` for python package installation, and conflicts in some extensions can arise in pip-installed versions (espicially in things such as jupyter-widgets).  


### Installing package binaries

While repositories such as Posit's package manager or R-Universe now provide pre-compiled binaries for Linux Ubuntu LTS releases, many of these packages still require that certain runtime libaries are available on the system.  Typically, R users have been expected to `apt-get` these "system-level" dependencies (e.g. `libgdal`), creating an additional technical hurdle that is often unfamiliar to users.  This stack leverages the design of the [BSPM](https://github.com/rocker-org/bspm) system to automatically manage installation of system dependencies during the Docker build process. The example shown in `extend/` illustrates how we can simply list any required packages in `install.r` and enjoy system dependencies being resolved automatically.However, Jupyterhub deploys typically prevent users from root (`sudo`) privileges required to install system libraries, so this mechanism is not available at runtime to end users. This stack will still allow non-sudo users to install pre-built binary packages from R-Universe, provided any required system libraries are already present on the image. 

On the python side, package dependencies are managed by conda, which bundles its own copies of any required system libraries. conda installations do not require root, meaning that users can easily install additional packages at build time or in an interactive session. 

### Base Images and CUDA

**GPU Images** are based on [`rapidsai/ci-conda:latest`](https://hub.docker.com/r/rapidsai/ci-conda), which provides Ubuntu 24.04 with CUDA 12 libraries and conda/mamba package management. This image is maintained by the RAPIDS AI team and includes optimized CUDA-enabled packages like cuDF and cuML.

**CPU Images** are based on [`condaforge/miniforge3:latest`](https://hub.docker.com/r/condaforge/miniforge3), providing Ubuntu 24.04 with conda/mamba but without CUDA libraries. This results in significantly smaller images (8.68 GB vs 12.9 GB for base, 9.06 GB vs 15.3 GB for spatial).

CUDA is only supported for x86_64 architectures. CPU images support both amd64 and arm64.


