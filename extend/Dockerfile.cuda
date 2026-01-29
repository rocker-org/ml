ARG BASE=rocker/ml
FROM $BASE 

# When run at build time, R automagically handles any necessary apt-gets
COPY install.r install.r
RUN Rscript install.r && \\\n    rm -rf /tmp/* /var/tmp/*

## Python extensions
COPY environment.yml environment.yml
RUN mamba env update -n base --file environment.yml && \\\n    mamba clean -afy && \\\n    find /opt/conda -type f -name '*.pyc' -delete && \\\n    find /opt/conda -type f -name '*.pyo' -delete && \\\n    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true && \\\n    find /opt/conda/lib -name '*.a' -delete 2>/dev/null || true && \\\n    rm -rf /tmp/*

# GDAL
ENV CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE=YES

