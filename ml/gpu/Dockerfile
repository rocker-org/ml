FROM rocker/tensorflow-gpu:3.5.2

# Python Xgboost for CPU
RUN pip3 install \
    wheel==0.33.0 \
    setuptools==40.8.0 \
    scipy==1.2.1 --upgrade

## xgboost with multi-GPU support
RUN apt-get update && apt-get -y install wget \
  && wget https://s3-us-west-2.amazonaws.com/xgboost-wheels/xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl \
  && pip3 install  xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl \
  && rm xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl

## Could do a multi-stage build if we figure out what to copy
RUN LIBRARY_PATH=/usr/local/cuda/lib64/stubs && \
    CUDNN_VERSION=7.4.2.24 && \
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
  apt-get remove --purge -y \
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
  rm -rf /var/lib/apt/lists/*

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

