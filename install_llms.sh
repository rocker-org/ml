#!/bin/bash

# goose CLI - install to system-wide location, skip interactive configure
curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | GOOSE_BIN_DIR=/usr/local/bin CONFIGURE=false bash

# vscode-goose extension (not on Open VSX, install from GitHub releases)
GOOSE_VSIX_URL=$(curl -fsSL https://api.github.com/repos/block/vscode-goose/releases/latest \
  | grep "browser_download_url.*\.vsix" | cut -d '"' -f 4)
curl -fsSL "$GOOSE_VSIX_URL" -o /tmp/vscode-goose.vsix
code-server --allow-root --extensions-dir ${CODE_EXTENSIONSDIR} --install-extension /tmp/vscode-goose.vsix
rm /tmp/vscode-goose.vsix
