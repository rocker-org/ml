FROM rocker/tf:gpu

# Python Xgboost for CPU
RUN pip3 install \
    wheel==0.33.0 \
    setuptools==40.8.0 \
    scipy==1.2.1 --upgrade
RUN pip3 install xgboost==0.81

## xgboost with multi-GPU support
RUN apt-get update && apt-get -y install wget \
  && wget https://s3-us-west-2.amazonaws.com/xgboost-wheels/xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl \
  && pip3 install  xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl \
  && rm https://s3-us-west-2.amazonaws.com/xgboost-wheels/xgboost-0.81-py2.py3-none-manylinux1_x86_64.whl

## Get Java (for h2o R package)
RUN apt-get update -qq \
  && apt-get -y --no-install-recommends install \
    cmake \
    default-jdk \
    default-jre \
  && R CMD javareconf

## h2o requires Java
RUN install2.r h2o
RUN install2.r greta

