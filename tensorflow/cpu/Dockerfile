FROM rocker/tidyverse:3.6.0

ENV WORKON_HOME /opt/virtualenvs
ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow

## Set up a user modifyable python3 environment
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN python3 -m venv ${PYTHON_VENV_PATH}

RUN chown -R rstudio:rstudio ${WORKON_HOME}
ENV PATH ${PYTHON_VENV_PATH}/bin:${PATH}
## And set ENV for R! It doesn't read from the environment...
RUN echo "PATH=${PATH}" >> /usr/local/lib/R/etc/Renviron && \
    echo "WORKON_HOME=${WORKON_HOME}" >> /usr/local/lib/R/etc/Renviron && \
    echo "RETICULATE_PYTHON_ENV=${PYTHON_VENV_PATH}" >> /usr/local/lib/R/etc/Renviron

## Because reticulate hardwires these PATHs...
RUN ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip && \
    ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv

## install as user to avoid venv issues later
USER rstudio
RUN pip3 install \
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow==1.12.0 \
    tensorflow-probability==0.5.0 \
    keras==2.2.4 \
    --no-cache-dir
USER root
RUN install2.r reticulate tensorflow keras

## Not clear why tensorflow::install_tensorflow() fails (cant find /usr/local/bin/virtualenv). 
## keras::install_keras() cannot specify a custom envname

## Not clear how we control versions...
#RUN R -e "reticulate::py_install(c( \
#  'tensorflow', \ 
#  'tensorflow-probability', \
#  'keras'))"

###RUN R -e "tensorflow::install_tensorflow(version='cpu', extra_packages = c('keras'), envname='r-tensorflow')"
