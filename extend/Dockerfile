FROM rocker/cuda

# When run as root, R automagically handles any necessary apt-gets
COPY install.r install.r
RUN Rscript install.r

## Python extensions
COPY environment.yml environment.yml
RUN conda update --all --solver=classic -n base -c conda-forge conda && \
    conda env update --file environment.yml

