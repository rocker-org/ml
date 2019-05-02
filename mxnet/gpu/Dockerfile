FROM rocker/cuda-dev:3.6.0

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget cmake && \
    git clone --recursive --branch v0.81 https://github.com/dmlc/xgboost && \
    mkdir -p xgboost/build && cd xgboost/build && \
    cmake .. -DUSE_CUDA=ON -DR_LIB=ON -DUSE_NCCL=ON && \
    make install -j$(nproc)

RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade \
    libopenblas-dev \
    liblapack-dev \
    libopencv-dev \
    libxt-dev

RUN git clone --recursive --branch 1.3.1 https://github.com/apache/incubator-mxnet.git \
  &&  cd incubator-mxnet \
  &&  echo "USE_OPENCV = 1" >> ./config.mk \
  &&  echo "USE_BLAS = openblas" >> ./config.mk \
  &&  echo "USE_CUDA = 1" >> ./config.mk \
  &&  echo "USE_CUDA_PATH = $CUDA_HOME" >> ./config.mk \
  &&  echo "USE_CUDNN = 1" >> ./config.mk \
  &&  make -j $(nproc)

RUN cd incubator-mxnet \
  && make rpkg

FROM rocker/cuda:3.6.0

RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade \
    libopenblas-dev \
    liblapack-dev \
    libopencv-dev \
    libxt-dev

COPY --from=0 /usr/local/lib/R/site-library /usr/local/lib/R/site-library

