#!/bin/bash

# opencode cli - installer hardcodes $HOME/.opencode/bin, so move to /usr/local/bin
curl -fsSL https://opencode.ai/install | bash && \
  mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode && \
  rm -rf "${HOME}/.opencode"

# opencode config — stored under $XDG_CONFIG_HOME so it survives JupyterHub volume mounts.
# Uses {env:VAR_NAME} syntax so the API key is never baked into the image.
mkdir -p ${XDG_CONFIG_HOME}/opencode
cat > ${XDG_CONFIG_HOME}/opencode/opencode.json <<'EOF'
{
  "model": "nrp/minimax-m2",
  "provider": {
    "nrp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "NRP",
      "options": {
        "baseURL": "https://ellm.nrp-nautilus.io/v1",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "minimax-m2": {
          "name": "MiniMax M2"
        }
      }
    },
    "copilot": {}
  }
}
EOF
chown -R ${NB_USER:-jovyan}:users ${XDG_CONFIG_HOME}/opencode

# Roo Cline pre-configuration via Jupyter server startup hook.
# /etc/jupyter/ is in Jupyter's config search path (outside $HOME, survives JupyterHub mounts).
# This script runs when the Jupyter server starts — before users access code-server.
# It generates a Roo settings import file with OPENAI_API_KEY from the environment,
# then sets roo-cline.autoImportSettingsPath in the code-server user settings.json.
# Roo re-reads autoImportSettingsPath on every extension activation, so the NRP provider
# and API key are configured automatically each session.
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_server_config.py <<'PYEOF'
"""Jupyter server startup hook: configure Roo Cline with NRP provider from env vars."""
import os, json, pathlib, logging
logger = logging.getLogger(__name__)

def _setup_roo_cline():
    api_key = os.environ.get("OPENAI_API_KEY", "")
    settings_dir = pathlib.Path("/tmp/roo-cline")
    settings_dir.mkdir(exist_ok=True)
    settings_file = settings_dir / "nrp-settings.json"
    settings_file.write_text(json.dumps({
        "providerProfiles": {
            "currentApiConfigName": "NRP",
            "apiConfigs": {
                "NRP": {
                    "apiProvider": "openai",
                    "openAiBaseUrl": "https://ellm.nrp-nautilus.io/v1",
                    "openAiApiKey": api_key,
                    "openAiModelId": "minimax-m2"
                }
            }
        }
    }, indent=2))
    # Update code-server user settings.json to point Roo at the generated file.
    # code-server user-data-dir defaults to ~/.local/share/code-server (in $HOME persistent volume).
    cs_settings_dir = pathlib.Path.home() / ".local/share/code-server/User"
    cs_settings_dir.mkdir(parents=True, exist_ok=True)
    cs_settings_file = cs_settings_dir / "settings.json"
    try:
        existing = json.loads(cs_settings_file.read_text()) if cs_settings_file.exists() else {}
    except Exception:
        existing = {}
    existing["roo-cline.autoImportSettingsPath"] = str(settings_file)
    cs_settings_file.write_text(json.dumps(existing, indent=2))

try:
    _setup_roo_cline()
except Exception as e:
    logger.error(f"Roo Cline setup failed: {e}")
PYEOF
