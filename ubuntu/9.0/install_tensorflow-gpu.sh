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
pip3 install --no-cache-dir tensorflow-gpu==1.11.0 tensorflow-probability==0.5.0
chown -R rstudio:rstudio ${PYTHON_VENV_PATH}

## greta==0.3.0
R -e "install.packages(c('keras', 'greta'))"

