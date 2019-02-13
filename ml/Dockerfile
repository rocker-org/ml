FROM rocker/cuda:9.0

## Python 
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    python3-dev \
    python3-setuptools \
    python3-pip

## Install Keras
RUN pip3 install h5py pyyaml requests Pillow tensorflow-gpu keras --no-cache-dir \
  && install2.r keras

ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH

# Set up env variables in R
RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf \
  && echo "Sys.setenv(TENSORFLOW_PYTHON='/usr/bin/python3'); Sys.setenv(CUDA_HOME=\"$CUDA_HOME\"); Sys.setenv(CUDA_PATH=\"$CUDA_PATH\"); Sys.setenv(PATH=\"$PATH\")" | tee -a /usr/local/lib/R/etc/Rprofile.site



## CUDA Version
ENV CUDA_MAJOR_VERSION=9.0
ENV CUDA_MAJOR_VERSION_HYP=9.0
ENV CUDA_MINOR_VERSION=9.0.176

RUN ls /usr/local/cuda-${CUDA_MAJOR_VERSION}/targets/x86_64-linux/lib/* | xargs -I{} ln -s {} /usr/lib/x86_64-linux-gnu/ \
  && ln -s libcuda.so /usr/lib/x86_64-linux-gnu/libcuda.so.1 \
  && ln -s libnvidia-ml.so /usr/lib/x86_64-linux-gnu/libnvidia-ml.so.1

ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility 


## Get Java
#RUN apt-get update -qq \
#  && apt-get -y --no-install-recommends install \
#    cmake \
#    default-jdk \
#    default-jre \
#    python3-pip \
#  && R CMD javareconf

# Python Xgboost for GPU
#RUN pip3 install wheel setuptools scipy --upgrade
#RUN pip3 install xgboost

### R Xgboost
#RUN git clone --recursive https://github.com/dmlc/xgboost \
#  && mkdir -p xgboost/build && cd xgboost/build \
#  && cmake .. -DUSE_CUDA=ON -DR_LIB=ON \
#  && make install -j$(nproc) 

## Get latest release of h2o
#RUN Rscript -e 'install.packages("h2o", type="source", repos="http://h2o-release.s3.amazonaws.com/h2o/latest_stable_R")'

