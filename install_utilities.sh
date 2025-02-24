#!/bin/bash

# some apt-get utilities. 
# NOTE: BSPM will get those required for any R packages.
apt-get update -qq && apt-get -y install \
  vim git-lfs wget curl qpdf sudo libcurl4-openssl-dev libxml2-dev python3-venv gettext

# ensure user owns all of /opt/share (e.g. for vscode-plugins)
mkdir /opt/share && chown -R ${NB_USER}:users /opt/share

# awscli tool for S3 use
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
     unzip awscliv2.zip && \
     ./aws/install

# minio client for S3 use
curl https://dl.min.io/client/mc/release/linux-amd64/mc -o /usr/local/bin/mc && chmod +x /usr/local/bin/mc

# optional git config
# git config --system pull.rebase false && \
# git config --system credential.credentialStore cache && \
# git config --system credential.cacheOptions "--timeout 30000" && \
# echo '"\e[5~": history-search-backward' >> /etc/inputrc && \
# echo '"\e[6~": history-search-forward' >> /etc/inputrc

# Optional credential manager for RStudio/Jupyter users. -- code-server extension provides easier alternative. 
# wget https://github.com/git-ecosystem/git-credential-manager/releases/download/v2.6.0/gcm-linux_amd64.2.6.0.deb && dpkg -i gcm-*.deb && rm gcm-*.deb
# git-credential-manager configure --system


