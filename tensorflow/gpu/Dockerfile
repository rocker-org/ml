FROM rocker/cuda:3.6.0

ENV CUDA=9.0
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        cuda-command-line-tools-9.0 \
        cuda-cublas-9.0 \
        cuda-cufft-9.0 \
        cuda-curand-9.0 \
        cuda-cusolver-9.0 \
        cuda-cusparse-9.0 \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

## install as user to avoid venv issues later
USER rstudio
RUN pip3 install \
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow-gpu==1.12.0 \
    tensorflow-probability==0.5.0 \
    keras==2.2.4 \
    --no-cache-dir
USER root
RUN install2.r reticulate tensorflow keras


