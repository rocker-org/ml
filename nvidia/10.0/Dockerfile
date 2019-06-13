FROM nvidia/cuda:10.0-cudnn7-devel

ARG DEBIAN_FRONTEND=noninteractive


ENV R_HOME=/usr/lib/R
COPY R.sh /tmp/install_R.sh
RUN  . /tmp/install_R.sh



COPY rstudio.sh /tmp/install_rstudio.sh
RUN . /tmp/install_rstudio.sh
COPY userconf.sh /etc/cont-init.d/userconf
EXPOSE 8787
CMD ["/init"]



ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH
RUN echo "\n\
          \nCUDA_HOME=$CUDA_HOME \
          \nCUDA_PATH=$CUDA_PATH \
          \nPATH=$PATH" >> ${R_HOME}/etc/Renviron
RUN if [ -f /etc/rstudio ]; then \
    echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf; fi


## Note: forcing PYTHON_RETICULATE_ENV may preclude defining alternative venvs
## Setting WORKON_HOME is more flexible, but may result in reticulate and tensorflow installing to diff locations
## ENV WORKON_HOME /opt/virtualenvs
## ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow

ENV PYTHON_VENV_PATH=/opt/venv 
ENV RETICULATE_PYTHON_ENV=$PYTHON_VENV_PATH
ENV PATH=${PYTHON_VENV_PATH}/bin:${PATH}
COPY python.sh /tmp/install_python.sh
RUN . /tmp/install_python.sh



COPY tensorflow-gpu.sh /tmp/install_tensorflow-gpu.sh
RUN . /tmp/install_tensorflow-gpu.sh

