# Developer notes


- `rocker/ml:cuda-9.0` (in 9.0 directory) is built on ubuntu:16.04, with tensorflow 1.12.0
- `rocker/ml:cuda-10.0` (in 10.0 directory) is built on ubuntu:18.04 with latest available tensorflow

## R and package versions

- These images are built only with the latest version of R.  Older and devel versions are not avaialable at this time.  

- Unlike the [rocker-versioned](https://github.com/rocker-org/rocker-versioned) stack, these images install R from Ubuntu binaries.  This means that R libraries are in `/usr/lib` and not `/usr/local/lib` (and so forth), and that packages can be installed from `apt-get`.  Note that adding PPAs to apt-get additional packages may not guarentee the reproducibility of what versions of packages are installed, and binary versions available in `apt-get` may be significantly behind those on CRAN.

- Also unlike the [rocker-versioned](https://github.com/rocker-org/rocker-versioned) stack, these do not set an MRAN snapshot repo, but use the default `cran.rstudio.com` mirror to install the latest packages.

- Future versions of these images may use the `renv` package to manage reproducible package installation & version tracking in place of the MRAN snapshot design.

## Templating

- These repositories use an experimental templating system, where installion of modular components (`R`, `rstudio`, `tidyverse`, `verse`, `python`, etc).   Currently these can be turned on and off in the Dockerfiles with commenting.  (Future work may also support proper templating with build args).  *NB:* currently, separate templates are maintained for the 9.0 and 10.0 stack, which operate on different base images (ubuntu-16.04 vs ubuntu 18.04, respectively), and thus may differ slightly in available package names, etc.  

## GPU support

Thise images are based on the official NVidia cuda images and should support GPU systems.  For this to work, these images must be run with [nvidia docker](https://github.com/NVIDIA/nvidia-docker)!

*Note that one cannot easily mix and match versions of CUDA, tensorflow, and the R packages.   Pre-compiled tensorflow binaries work only with CUDA 9.0 and 10.0.*

For example, the current dev version of `greta` (0.3.0.9002) needs `tensorflow-gpu==1.13.1`, CUDA 10.0 (and probably python 3.6).  More recent or older versions will likely break things.  The current stable version, (0.3.0) cannot run in this environment, and needs CUDA 9.0 and tensorflow==`1.12.0`.  


## Managing the Python Virtualenv

Currently, we set global env var `PYTHON_RETICULATE_ENV`, which forces `reticulate` and friends to use the virtualenv we set up at that location (`opt/venv`).  This may make it dificult to provide alternative venvs (since running `Sys.unsetenv()` from the R console is not sufficient).  

Setting `WORKON_HOME` is more flexible, e.g.:

```
ENV WORKON_HOME /opt/virtualenvs
ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow
```

which allows `reticulate` to still find `python` in the venv out-of-the-box, but can create additional virtualenvs in `WORKON_HOME` (users should be given write permissions to this). 
