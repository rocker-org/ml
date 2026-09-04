#!/bin/bash
set -e

# Posit Assistant (the AI pane in RStudio 2026.04.0+) is not shipped inside the
# rstudio-server deb: RStudio downloads a Node bundle on first use into
# ~/.local/share/rstudio/pai/bin. That is a per-user, network-dependent step, so
# instead we bake the bundle into the image at the system-wide location RStudio
# searches next: /etc/rstudio/pai/bin (xdg systemConfigDir + "pai/bin").
#
# Lookup order in RStudio (ChatInstallation.cpp locatePositAssistantInstallation):
#   1. $RSTUDIO_POSIT_AI_PATH   2. ~/.local/share/rstudio/pai/bin   3. /etc/rstudio/pai/bin
# Using (3) rather than the env var deliberately leaves (2) available: if a user
# lets RStudio update the assistant, the newer copy in their persistent HOME
# wins over the image-baked one instead of being shadowed.

MANIFEST_URL="https://cdn.posit.co/posit-ai/manifest.json"
INSTALL_DIR="/etc/rstudio/pai/bin"

apt-get update && apt-get -y install unzip
rm -rf /var/lib/apt/lists/*

# The manifest keys releases by wire-protocol version ("9.0", "10.0", "11.0", ...).
# Take the highest, matching the current stable RStudio we install alongside it.
# If a future RStudio ever speaks an older protocol than the newest published
# bundle, this degrades gracefully -- RStudio reports the mismatch and offers to
# install the right version into the user's HOME.
read -r PAI_VERSION PAI_URL PAI_SHA256 <<EOF
$(curl -fsSL "$MANIFEST_URL" | python3 -c '
import json, sys
m = json.load(sys.stdin)["versions"]
p = max(m, key=lambda k: tuple(int(n) for n in k.split(".")))
v = m[p]
print(v["version"], v["url"], v["sha256"])
')
EOF

if [ -z "$PAI_URL" ]; then
    echo "ERROR: could not resolve a Posit Assistant build from ${MANIFEST_URL}" >&2
    exit 1
fi
echo "Installing Posit Assistant ${PAI_VERSION} to ${INSTALL_DIR}"

curl -fsSL "$PAI_URL" -o /tmp/pai.zip
echo "${PAI_SHA256}  /tmp/pai.zip" | sha256sum -c -

mkdir -p "$INSTALL_DIR"
unzip -q /tmp/pai.zip -d "$INSTALL_DIR"
rm -f /tmp/pai.zip

# RStudio only treats the directory as a valid install when all three exist.
for f in dist/server/main.js dist/client/index.html package.json; do
    if [ ! -e "${INSTALL_DIR}/${f}" ]; then
        echo "ERROR: Posit Assistant bundle is missing ${f}" >&2
        exit 1
    fi
done

# World-readable, root-owned: every user reads the same copy, nobody mutates it.
chmod -R a+rX "$INSTALL_DIR"

# Getting environment variables into the RStudio session is the hard part.
# rserver does NOT pass its own environment to rsession: it builds a curated
# ~27-variable environment (RS_*/RSTUDIO_*/R_* plus HOME/PATH/USER/LANG/SHELL/
# LD_LIBRARY_PATH/XDG_CONFIG_HOME) and drops everything else, so anything
# exported by the Jupyter server -- including RSTUDIO_POSIT_AI_PATH -- never
# arrives. /etc/rstudio/env-vars does not help
# either; rserver only setenv()s that into its own process.
#
# R's Renviron.site is the way through: R putenv()s it into the rsession
# process at startup, before the assistant is ever looked up, and the Node
# backend inherits it (SessionChat launches the backend with the full process
# environment, and RStudio's own source cites ~/.Renviron as how proxy vars
# reach it). This is the same reason set_renviron.sh exists in this repo.
#
# The file is chowned to the container user so the Jupyter startup hook can
# rewrite the block on each start.
#
# The block carries the install path and nothing else. No provider, base URL or
# key is baked in: users choose a provider in the assistant's own settings UI,
# and ~/.posit/assistant/settings.json is on the persistent HOME so the choice
# survives a restart.
RENVIRON_SITE="$(R RHOME)/etc/Renviron.site"
touch "$RENVIRON_SITE"
cat >> "$RENVIRON_SITE" <<EOF

# >>> rocker-ml posit-assistant >>>
# Managed by install_posit_assistant.sh and the Jupyter startup hook.
RSTUDIO_POSIT_AI_PATH=${INSTALL_DIR}
# <<< rocker-ml posit-assistant <<<
EOF
chown "${NB_USER:-jovyan}" "$RENVIRON_SITE"
