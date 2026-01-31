# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation in R.  

## Pre-Built Images

### Base Images

- **`rocker/cuda`** - GPU image with CUDA 13 and RAPIDS AI. Based on `nvidia/cuda:13.0.0-runtime-ubuntu24.04` with pip-based Python environment. Includes RAPIDS cuDF and PyTorch with CUDA 13 support.
  - Tags: `latest`, `cuda13.0-py3.12-rapids25.12`, `cuda13.0-py3.12`, `cuda13.0`
  
- **`rocker/ml`** - CPU-only image using `ubuntu:24.04` base. Same Python stack but CPU versions only (no CUDA/RAPIDS).
  - Tags: `latest`, `py3.12`

### Extended Images with Geospatial Packages

- **`rocker/cuda-spatial`** - Extends `rocker/cuda` with geospatial packages (GDAL, GeoPandas, Rasterio, Xarray, etc.)
  - Tags: `latest`
  
- **`rocker/ml-spatial`** - Extends `rocker/ml` with geospatial packages (GDAL, GeoPandas, Rasterio, Xarray, etc.)
  - Tags: `latest`

To access a stable build, users may refer to specific SHA hash tags on the [GitHub Container Registry](https://github.com/orgs/rocker-org/packages). Note that SHA-tagged images are 'frozen' and will not have the most recent versions of software, possibly including critical security patches.

## Features

- **IDEs:** Jupyter Lab, RStudio Server, VSCode (code-server) with common extensions
- **ML Plugins:** Tensorboard support
- **Python:** 3.12 with pip-based environment at `/opt/venv` (user-writable)
- **CUDA Support:** CUDA 13 runtime libraries (GPU image only)
- **RAPIDS AI:** cuDF 25.12 with built-in Polars interoperability (GPU image only)
- **PyTorch:** CUDA 13 wheels (GPU) or CPU wheels (CPU image)
- **R Packages:** Binary-friendly installs via BSPM/R-universe
- **Data Tools:** JupyterLab extensions, DuckDB, Polars, Ibis

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

Several other popular configurations exist for R and Python environments. Rather than provide a comprehensive stack, this project seeks to provide a robust base that sidesteps some of the issues and complexities of alternatives.

### Python Environment

This stack uses **pip-based Python** with a system-wide virtual environment at `/opt/venv` (included in `PATH`). The virtual environment is user-writable via group permissions, allowing users to install additional packages without sudo.

For CUDA support, we use pip wheels from:
- RAPIDS packages from `pypi.nvidia.com` (e.g., `cudf-cu13==25.12.*`)
- PyTorch from `download.pytorch.org/whl/cu130`

The GPU image is based on `nvidia/cuda:13.0.0-runtime-ubuntu24.04`, which provides CUDA runtime libraries and NVRTC (required for Numba JIT compilation in RAPIDS). The CPU image uses plain `ubuntu:24.04`.

**Why pip instead of conda?** While conda is excellent for many use cases, pip wheels provide:
- More straightforward CUDA 13 support for RAPIDS 25.12
- Simpler dependency management for our specific package set
- Smaller images for CPU-only deployments

### JupyterHub Compatibility

This stack is designed with maximum compatibility with [JupyterHub](https://jupyter.org/hub) deployments. Key design decisions:

- **User-writable environments:** Python packages can be installed by non-sudo users in `/opt/venv`
- **No home directory pollution:** Software is installed outside `$HOME` since JupyterHub typically bind-mounts user home directories
- **Standard conventions:** Uses `$NB_USER` (default: `jovyan`) and UID 1000 matching JupyterHub standards

Additional utilities and VSCode extensions are installed in `/opt/share` (via `XDG_DATA_HOME`). This allows pre-installation and avoids unnecessary bloat of users' home directories, which is important when many users access the same JupyterHub.  


### Installing package binaries

**R packages:** Repositories such as Posit's Package Manager and R-Universe now provide pre-compiled binaries for Linux Ubuntu LTS releases. However, many packages still require runtime libraries (e.g., `libgdal`). This stack leverages [BSPM](https://github.com/rocker-org/bspm) to automatically manage installation of system dependencies during the Docker build process. The example in `extend/install.r` illustrates how you can simply list required R packages and have system dependencies resolved automatically.

Note: JupyterHub deployments typically prevent users from root (`sudo`) privileges, so this mechanism is not available at runtime to end users. However, users can still install pre-built binary packages from R-Universe if required system libraries are already present on the image.

**Python packages:** With our pip-based approach, users can install additional packages at build time or in an interactive session using `pip install`. The `/opt/venv` is user-writable (via group permissions), so no sudo is required. 

### CUDA and RAPIDS Support

**CUDA 13.0:** The GPU image (`rocker/cuda`) uses NVIDIA's `cuda:13.0.0-runtime-ubuntu24.04` base image, which provides:
- CUDA 13.0 runtime libraries
- NVRTC (NVIDIA Runtime Compilation) for Numba JIT compilation
- Required NVIDIA driver: 580.65.06 or newer

**RAPIDS 25.12:** We install RAPIDS packages using pip wheels with the `-cu13` suffix:
- `cudf-cu13==25.12.*` - GPU DataFrame library with built-in Polars interoperability
- Includes necessary CUDA libraries bundled with the pip packages

**PyTorch:** Installed from PyTorch's CUDA 13.0 wheel index for GPU image, CPU wheels for ML image.

For more details on CUDA compatibility, see [NVIDIA's CUDA compatibility documentation](https://docs.nvidia.com/deploy/cuda-compatibility/).


