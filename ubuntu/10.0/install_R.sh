#!/bin/sh


echo "deb https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_VERSION}-cran35/" >> /etc/apt/sources.list && \
    gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys E298A3A825C0D65DFD57CBB651716619E084DAB9 && \
    gpg -a --export E298A3A825C0D65DFD57CBB651716619E084DAB9 | apt-key add - && \
    apt-get update && apt-get -y install r-base && \
    rm -rf /var/lib/apt/lists/*


