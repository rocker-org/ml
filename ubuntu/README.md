

CUDA 9.0 is built on ubuntu:16.04
CUDA 10.0 is built on ubuntu:18.04



## Developer notes


Currently, we set global env var `PYTHON_RETICULATE_ENV`, which forces `reticulate` and friends to use the virtualenv we set up at that location (`opt/venv`).  This may make it dificult to provide alternative venvs (since running `Sys.unsetenv()` from the R console is not sufficient).  

Setting `WORKON_HOME` is more flexible, e.g.:

```
ENV WORKON_HOME /opt/virtualenvs
ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow
```

which allows `reticulate` to still find `python` in the venv out-of-the-box, but can create additional virtualenvs in `WORKON_HOME` (users should be given write permissions to this). 
