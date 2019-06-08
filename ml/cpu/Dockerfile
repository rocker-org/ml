FROM rocker/tensorflow:3.6.0

# Python Xgboost for CPU
USER rstudio
RUN pip3 --no-cache-dir install \
    xgboost==0.81 \
    wheel==0.33.0 \
    setuptools==40.8.0 \
    scipy==1.2.1
USER root

## Get Java (for h2o R package)
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    cmake \
    default-jdk \
    default-jre \
  && R CMD javareconf

## h2o requires Java
RUN install2.r h2o
#RUN install2.r greta
RUN installGithub.r greta-dev/greta

