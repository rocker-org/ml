# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation in R.  

## Pre-Built Images

At this time there are two prebuilt images available, both using the `latest` tag.

- `rocker/cuda` - CUDA drivers for NVIDIA GPUs. Based on `quay.io/jupyter/pytorch-notebook:cuda12-ubuntu-24.04`.  A good general-purpose image supporting NVIDIA GPUs.
- `rocker/ml` - Identical image recipe but using `quay.io/jupyter/minimal-notebook:ubuntu-24.04`.  A smaller image when CUDA drivers are not required.

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

```
docker run -ti -p 8888:8888 rocker/ml
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

### CUDA versions

This approach inherits CUDA libraries from [upstream images of the Jupyter Docker stack](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/selecting.html#cuda-enabled-variants).  At this time, Jupyter builds `pytorch` images for the last two CUDA variants (12 & 11) and the `tensorflow` images only for the latest version of CUDA (12). CUDA is only supported for x86_64 architectures, though non-cuda versions support aarch64 (amd64).    

 CUDA Version | image
 -------------|----------------------------------------------------------------------------------------------------
 12 | [`quay.io/jupyter/pytorch-notebook:cuda12-ubuntu-24.04`](https://quay.io/repository/jupyter/pytorch-notebook) 
 12 | [`quay.io/jupyter/tensorflow-notebook:cuda12-ubuntu-24.04`](https://quay.io/repository/jupyter/pytorch-notebook) 
 11 | [`quay.io/jupyter/pytorch-notebook:cuda11-ubuntu-24.04`](https://quay.io/repository/jupyter/pytorch-notebook)


