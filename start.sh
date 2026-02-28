#!/bin/bash
# Container entrypoint: seed goose config, then start JupyterLab.

GOOSE_CP_DIR="${HOME}/.config/goose/custom_providers"
mkdir -p "$GOOSE_CP_DIR"

# Copy NRP provider config if not already present (safe on JupyterHub persistent home)
if [ ! -f "$GOOSE_CP_DIR/nrp.json" ] && [ -f "/opt/share/goose/custom_providers/nrp.json" ]; then
    cp /opt/share/goose/custom_providers/nrp.json "$GOOSE_CP_DIR/nrp.json"
fi

exec jupyter lab --ip=0.0.0.0 --port=8888 --no-browser \
    --NotebookApp.token='' --NotebookApp.password=''
