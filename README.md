# Rocker stack for Machine Learning in R 

This repository contains images for machine learning and GPU-based computation in R.  


## Deploying images

These images can be deployed in the usual manner directly with Docker:

```
docker run -ti -p 8888:8888 rocker/ml
```

### JupyterHub

These images are designed to support easy intergration with JupyterHub.  Jupy

### Binder

### Codespaces

These images are also compatible with Jupyterlab in GitHub Codespaces.  

## Customizing images

These images can be easily extended with additional packages from R and python.
An example is provided in the `extend` directory, showing 


## Technical details

These docker images build on the widely used Ubuntu Linux distribution (LTS release, 24.04 at the time of writing). 

While repositories such as Posit's package manager or R-Universe now provide pre-compiled binaries for Linux Ubuntu LTS releases, many of these packages still require that certain runtime libaries are available on the system.  Typically, R users have been expected to `apt-get` these "system-level" dependencies (e.g. `libgdal`), creating an additional technical hurdle that is often unfamiliar to users.

This stack leverages the design of the [BSPM](https://github.com/rocker-org/bspm) system to automatically manage installation of system dependencies during the Docker build process.
The example shown in `extend/` illustrates how we can simply list any required packages in `install.r` and enjoy system dependencies being resolved automatically.

However, Jupyterhub deploys typically prevent users from root (`sudo`) privileges required to install system libraries, so this mechanism is not available at runtime to end users. This stack will still allow non-sudo users to install pre-built binary packages from R-Universe, provided any required system libraries are already present on the image. 

On the python side, package dependencies are managed by conda, which bundles its own copies of any required system libraries. conda installations do not require root, meaning that users can easily install additional packages at build time or in an interactive session. 

Note that following standard JupyterHub designs, interactive installation of packages will not persist between sessions.  
