#!/bin/sh
set -e

apt-get update -qq && apt-get -y --no-install-recommends install \
    libxml2-dev \
    libcairo2-dev \
    libgit2-dev \
    libmariadbd-dev \
    libmariadb-client-lgpl-dev \
    libpq-dev \
    libsasl2-dev \
    libsqlite3-dev \
    libssh2-1-dev \
    unixodbc-dev && \
  rm -rf /var/lib/apt/lists/*

install2.r --error \
    --deps TRUE \
    tidyverse \
    dplyr \
    devtools \
    formatR \
    remotes \
    selectr \
    caTools \
    BiocManager

