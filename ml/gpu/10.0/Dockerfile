FROM rocker/gpu:cuda9.0-R3.5.2

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

## Python
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    python3-dev \
    python3-setuptools \
    python3-pip

## Install Keras
RUN pip3 install \
    h5py \
    pyyaml \
    requests \
    Pillow \
    tf-nightly-gpu \
    keras \
    --no-cache-dir \
  && install2.r keras

# Python Xgboost for CPU
RUN pip3 install \
    wheel==0.33.0 \
    setuptools==40.8.0 \
    scipy==1.2.1 --upgrade
RUN pip3 install xgboost==0.81

### R needs Xgboost compiled from source to support GPU (not a reticulate-bindings)
### Technically could be done with a multi-stage build so we could
### drop the heavy cuda-devel dependencies currently built into rocker/cuda:9.0
RUN apt-get update && apt-get -y install cmake wget \
  && wget https://github.com/dmlc/xgboost/archive/v0.81.tar.gz \
  && tar -xvf v0.81.tar.gz \
  && mkdir -p xgboost-0.81/build && cd xgboost-0.81/build \
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

