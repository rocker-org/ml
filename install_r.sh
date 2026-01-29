#!/bin/bash
set -e

# determine Ubuntu release
source /etc/os-release

# detect architecture
ARCH=$(dpkg --print-architecture)

## First: update apt and get keys
apt-get update -qq && apt-get install --yes --no-install-recommends wget ca-certificates gnupg
wget -q -O- https://eddelbuettel.github.io/r2u/assets/dirk_eddelbuettel_key.asc \
    | tee -a /etc/apt/trusted.gpg.d/cranapt_key.asc

## Second: add the repo -- here we use the well-connected mirror
echo "deb [arch=${ARCH}] https://r2u.stat.illinois.edu/ubuntu ${UBUNTU_CODENAME} main" > /etc/apt/sources.list.d/cranapt.list
apt-get update

## Third: ensure current R is used
wget -q -O- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc \
    | tee -a /etc/apt/trusted.gpg.d/cran_ubuntu_key.asc
echo "deb [arch=${ARCH}] https://cloud.r-project.org/bin/linux/ubuntu ${UBUNTU_CODENAME}-cran40/" > /etc/apt/sources.list.d/cran_r.list
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 67C2D66C4B1D4339 51716619E084DAB9
apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install --yes --no-install-recommends r-base r-base-dev r-recommended

## Fourth: add pinning to ensure package sorting
echo "Package: *" > /etc/apt/preferences.d/99cranapt
echo "Pin: release o=CRAN-Apt Project" >> /etc/apt/preferences.d/99cranapt
echo "Pin: release l=CRAN-Apt Packages" >> /etc/apt/preferences.d/99cranapt
echo "Pin-Priority: 700"  >> /etc/apt/preferences.d/99cranapt

## Fifth: install bspm (and its Python requirements) and enable it
## If needed (in bare container, say) install python tools for bspm and R itself
apt-get install --yes --no-install-recommends python3-{dbus,gi,apt} \
	make sudo r-cran-{docopt,littler,remotes} 
## Then install bspm (as root) and enable it, and enable a speed optimization
Rscript -e 'install.packages("bspm")'
R_HOME=$(R RHOME)

# must go first.  Only configure for ROOT user
#echo "options(bspm.sudo = TRUE)" >> /root/.Rprofile
#echo "options(bspm.version.check=FALSE)" >> /root/.Rprofile
#echo "suppressMessages(bspm::enable())" >> /root/.Rprofile

# packages installed by root / bspm will go in /usr/lib/R/site-library
usermod -a -G users ${NB_USER}
chgrp -R users /usr/local/lib/R/site-library
chgrp -R users /usr/lib/R/site-library
chmod -R g+ws /usr/local/lib/R/site-library
chmod -R g+ws /usr/lib/R/site-library

# Cleanup
rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

ln -s /usr/lib/R/site-library/littler/examples/install2.r /usr/local/bin/install2.r
ln -s /usr/lib/R/site-library/littler/examples/installRub.r /usr/local/bin/installRub.r

## add user to sudoers -- not jupyterhub compatible(?)
# echo "${NB_USER} ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

## switch non-root users from BSPM to r-universe if no sudo 
wget https://raw.githubusercontent.com/rocker-org/ml/refs/heads/master/Rprofile
mv Rprofile ${R_HOME}/etc/Rprofile.site

rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
