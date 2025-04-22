# use rocker/cuda if NVIDIA drivers are needed, otherwise rocker/ml is a good choice
ARG BASE=rocker/ml
FROM $BASE 

# When run at build time, R automagically handles any necessary apt-gets
COPY install.r install.r
RUN Rscript install.r

## Python extensions
COPY environment.yml environment.yml
RUN mamba env update --file environment.yml

# GDAL
ENV CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE=YES

