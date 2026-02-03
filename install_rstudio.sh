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

## Download RStudio Server for Ubuntu 18+
DOWNLOAD_FILE=rstudio-server.deb

if [ "$RSTUDIO_VERSION" = "latest" ]; then
    RSTUDIO_VERSION="stable"
fi

# Handle ARM64 architecture
# ARM64 builds are only available for jammy (22.04), not focal, bionic, or noble
if [ "$ARCH" = "arm64" ]; then
    echo "Detected ARM64 architecture, using appropriate RStudio Server build..."
    
    # ARM64 builds only available for Ubuntu 22.04 (jammy)
    # Noble (24.04) doesn't have separate ARM64 builds yet, use jammy
    if [ "$UBUNTU_CODENAME" != "jammy" ]; then
        echo "Using jammy build for ARM64 (current codename: $UBUNTU_CODENAME)..."
        UBUNTU_CODENAME="jammy"
    fi
    
    if [ "$RSTUDIO_VERSION" = "stable" ]; then
        # Use latest stable version from S3 bucket (verified working)
        # Current stable version as of Nov 2025
        RSTUDIO_VERSION="2025.09.2-418"
        echo "Downloading RStudio Server ${RSTUDIO_VERSION} for ARM64..."
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
    elif [ "$RSTUDIO_VERSION" = "preview" ] || [ "$RSTUDIO_VERSION" = "daily" ]; then
        # Use daily builds for preview/daily
        # Get the latest daily build number - using a recent known working version
        RSTUDIO_VERSION="2025.12.0-daily-302"
        echo "Downloading RStudio Server daily build ${RSTUDIO_VERSION} for ARM64..."
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
    else
        # User specified a specific version
        echo "Downloading RStudio Server ${RSTUDIO_VERSION} for ARM64..."
        wget "https://s3.amazonaws.com/rstudio-ide-build/server/${UBUNTU_CODENAME}/${ARCH}/rstudio-server-${RSTUDIO_VERSION/"+"/"-"}-${ARCH}.deb" -O "$DOWNLOAD_FILE"
    fi
else
    # AMD64/x86_64 architecture - use standard installation
    
    # Apply Ubuntu codename conversions for x86_64
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

# don't assume conda, let package manager handle this
# su ${NB_USER} -c "/opt/conda/bin/conda install -y jupyter-rsession-proxy"

## Append repo-specific env vars to Renviron
# We iterate over a whitelist of vars set in the Dockerfiles to ensure they
# are available in RStudio sessions.
VARS_TO_FORWARD="SHELL PYTHONBUFFERED CODE_EXTENSIONSDIR LANG VIRTUAL_ENV RETICULATE_PYTHON LD_LIBRARY_PATH GDAL_DATA PROJ_DATA GDAL_CONFIG PKG_CONFIG_PATH CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE PATH"
RENVIRON="$RHOME/etc/Renviron"

for VAR in $VARS_TO_FORWARD; do
    if [ -n "${!VAR}" ]; then
        VAL="${!VAR}"

        # If the file exists, remove any existing lines for this variable to avoid duplicates
        if [ -f "$RENVIRON" ]; then
            sed -i "/^${VAR}=/d" "$RENVIRON"
        fi
        
        # Append the new value
        echo "${VAR}=${VAL}" >> "$RENVIRON"
    fi
done

# Cleanup
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

