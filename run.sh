#!/bin/bash
# Run rocker-ml locally with JupyterLab on http://localhost:8888
#
# The image ships with no AI provider configured -- opencode, Kilo Code and the
# RStudio assistant are all configured interactively by the user, and their
# config persists in $HOME. Nothing here needs an API key.

set -euo pipefail

docker run --rm -p 8888:8888 rocker-ml:local
