#!/bin/sh
set -e

RSTUDIO_VERSION=1.2.1335
S6_VERSION=${S6_VERSION:-v1.21.7.0}
S6_BEHAVIOUR_IF_STAGE2_FAILS=2
PANDOC_TEMPLATES_VERSION=${PANDOC_TEMPLATES_VERSION:-2.6}
export PATH=/usr/lib/rstudio-server/bin:$PATH


## Download and install RStudio server & dependencies
## Attempts to get detect latest version, otherwise falls back to version given in $VER
## Symlink pandoc, pandoc-citeproc so they are available system-wide
apt-get update \
  && apt-get install -y --no-install-recommends \
    file \
    git \
    libapparmor1 \
    libcurl4-openssl-dev \
    libedit2 \
    libssl-dev \
    lsb-release \
    psmisc \
    procps \
    python-setuptools \
    sudo \
    wget \
    libclang-dev \
    libobjc-5-dev \
    libgc1c2 \
  && rm -rf /var/lib/apt/lists/*

## NOTE: xenial also uses 'trusty' URL here for latest version. 
RSTUDIO_URL="https://download2.rstudio.org/server/trusty/amd64/rstudio-server-${RSTUDIO_VERSION}-amd64.deb"

wget -q $RSTUDIO_URL \
  && dpkg -i rstudio-server-*-amd64.deb \
  && rm rstudio-server-*-amd64.deb

## Symlink pandoc & standard pandoc templates for use system-wide
ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc /usr/local/bin \
  && ln -s /usr/lib/rstudio-server/bin/pandoc/pandoc-citeproc /usr/local/bin \
  && git clone --recursive --branch ${PANDOC_TEMPLATES_VERSION} https://github.com/jgm/pandoc-templates \
  && mkdir -p /opt/pandoc/templates \
  && cp -r pandoc-templates*/* /opt/pandoc/templates && rm -rf pandoc-templates* \
  && mkdir /root/.pandoc && ln -s /opt/pandoc/templates /root/.pandoc/templates


## RStudio wants an /etc/R, will populate from $R_HOME/etc
mkdir -p /etc/R \
  && echo "\n\
    \n# Configure httr to perform out-of-band authentication if HTTR_LOCALHOST \
    \n# is not set since a redirect to localhost may not work depending upon \
    \n# where this Docker container is running. \
    \nif(is.na(Sys.getenv('HTTR_LOCALHOST', unset=NA))) { \
    \n  options(httr_oob_default = TRUE) \
    \n}" >> ${R_HOME}/etc/Rprofile.site \
  && echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron


## Need to configure non-root user for RStudio
useradd rstudio \
  && echo "rstudio:rstudio" | chpasswd \
  && mkdir /home/rstudio \
  && chown rstudio:rstudio /home/rstudio \
  && addgroup rstudio staff 
  ## Prevent rstudio from deciding to use /usr/bin/R if a user apt-get installs a package

R_BIN=`which R`
echo "rsession-which-r=${R_BIN}" >> /etc/rstudio/rserver.conf
## use more robust file locking to avoid errors when using shared volumes:
echo "lock-type=advisory" >> /etc/rstudio/file-locks

## Optional configuration file to disable authentication
cp /etc/rstudio/rserver.conf /etc/rstudio/disable_auth_rserver.conf
echo "auth-none=1" >> /etc/rstudio/disable_auth_rserver.conf

## configure git not to request password each time
git config --system credential.helper 'cache --timeout=3600' \
  && git config --system push.default simple

## Set up S6 init system
wget -P /tmp/ https://github.com/just-containers/s6-overlay/releases/download/${S6_VERSION}/s6-overlay-amd64.tar.gz \
  && tar xzf /tmp/s6-overlay-amd64.tar.gz -C / \
  && mkdir -p /etc/services.d/rstudio \
  && echo "#!/usr/bin/with-contenv bash \
          \n## load /etc/environment vars first: \
          \n for line in $( cat /etc/environment ) ; do export $line > /dev/null; done \
          \n exec /usr/lib/rstudio-server/bin/rserver --server-daemonize 0" \
          > /etc/services.d/rstudio/run \
  && echo "#!/bin/bash \
          \n rstudio-server stop" \
          > /etc/services.d/rstudio/finish \
  && mkdir -p /home/rstudio/.rstudio/monitored/user-settings \
  && echo "alwaysSaveHistory='0' \
          \nloadRData='0' \
          \nsaveAction='0'" \
          > /home/rstudio/.rstudio/monitored/user-settings/user-settings \
  && chown -R rstudio:rstudio /home/rstudio/.rstudio


#COPY userconf.sh /etc/cont-init.d/userconf
# EXPOSE 8787
# CMD ["/init"]
