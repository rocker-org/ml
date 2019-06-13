#!/bin/sh

apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip


## symlink these because reticulate hardwires these PATHs...
ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip
ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv

chown -R rstudio:rstudio ${PYTHON_VENV_PATH}

## FIXME set versions Consider renv
#R -e "renv::restore()"
pip3 install --no-cache-dir tensorflow-gpu==1.11.0 keras h5py pyyaml requests Pillow 
R -e "install.packages(c('keras', 'greta'))"

