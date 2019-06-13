FROM nvidia/cuda:9.0-cudnn7-devel

## cuda:9.0 is xenial, cuda:10.0 is bionic
ARG UBUNTU_VERSION=xenial 
ARG R_HOME=/usr/lib/R
ARG DEBIAN_FRONTEND=noninteractive



COPY install_R.sh /tmp/install_R.sh
RUN  . /tmp/install_R.sh



COPY install_rstudio.sh /tmp/install_rstudio.sh
RUN . /tmp/install_rstudio.sh
COPY userconf.sh /etc/cont-init.d/userconf
EXPOSE 8787
CMD ["/init"]



