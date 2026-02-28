#!/bin/bash
# Run rocker-ml locally with JupyterLab on http://localhost:8888
# Goose is configured to use the NRP provider (minimax-m2).

set -euo pipefail

# Pull OPENAI_API_KEY from ~/.bashrc without requiring an interactive shell
OPENAI_API_KEY=$(grep -oP '(?<=OPENAI_API_KEY=)\S+' ~/.bashrc | head -1)

if [[ -z "$OPENAI_API_KEY" ]]; then
  echo "ERROR: OPENAI_API_KEY not found in ~/.bashrc" >&2
  exit 1
fi

docker run --rm -p 8888:8888 \
  -e OPENAI_API_KEY="$OPENAI_API_KEY" \
  -e GOOSE_PROVIDER="nrp" \
  -e GOOSE_MODEL="minimax-m2" \
  rocker-ml:local
