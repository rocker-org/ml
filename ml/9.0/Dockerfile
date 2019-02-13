FROM rocker/gpu:cuda9.0-R3.5.1

## Python
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    python3-dev \
    python3-setuptools \
    python3-pip

## Install Keras
RUN pip3 install h5py pyyaml requests Pillow tensorflow-gpu keras --no-cache-dir \
  && install2.r keras

# Set up env variables in R
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH

RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf \
  && echo "\n\
         \nTENSORFLOW_PYTHON=/usr/bin/python3 \
         \nCUDA_HOME=$CUDA_HOME \
         \nCUDA_PATH=$CUDA_PATH \
         \nPATH=$PATH" >> /usr/local/lib/R/etc/Renviron

# Python Xgboost for CPU
RUN pip3 install wheel setuptools scipy --upgrade
RUN pip3 install xgboost

### R needs Xgboost compiled from source to support GPU (not a reticulate-bindings)
### Technically could be done with a multi-stage build so we could
### drop the heavy cuda-devel dependencies currently built into rocker/cuda:9.0
RUN apt-get update && apt-get -y install cmake \
  && git clone --recursive https://github.com/dmlc/xgboost \
  && mkdir -p xgboost/build && cd xgboost/build \
  && cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
  && make install -j$(nproc)

## Get Java (for h2o R package)
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    cmake \
    default-jdk \
    default-jre \
  && R CMD javareconf

## h2o requires Java
RUN install2.r h2o

RUN install2.r greta


