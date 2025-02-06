#!/bin/bash
set -e

RSTUDIO_VERSION=${1:-${RSTUDIO_VERSION:-"stable"}}
NB_USER=${NB_USER:-"jovyan"}

apt-get update && apt-get -y install \
    ca-certificates \
    gdebi-core \
    git \
    libclang-dev \
    libssl-dev \
    lsb-release \
    psmisc \
    pwgen \
    sudo \
    wget

ARCH=$(dpkg --print-architecture)
source /etc/os-release

## Download RStudio Server for Ubuntu 18+
DOWNLOAD_FILE=rstudio-server.deb

if [ "$RSTUDIO_VERSION" = "latest" ]; then
    RSTUDIO_VERSION="stable"
fi

if [ "$UBUNTU_CODENAME" = "focal" ]; then
    UBUNTU_CODENAME="bionic"
fi

# TODO: remove this workaround for Ubuntu 24.04
if [ "$UBUNTU_CODENAME" = "noble" ]; then
    UBUNTU_CODENAME="jammy"
fi

if [ "$RSTUDIO_VERSION" = "stable" ] || [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
    if [ "$UBUNTU_CODENAME" = "bionic" ]; then
        UBUNTU_CODENAME="focal"
    fi
    wget "https://rstudio.org/download/latest/${RSTUDIO_VERSION}/server/${UBUNTU_CODENAME}/rstudio-server-latest-${ARCH}.deb" -O "$DOWNLOAD_FILE"
else
    wget "https://download2.rstudio.org/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE" ||
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
fi

gdebi --non-interactive "$DOWNLOAD_FILE"
rm "$DOWNLOAD_FILE"

ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin
ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin

# https://github.com/rocker-org/rocker-versioned2/issues/137
rm -f /var/lib/rstudio-server/secure-cookie-key

## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R

## Make RStudio compatible with case when R is built from source
## (and thus is at /usr/local/bin/R), because RStudio doesn't obey
## path if a user apt-get installs a package
R_BIN="$(which R)"
echo "rsession-which-r=${R_BIN}" >/etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" >/etc/rstudio/file-locks

## Prepare optional configuration file to disable authentication
## To de-activate authentication, `disable_auth_rserver.conf` script
## will just need to be overwrite /etc/rstudio/rserver.conf.
## This is triggered by an env var in the user config
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >>/etc/rstudio/disable_auth_rserver.conf


su ${NB_USER} -c "/opt/conda/bin/conda install -y jupyter-rsession-proxy"

