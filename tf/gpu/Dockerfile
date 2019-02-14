FROM rocker/cuda:3.5.2

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
    h5py==2.9.0 \
    pyyaml==3.13 \
    requests==2.21.0 \
    Pillow==5.4.1 \
    tensorflow-gpu==1.12.0 \
    keras==2.2.4 \
    --no-cache-dir \
  && install2.r keras


