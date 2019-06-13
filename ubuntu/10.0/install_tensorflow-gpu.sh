#!/bin/sh
set -e

apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

## FIXME set versions Consider renv
#R -e "renv::restore()"
pip3 install --no-cache-dir tensorflow-gpu tensorflow-probability keras h5py pyyaml requests Pillow 
chown -R rstudio:rstudio ${PYTHON_VENV_PATH}

R -e "install.packages('keras')"
R -e "install.packages('remotes'); remotes::install_github('greta-dev/greta')"

