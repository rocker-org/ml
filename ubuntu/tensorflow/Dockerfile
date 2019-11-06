FROM tensorflow/tensorflow:2.0.0-gpu-py3 

LABEL org.label-schema.license="GPL-2.0" \
      org.label-schema.vcs-url="https://github.com/rocker-org/rocker-versioned" \
      org.label-schema.vendor="Rocker Project" \
      maintainer="Carl Boettiger <cboettig@ropensci.org>"

ENV TERM=xterm
ENV CRAN=https://cran.rstudio.com

## cuda:9.0 is xenial, cuda:10.0 is bionic
ARG UBUNTU_VERSION=bionic
ARG R_HOME=/usr/lib/R
ARG DEBIAN_FRONTEND=noninteractive


ENV R_VERSION=${R_VERSION:-3.6.1}
ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
COPY shared/install_R.sh /tmp/install_R.sh
RUN  . /tmp/install_R.sh


COPY shared/install_rstudio.sh /tmp/install_rstudio.sh
RUN . /tmp/install_rstudio.sh
COPY shared/userconf.sh /etc/cont-init.d/userconf
EXPOSE 8787
CMD ["/init"]


COPY shared/install_tidyverse.sh /tmp/install_tidyverse.sh
RUN . /tmp/install_tidyverse.sh


COPY shared/install_verse.sh /tmp/install_verse.sh
RUN . /tmp/install_verse.sh


## Use Configure CUDA for R, use NVidia libs for BLAS
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$PATH:$CUDA_HOME/bin
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64/libnvblas.so:$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64
ENV NVBLAS_CONFIG_FILE=/etc/nvblas.conf
COPY shared/config_R_cuda.sh /tmp/config_R_cuda.sh
RUN . /tmp/config_R_cuda.sh

RUN install2.r --repo https://cran.rstudio.com --error keras greta

#COPY shared/install_geospatial.sh /tmp/install_geospatial.sh
#RUN . /tmp/install_geospatial.sh




