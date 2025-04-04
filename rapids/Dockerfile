FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12
ENV CONDA_DIR=/opt/conda
ENV NB_USER=jovyan
ENTRYPOINT []

USER root
RUN useradd -G users,conda -ms /bin/bash ${NB_USER} && \
    cp -rp /home/rapids/. /home/${NB_USER}/ && \
    chown -R ${NB_USER}:users /home/${NB_USER}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]
USER ${NB_USER}

RUN mamba install \
  --channel conda-forge \
  --yes \
  "jupyterhub-singleuser==4.*"

CMD ["jupyter", "lab", "--ip", "0.0.0.0"]

