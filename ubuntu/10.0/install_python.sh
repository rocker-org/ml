#/bin/sh

apt-get update && apt-get install -y --no-install-recommends \
        libpython3-dev \
        python3-pip \
        python3-venv && \
    rm -rf /var/lib/apt/lists/*
python3 -m venv ${PYTHON_VENV_PATH}
pip3 install --no-cache-dir virtualenv

