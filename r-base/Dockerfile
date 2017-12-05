FROM rocker/r-base
RUN apt-get update && apt-get -y install \
    python-virtualenv \
    python-pip && \
    pip install h5py pyyaml requests Pillow scipy && \
    install2.r --error keras && \
    R -e "keras::install_keras(tensorflow='gpu')"


