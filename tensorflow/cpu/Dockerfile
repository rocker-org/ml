FROM rocker/tidyverse:3.6.0

# Set up env variables in R
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH
RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf \
  && echo "TENSORFLOW_PYTHON=/usr/bin/python3" >> /usr/local/lib/R/etc/Renviron

### Set up a user modifyable python3 environment
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

RUN ENV PYTHON_VENV_PATH /opt/venv
RUN python3 -m venv ${PYTHON_VENV_PATH}

RUN chown -R rstudio:rstudio ${PYTHON_VENV_PATH}
ENV PATH ${PYTHON_VENV_PATH}/bin:${PATH}

## Install Keras
USER rstudio
RUN pip3 install \
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow==1.12.0 \
    keras==2.2.4 \
    --no-cache-dir
USER root
RUN install2.r keras

