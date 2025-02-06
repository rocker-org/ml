FROM rocker/cuda

USER root
# When run as root, R automagically handles any necessary apt-gets
COPY install.r install.r
RUN Rscript install.r

USER ${NB_USER}

## Python extensions
COPY spatial-env.yml environment.yml
RUN conda update --all --solver=classic -n base -c conda-forge conda && \
    conda env update --file environment.yml

