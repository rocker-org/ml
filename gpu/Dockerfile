FROM nvidia/cuda:8.0-cudnn6-runtime

RUN apt-get update -q && apt-get upgrade -y -q

## R installation
RUN sh -c 'echo "deb http://cran.rstudio.com/bin/linux/ubuntu xenial/" >> /etc/apt/sources.list'
RUN gpg --keyserver keyserver.ubuntu.com --recv-key E084DAB9
RUN gpg -a --export E084DAB9 | apt-key add -
RUN apt-get update
RUN apt-get install -y r-base r-base-dev libxml2-dev libxt-dev libssl-dev libcurl4-openssl-dev imagemagick

## Python dependencies
RUN apt-get update && apt-get -y upgrade
RUN apt-get install python-pip python-virtualenv -y
RUN pip install virtualenv

## R packages
RUN R -e "install.packages('devtools', repos = 'https://cloud.r-project.org')"
RUN R -e "devtools::install_github('rstudio/tensorflow')"
RUN R -e "devtools::install_github('rstudio/keras')"
RUN R -e "keras::install_keras(tensorflow = 'gpu')"
