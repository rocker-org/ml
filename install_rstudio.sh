#!/bin/bash
set -e

RSTUDIO_VERSION=${1:-${RSTUDIO_VERSION:-"stable"}}
NB_USER=${NB_USER:-"jovyan"}

export RHOME=$(R RHOME)
export DEBIAN_FRONTEND=noninteractive

# Fix any interrupted dpkg processes
dpkg --configure -a

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

## RStudio Server package we download and install below
DOWNLOAD_FILE=rstudio-server.deb

# Normalize "latest" to "stable"
if [ "$RSTUDIO_VERSION" = "latest" ]; then
    RSTUDIO_VERSION="stable"
fi

# RStudio Server .deb builds are only published for a limited set of Ubuntu
# codenames, so map the ones we run on to the nearest available build:
#   - noble (24.04) has no dedicated server build yet -> use jammy
#   - focal (20.04) -> use jammy
#   - arm64 is only published for jammy
case "$UBUNTU_CODENAME" in
    noble | focal) UBUNTU_CODENAME="jammy" ;;
esac
if [ "$ARCH" = "arm64" ] && [ "$UBUNTU_CODENAME" != "jammy" ]; then
    UBUNTU_CODENAME="jammy"
fi

# Resolve the "stable" keyword to a concrete version number.
#
# The old https://rstudio.org/download/latest/stable/... "latest" redirect now
# returns 404 (rocker-org/ml#48), so instead we read the current published
# version from Posit's version file and download the numbered artifact directly.
# current.ver looks like "2026.07.0+139.pro9"; strip the trailing Pro suffix and
# turn the build separator "+" into "-" to get the open-source package version,
# e.g. "2026.07.0-139".
if [ "$RSTUDIO_VERSION" = "stable" ]; then
    RSTUDIO_VERSION="$(wget -qO- https://download2.rstudio.org/current.ver | sed -e 's/\.pro[0-9]*$//' -e 's/+/-/')"
    if [ -z "$RSTUDIO_VERSION" ]; then
        echo "ERROR: could not resolve the latest stable RStudio Server version" >&2
        exit 1
    fi
    echo "Resolved latest stable RStudio Server version: ${RSTUDIO_VERSION}"
fi

if [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
    # Resolve the latest daily server build for this platform from the dailies
    # index (JSON) and download the URL it advertises directly.
    echo "Resolving latest daily RStudio Server build for ${UBUNTU_CODENAME}/${ARCH}..."
    DAILY_URL="$(wget -qO- https://dailies.rstudio.com/rstudio/latest/index.json |
        grep -o "https://[^\"]*/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-[^\"]*\.deb" | head -n1)"
    if [ -z "$DAILY_URL" ]; then
        echo "ERROR: could not resolve a daily RStudio Server build for ${UBUNTU_CODENAME}/${ARCH}" >&2
        exit 1
    fi
    echo "Downloading ${DAILY_URL}"
    wget "$DAILY_URL" -O "$DOWNLOAD_FILE"
else
    # Concrete version number (passed in explicitly or resolved from "stable").
    # Normalize any "+" build separator to "-" to match the package filename.
    RSTUDIO_VERSION="${RSTUDIO_VERSION/"+"/"-"}"
    echo "Downloading RStudio Server ${RSTUDIO_VERSION} for ${UBUNTU_CODENAME}/${ARCH}..."
    # download2 hosts the current x86_64 release; the S3 build bucket is the
    # fallback and also serves arm64 builds and older versions.
    wget "https://download2.rstudio.org/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb" -O "$DOWNLOAD_FILE" ||
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
fi

gdebi --non-interactive "$DOWNLOAD_FILE"
rm "$DOWNLOAD_FILE"

ln -fs /usr/lib/rstudio-server/bin/rstudio-server /usr/local/bin
ln -fs /usr/lib/rstudio-server/bin/rserver /usr/local/bin

# https://github.com/rocker-org/rocker-versioned2/issues/137
rm -f /var/lib/rstudio-server/secure-cookie-key

# RStudio 2026.05.0 "Golden Wattle" reads a root-owned session-rpc-key at
# rserver startup. When run rootless via jupyter-rsession-proxy (as jovyan),
# the baked root:root 0600 key is unreadable and rserver exits 1. Remove it so
# it is regenerated per-run with appropriate ownership. See rocker-org/ml#42.
rm -f /var/lib/rstudio-server/session-rpc-key

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

# don't assume conda, let package manager handle this
# su ${NB_USER} -c "/opt/conda/bin/conda install -y jupyter-rsession-proxy"

# Cleanup
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
