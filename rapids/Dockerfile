ARG BASE=quay.io/jupyter/pytorch-notebook:cuda12-ubuntu-24.04
FROM $BASE

RUN conda create -n rapids-25.02 -c rapidsai -c conda-forge -c nvidia rapids=25.02 python=3.12 cuda-version=12.8
RUN conda install cuda-cudart cuda-version=12
RUN pip install \
  --extra-index-url=https://pypi.nvidia.com \
  cudf-cu12==25.2.* \
  dask-cudf-cu12==25.2.* \
  cuml-cu12==25.2.* \
  cugraph-cu12==25.2.*

RUN pip install polars[gpu] --extra-index-url=https://pypi.nvidia.com


