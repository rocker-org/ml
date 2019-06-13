FROM nvidia/cuda:10.0-cudnn7-devel

## cuda:9.0 is xenial, cuda:10.0 is bionic
ARG UBUNTU_VERSION=bionic
ARG R_HOME=/usr/lib/R
ARG DEBIAN_FRONTEND=noninteractive



ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
COPY install_R.sh /tmp/install_R.sh
RUN  . /tmp/install_R.sh



COPY install_rstudio.sh /tmp/install_rstudio.sh
RUN . /tmp/install_rstudio.sh
COPY userconf.sh /etc/cont-init.d/userconf
EXPOSE 8787
CMD ["/init"]



COPY install_tidyverse.sh /tmp/install_tidyverse.sh
RUN . /tmp/install_tidyverse.sh



COPY install_verse.sh /tmp/install_verse.sh
RUN . /tmp/install_verse.sh




## FROM https://tensorflow.rstudio.com/tools/local_gpu.html#environment-variables
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=$PATH:$CUDA_HOME/bin
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64
RUN echo "\n\
          \nCUDA_HOME=$CUDA_HOME\
          \nPATH=$PATH" >> ${R_HOME}/etc/Renviron && \
    echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf




ENV PYTHON_VENV_PATH=/opt/venv 
ENV RETICULATE_PYTHON_ENV=$PYTHON_VENV_PATH
ENV PATH=${PYTHON_VENV_PATH}/bin:${PATH}
COPY install_python.sh /tmp/install_python.sh
RUN . /tmp/install_python.sh



COPY install_tensorflow-gpu.sh /tmp/install_tensorflow-gpu.sh
RUN . /tmp/install_tensorflow-gpu.sh

