#!/bin/sh

set -e

## CUDA environmental variables configuration for RStudio

## cli R inherits these, but RStudio needs to have these set in as follows:
## (From https://tensorflow.rstudio.com/tools/local_gpu.html#environment-variables)
echo "\n\
      \nCUDA_HOME=$CUDA_HOME\
      \nPATH=$PATH" >> ${R_HOME}/etc/Renviron 
 
if test -f /etc/rstudio/rserver.conf; then 
  echo "rsession-ld-library-path=$LD_LIBRARY_PATH" >> /etc/rstudio/rserver.conf
fi

touch /var/log/nvblas.log && chown :staff /var/log/nvblas.log
chmod a+rw /var/log/nvblas.log

## Configure R & RStudio to use drop-in CUDA blas
## Allow R to use CUDA for BLAS, with fallback on openblas
echo "\nNVBLAS_LOGFILE /var/log/nvblas.log \
      \nNVBLAS_CPU_BLAS_LIB /usr/lib/x86_64-linux-gnu/openblas/libblas.so.3 \
      \nNVBLAS_GPU_LIST ALL" > /etc/nvblas.conf

echo "NVBLAS_CONFIG_FILE=$NVBLAS_CONFIG_FILE" >> ${R_HOME}/etc/Renviron


## We don't want to set LD_PRELOAD globally
##ENV LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so
#
### Instead, we will set it before calling R, Rscript, or RStudio:
#mv /usr/bin/R /usr/bin/R_
#mv /usr/bin/Rscript /usr/bin/Rscript_
#
#echo '\#!/bin/sh \
#      \n LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/bin/R_ "$@"' \
#      > /usr/bin/R && \
#    chmod +x /usr/bin/R && \
#    echo '#!/bin/sh \
#          \n LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so /usr/bin/Rscript_ "$@"' \
#      > /usr/bin/Rscript && \
#    chmod +x /usr/bin/Rscript
#
#echo '#!/usr/bin/with-contenv bash \
#      \n## load /etc/environment vars first: \
#      \n for line in \$( cat /etc/environment ) ; do export $line ; done \
#      \n export LD_PRELOAD=/usr/local/cuda/lib64/libnvblas.so \
#      \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0' \
#      > /etc/services.d/rstudio/run
#
