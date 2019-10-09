## Developer notes


- CUDA 9.0 is built on ubuntu:16.04, with tensorflow 1.12.0
- CUDA 10.0 is built on ubuntu:18.04 with tensorflow 1.13.1


Note that one cannot easily mix and match versions of CUDA, tensorflow, and the R packages.   Pre-compiled tensorflow binaries work only with CUDA 9.0 and 10.0.  

For example, the current dev version of `greta` (0.3.0.9002) needs `tensorflow-gpu==1.13.1`, CUDA 10.0 (and probably python 3.6).  More recent or older versions will likely break things.  The current stable version, (0.3.0) cannot run in this environment, and needs CUDA 9.0 and tensorflow==`1.12.0`.  


## Managing the Python Virtualenv

Currently, we set global env var `PYTHON_RETICULATE_ENV`, which forces `reticulate` and friends to use the virtualenv we set up at that location (`opt/venv`).  This may make it dificult to provide alternative venvs (since running `Sys.unsetenv()` from the R console is not sufficient).  

Setting `WORKON_HOME` is more flexible, e.g.:

```
ENV WORKON_HOME /opt/virtualenvs
ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow
```

which allows `reticulate` to still find `python` in the venv out-of-the-box, but can create additional virtualenvs in `WORKON_HOME` (users should be given write permissions to this). 
