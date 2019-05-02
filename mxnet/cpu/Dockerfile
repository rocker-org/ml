FROM rocker/tidyverse:3.6.0

RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade \
    build-essential \
    libopenblas-dev \
    liblapack-dev \
    libopencv-dev \
    libxt-dev

RUN git clone --recursive --branch 1.3.1 https://github.com/apache/incubator-mxnet.git \
  &&  cd incubator-mxnet \
  &&  make -j $(nproc) USE_OPENCV=1 USE_BLAS=openblas

RUN cd incubator-mxnet \
  && make rpkg

FROM rocker/tidyverse:3.6.0

RUN apt-get update && apt-get install -y --no-install-recommends --no-upgrade \
    libopenblas-dev \
    liblapack-dev \
    libopencv-dev \
    libxt-dev

COPY --from=0 /usr/local/lib/R/site-library /usr/local/lib/R/site-library

RUN install2.r \
  xgboost
