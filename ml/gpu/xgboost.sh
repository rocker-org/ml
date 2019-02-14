#!/bin/sh

LIBRARY_PATH=/usr/local/cuda/lib64/stubs
CUDNN_VERSION=7.4.2.24

apt-get update && apt-get install -y --no-install-recommends \
    cuda-libraries-dev-$CUDA_PKG_VERSION \
    cuda-nvml-dev-$CUDA_PKG_VERSION \
    cuda-minimal-build-$CUDA_PKG_VERSION \
    cuda-command-line-tools-$CUDA_PKG_VERSION \
    cuda-core-9-0=9.0.176.3-1 \
    cuda-cublas-dev-9-0=9.0.176.4-1 \
    libnccl-dev=$NCCL_VERSION-1+cuda9.0 && \
  apt-get install -y --no-install-recommends \
    libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
    libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 \
    wget cmake && \
  apt-mark hold libcudnn7 && \
  git clone --recursive https://github.com/dmlc/xgboost && \
  mkdir -p xgboost/build && cd xgboost/build && \
  cmake .. -DUSE_CUDA=ON -DR_LIB=ON && \
  make install -j$(nproc) && \
  install2.r xgboost && \
  cd / && rm -rf xgboost && \
  apt-get remove --purge \
   cuda-libraries-dev-$CUDA_PKG_VERSION \
    cuda-nvml-dev-$CUDA_PKG_VERSION \
    cuda-minimal-build-$CUDA_PKG_VERSION \
    cuda-command-line-tools-$CUDA_PKG_VERSION \
    cuda-core-9-0=9.0.176.3-1 \
    cuda-cublas-dev-9-0=9.0.176.4-1 \
    libnccl-dev=$NCCL_VERSION-1+cuda9.0 \
    libcudnn7=$CUDNN_VERSION-1+cuda9.0 \
    libcudnn7-dev=$CUDNN_VERSION-1+cuda9.0 \
    wget cmake && \
  rm -rf /var/lib/apt/lists/* && \

 ## Not sure why explicit version doesn't work
# apt-get update && apt-get -y install cmake wget \
#   && wget https://github.com/dmlc/xgboost/archive/v0.81.tar.gz \
#   && tar -xvf v0.81.tar.gz \
#   && mkdir -p xgboost-0.81/build && cd xgboost-0.81/build \
#   && cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
#  && make install -j$(nproc)


