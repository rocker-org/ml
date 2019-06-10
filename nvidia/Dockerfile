FROM nvidia/cuda:10.1-cudnn7-runtime

ARG DEBIAN_FRONTEND=noninteractive

RUN echo 'deb https://cloud.r-project.org/bin/linux/ubuntu bionic-cran35/' >> /etc/apt/sources.list && \
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add - && \
    apt-get update && apt-get -y install r-base
 

####### Set up env variables in R #######
ENV R_HOME=/usr/lib/R
ENV CUDA_HOME=/usr/local/cuda
ENV CUDA_PATH=/usr/local/cuda
ENV PATH=$CUDA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=$CUDA_HOME/lib64:$CUDA_HOME/extras/CUPTI/lib64:$LD_LIBRARY_PATH

#RUN echo "rsession-ld-library-path=$LD_LIBRARY_PATH" | tee -a /etc/rstudio/rserver.conf \
RUN echo "\n\
         \nCUDA_HOME=$CUDA_HOME \
         \nCUDA_PATH=$CUDA_PATH \
         \nPATH=$PATH" >> ${R_HOME}/etc/Renviron

######### Set up Python3 Virtual Environment to play nice with R ###
#ENV WORKON_HOME /opt/virtualenvs
#ENV PYTHON_VENV_PATH $WORKON_HOME/r-tensorflow

## Set up a user modifyable python3 environment
RUN apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-pip \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

#RUN python3 -m venv ${PYTHON_VENV_PATH}

#ENV PATH ${PYTHON_VENV_PATH}/bin:${PATH}
## And set ENV for R! It doesn't read from the environment...
#RUN echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron && \
#    echo "WORKON_HOME=${WORKON_HOME}" >> ${R_HOME}/etc/Renviron && \
#    echo "RETICULATE_PYTHON_ENV=${PYTHON_VENV_PATH}" >> ${R_HOME}/etc/Renviron


## reticulate will want virtualenv lib installed as well
#USER rstudio
RUN pip3 install --no-cache-dir virtualenv
#USER root

RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        libfreetype6-dev \
        libhdf5-serial-dev \
        libzmq3-dev \
        pkg-config \
        software-properties-common \
        unzip

RUN R -e "install.packages(c('keras'))"
RUN R -e "install.packages('remotes')"
RUN R -e "remotes::install_github('greta-dev/greta')"


## Because reticulate hardwires these PATHs...
#RUN ln -s ${PYTHON_VENV_PATH}/bin/pip /usr/local/bin/pip && \
#    ln -s ${PYTHON_VENV_PATH}/bin/virtualenv /usr/local/bin/virtualenv

# RUN chown -R rstudio:rstudio ${WORKON_HOME}

