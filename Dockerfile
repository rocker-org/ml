ARG BASE=rapidsai/ci-conda
FROM ${BASE}

ENV SHELL=/bin/bash
# Don't buffer Python stdout/stderr output
ENV PYTHONBUFFERED=1
# Don't prompt in apt commands
ENV DEBIAN_FRONTEND=noninteractive
# persistent install for vscode extensions
ENV CODE_EXTENSIONSDIR=/opt/share/code-server

# Set up JupyterLab user
ARG NB_USER=jovyan
ENV NB_USER=${NB_USER}
ENV NB_UID=1000
ENV USER="${NB_USER}"
ENV HOME="/home/${NB_USER}"


USER root

# change ubuntu to jovyan (consistent with Jupyter stacks for home dir mapping)
RUN usermod -l ${NB_USER} ubuntu && \
    usermod -d /home/${NB_USER} -m ${NB_USER}

# Create conda group if it doesn't exist, and add user to it
RUN getent group conda || groupadd conda && usermod -aG conda $NB_USER

# Fix permissions on /opt/conda directories so user can write to them

# Fix permissions on /opt/conda directories so user can write to them
# We only change directories to avoid copying all file data (doubling image size)
RUN find /opt/conda -type d ! -group conda -exec chgrp conda {} + && \
    find /opt/conda -type d ! -perm -g+w -exec chmod g+rwx {} +

USER ${NB_USER}
# Install additional conda packages into base environment
COPY environment.yml /tmp/environment.yml
RUN . /opt/conda/etc/profile.d/conda.sh; conda activate base && \
    mamba env update --file /tmp/environment.yml && \
    mamba clean -afy

USER root
RUN apt-get update && apt-get -y install curl && rm -rf /var/lib/apt/lists/*

# install vscode
RUN curl -fsSL https://code-server.dev/install.sh | sh && rm -rf .cache 

# apt utilities, code-server setup
RUN curl -s https://raw.githubusercontent.com/rocker-org/ml/refs/heads/master/install_utilities.sh | bash

## Grant user sudoer privileges
RUN adduser "$NB_USER" sudo && echo '%sudo ALL=(ALL) NOPASSWD:ALL' >>/etc/sudoers

# Install R
COPY install_r.sh install_r.sh
RUN bash install_r.sh

# RStudio
COPY install_rstudio.sh install_rstudio.sh
RUN bash install_rstudio.sh

COPY Rprofile /usr/lib/R/etc/Rprofile.site

## Add rstudio's binaries to path for quarto
ENV PATH=$PATH:/usr/lib/rstudio-server/bin/quarto/bin

# activate base by default in bashrc
# RUN sed 's/conda activate base/conda activate base/' /home/$NB_USER/.bashrc > /etc/profile.d/bashrc

WORKDIR /home/$NB_USER 
USER $NB_USER

COPY vscode-extensions.txt /tmp/vscode-extensions.txt
RUN xargs -n 1 code-server --extensions-dir ${CODE_EXTENSIONSDIR}  --install-extension < /tmp/vscode-extensions.txt

# When run at build-time, install.r automagically handles any necessary apt-gets
COPY install.r /tmp/install.r
RUN Rscript /tmp/install.r 

## additions for this image
COPY install_spatial.r /tmp/install.r
RUN Rscript /tmp/install.r 

USER $NB_USER

CMD ["jupyter", "lab", "--no-browser", "--ip=0.0.0.0"]


