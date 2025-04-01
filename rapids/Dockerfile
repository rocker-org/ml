FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12
ENTRYPOINT []
ENV CONDA_DIR=/opt/conda

RUN mamba install \
  --channel conda-forge \
  --yes \
  "jupyterhub-singleuser==4.*"

