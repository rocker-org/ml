#/bin/sh

## Python3  
apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-pip \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*

python3 -m venv ${PYTHON_VENV_PATH}

## And set ENV for R; it doesn't read from the environment...
#    echo "PATH=${PATH}" >> ${R_HOME}/etc/Renviron && \
#    echo "WORKON_HOME=${WORKON_HOME}" >> ${R_HOME}/etc/Renviron && \
#    echo "RETICULATE_PYTHON_ENV=${PYTHON_VENV_PATH}" >> ${R_HOME}/etc/Renviron

## Reticulate needs this too?
pip3 install --no-cache-dir virtualenv




