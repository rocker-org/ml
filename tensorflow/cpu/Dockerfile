FROM rocker/tidyverse:3.6.0

ENV PYTHON_VENV_PATH /opt/venv

## Set up a user modifyable python3 environment
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv ${PYTHON_VENV_PATH}
#RUN python -m virtualenv ${PYTHON_VENV_PATH}

RUN chown -R rstudio:rstudio ${PYTHON_VENV_PATH}
ENV PATH ${PYTHON_VENV_PATH}/bin:${PATH}
## And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron && \
  echo "RETICULATE_PYTHON= ${PYTHON_VENV_PATH}/bin/python" >> /usr/local/lib/R/etc/Renviron && \
  echo "RETICULATE_PYTHON_ENV= ${PYTHON_VENV_PATH}" >> /usr/local/lib/R/etc/Renviron

## Install Keras
USER rstudio
RUN pip install \
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow==1.12.0 \
    keras==2.2.4 \
    --no-cache-dir
USER root
RUN install2.r keras tensorflow reticulate

## Because reticulate hardwires these PATHs...
RUN ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip && \
    ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv


