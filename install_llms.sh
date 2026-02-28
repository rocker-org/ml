#!/bin/bash

# goose CLI - install to system-wide location, skip interactive configure
curl -fsSL https://github.com/block/goose/releases/download/stable/download_cli.sh | GOOSE_BIN_DIR=/usr/local/bin CONFIGURE=false bash
chown root:root /usr/local/bin/goose

# vscode-goose extension (not on Open VSX, install from GitHub releases)
# Must run as NB_USER: code-server 4.x does not support --allow-root
GOOSE_VSIX_URL=$(curl -fsSL https://api.github.com/repos/block/vscode-goose/releases/latest \
  | grep "browser_download_url.*\.vsix" | cut -d '"' -f 4)
curl -fsSL "$GOOSE_VSIX_URL" -o /tmp/vscode-goose.vsix
sudo -u ${NB_USER:-jovyan} code-server --extensions-dir ${CODE_EXTENSIONSDIR} --install-extension /tmp/vscode-goose.vsix
rm /tmp/vscode-goose.vsix

# NRP custom provider config.
# Stored under $XDG_CONFIG_HOME (set to /opt/share/xdg-config in Dockerfile),
# so goose finds it without touching $HOME — survives JupyterHub volume mounts.
mkdir -p ${XDG_CONFIG_HOME}/goose/custom_providers
cat > ${XDG_CONFIG_HOME}/goose/custom_providers/nrp.json <<'EOF'
{
  "name": "nrp",
  "engine": "openai",
  "display_name": "NRP",
  "description": "NRP Nautilus OpenAI-compatible LLM endpoint",
  "api_key_env": "OPENAI_API_KEY",
  "base_url": "https://ellm.nrp-nautilus.io/v1",
  "models": [
    {
      "name": "minimax-m2",
      "context_limit": 40960
    }
  ],
  "supports_streaming": true,
  "requires_auth": true
}
EOF
chown -R ${NB_USER:-jovyan}:users ${XDG_CONFIG_HOME}
