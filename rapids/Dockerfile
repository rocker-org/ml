FROM nvcr.io/nvidia/rapidsai/notebooks:25.02-cuda12.0-py3.12

USER root
RUN apt-get update --yes && \
    # - `apt-get upgrade` is run to patch known vulnerabilities in system packages
    #   as the Ubuntu base image is rebuilt too seldom sometimes (less than once a month)
    apt-get upgrade --yes && \
    apt-get install --yes --no-install-recommends \
    # - bzip2 is necessary to extract the micromamba executable.
    bzip2 \
    ca-certificates \
    locales \
    # - `netbase` provides /etc/{protocols,rpc,services}, part of POSIX
    #   and required by various C functions like getservbyname and getprotobyname
    #   https://github.com/jupyter/docker-stacks/pull/2129
    netbase \
    sudo \
    # - `tini` is installed as a helpful container entrypoint,
    #   that reaps zombie processes and such of the actual executable we want to start
    #   See https://github.com/krallin/tini#why-tini for details
    tini \
    wget && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    echo "C.UTF-8 UTF-8" >> /etc/locale.gen && \
    locale-gen


# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER="rapids" \
    NB_GID=1000 \
    NB_UID=1001 \
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8 \
    LANGUAGE=C.UTF-8
ENV PATH="${CONDA_DIR}/bin:${PATH}" \
    HOME="/home/${NB_USER}"

# Copy a script that we will use to correct permissions after running certain commands
RUN cd /usr/local/bin && wget https://raw.githubusercontent.com/jupyter/docker-stacks/refs/heads/main/images/docker-stacks-foundation/fix-permissions && chmod a+rx /usr/local/bin/fix-permissions


# Create dirs for startup hooks
RUN mkdir /usr/local/bin/start-notebook.d && \
    mkdir /usr/local/bin/before-notebook.d

USER rapids


RUN cd /usr/local/bin && wget https://raw.githubusercontent.com/jupyter/docker-stacks/refs/heads/main/images/docker-stacks-foundation/run-hooks.sh && wget https://raw.githubusercontent.com/jupyter/docker-stacks/refs/heads/main/images/docker-stacks-foundation/start.sh && chmod a+rx start.sh && chmod a+rx run-hooks.sh

ENTRYPOINT ["tini", "-g", "--", "start.sh"]
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN mamba install -c conda-forge --yes \
    jupyterhub-singleuser jupyterlab nbclassic 'notebook>=7.2.2' && \
    jupyter server --generate-config && \
    mamba clean --all -f -y && \
    jupyter lab clean && \
    rm -rf "/home/${NB_USER}/.cache/yarn" 


USER root
RUN  fix-permissions "${CONDA_DIR}" && \
     fix-permissions "/home/${NB_USER}"

USER ${NB_USER}

WORKDIR "${HOME}"


