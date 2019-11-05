#!/bin/sh
set -e

R -e "install.packages('keras')"
R -e "install.packages('remotes'); remotes::install_github('greta-dev/greta')"

