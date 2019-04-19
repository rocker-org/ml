FROM rocker/cuda:3.5.3

RUN echo "\nTENSORFLOW_PYTHON=/usr/bin/python3" >> \
  /usr/local/lib/R/etc/Renviron

## Python
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    python3-dev \
    python3-setuptools \
    python3-pip

## Install Keras
RUN pip3 install \
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow-gpu==1.12.0 \
    keras==2.2.4 \
    --no-cache-dir \
  && install2.r keras


