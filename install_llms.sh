#!/bin/bash

# opencode cli - installer hardcodes $HOME/.opencode/bin, so move to /usr/local/bin
curl -fsSL https://opencode.ai/install | bash && \
  mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode && \
  rm -rf "${HOME}/.opencode"

# opencode config — the image-baked file at $XDG_CONFIG_HOME/opencode/opencode.json
# serves as the sysadmin template. The Jupyter server startup hook below seeds a
# per-user copy at $HOME/.config/opencode/opencode.json on first launch, and
# /etc/profile.d/opencode.sh points OPENCODE_CONFIG at that HOME path so user edits
# persist across container restarts. Delete the user copy and restart to re-seed.
# Uses {env:VAR_NAME} syntax so the API key is never baked into the image.
mkdir -p ${XDG_CONFIG_HOME}/opencode
cat > ${XDG_CONFIG_HOME}/opencode/opencode.json <<'EOF'
{
  "model": "nrp/qwen3",
  "provider": {
    "nrp": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "NRP",
      "options": {
        "baseURL": "https://ellm.nrp-nautilus.io/v1",
        "apiKey": "{env:OPENAI_API_KEY}"
      },
      "models": {
        "qwen3": {
          "name": "Qwen3"
        },
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

# Redirect opencode to a HOME-resident config file so user edits persist across
# container restarts (the JupyterHub HOME volume is persistent; XDG_CONFIG_HOME is not).
# Set in /etc/profile.d so it applies per-user with ${HOME} expansion at shell init,
# and is picked up by interactive shells, jupyter-server-spawned terminals, and
# code-server child processes inheriting the jupyter server env.
cat > /etc/profile.d/opencode.sh <<'EOF'
# Per-user opencode config (seeded from /opt/share/xdg-config/opencode/opencode.json
# by the Jupyter server startup hook on first launch). Delete the file and restart
# the container to re-seed from the current sysadmin template.
export OPENCODE_CONFIG="${HOME}/.config/opencode/opencode.json"
EOF
chmod 0644 /etc/profile.d/opencode.sh

# Roo Cline pre-configuration via Jupyter server startup hook.
# /etc/jupyter/ is in Jupyter's config search path (outside $HOME, survives JupyterHub mounts).
# This script runs when the Jupyter server starts — before users access code-server.
# It generates a Roo settings import file with OPENAI_API_KEY from the environment,
# then sets roo-cline.autoImportSettingsPath in the code-server user settings.json.
# Roo re-reads autoImportSettingsPath on every extension activation, so the NRP provider
# and API key are configured automatically each session.
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_server_config.py <<'PYEOF'
"""Jupyter server startup hook: seed per-user opencode config and Roo Cline settings."""
import os, json, pathlib, logging, shutil
logger = logging.getLogger(__name__)

def _setup_opencode():
    # Seed the user's opencode config from the image-baked sysadmin template if
    # missing, then expose OPENCODE_CONFIG in the jupyter server env so code-server
    # and any child process inherits it (belt-and-suspenders with profile.d).
    template = pathlib.Path("/opt/share/xdg-config/opencode/opencode.json")
    user_config = pathlib.Path.home() / ".config/opencode/opencode.json"
    if not user_config.exists() and template.exists():
        user_config.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(template, user_config)
    os.environ.setdefault("OPENCODE_CONFIG", str(user_config))

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
                    "openAiModelId": "qwen3"
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
    _setup_opencode()
except Exception as e:
    logger.error(f"opencode setup failed: {e}")

try:
    _setup_roo_cline()
except Exception as e:
    logger.error(f"Roo Cline setup failed: {e}")
PYEOF
