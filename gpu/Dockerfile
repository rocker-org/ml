
## Based on work by https://github.com/rocker-org/rocker/issues/273
## and particularly https://github.com/rocker-org/rocker/issues/273#issuecomment-349814504
##
## Based on Ubuntu 16.04 

FROM nvidia/cuda:8.0-cudnn6-runtime


## This handle reaches Carl and Dirk
MAINTAINER "Carl Boettiger and Dirk Eddelbuettel" rocker-maintainers@eddelbuettel.com


## Prepare R installation from 
RUN sh -c 'echo "deb http://cloud.r-project.org/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list' \
    && gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9 \
    && gpg -a --export E084DAB9 | apt-key add -

RUN apt-get update \
    && apt-get upgrade -y -q \
    && apt-get install -y --no-install-recommends \
           r-base \
           r-base-dev \
           r-cran-littler \
           libxml2-dev \
           libxt-dev \
           libssl-dev \
           libcurl4-openssl-dev \
           imagemagick \
           python-pip \
    && pip install --upgrade pip \
    && pip install virtualenv \
    && echo 'options(repos = c(CRAN = "https://cloud.r-project.org"))' >> /etc/R/Rprofile.site \
    && /usr/lib/R/site-library/littler/examples/install.r tensorflow keras \
    && r -e "keras::install_keras(tensorflow = 'gpu')"
