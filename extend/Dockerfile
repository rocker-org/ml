ARG BASE=rocker/ml
FROM $BASE 

# When run at build time, R automagically handles any necessary apt-gets
COPY install.r install.r
RUN Rscript install.r && \
    rm -rf /tmp/* /var/tmp/*

## Python extensions
COPY environment.yml environment.yml
COPY clean_conda.sh /tmp/clean_conda.sh
RUN mamba env update -n base --file environment.yml && \
    bash /tmp/clean_conda.sh

# GDAL
ENV CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE=YES
