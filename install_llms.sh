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

# Kilo Code (VS Code extension) config persistence.
#
# Kilo v7 is an opencode fork: its data/, state/ and cache/ dirs are HOME-resident
# (~/.local/share/kilo, ~/.local/state/kilo, ~/.cache/kilo -- all persistent on
# JupyterHub), but its *config* dir is $XDG_CONFIG_HOME/kilo, and this image points
# XDG_CONFIG_HOME at /opt/share/xdg-config, which is image-resident and therefore
# thrown away on every restart. Anything a user configures in the Kilo UI that lands
# in kilo.json -- custom providers, custom models, agents, MCP servers -- was lost.
#
# Fix: replace $XDG_CONFIG_HOME/kilo with a symlink into the persistent HOME, so the
# extension reads and writes ~/.config/kilo without knowing anything about it. The
# sysadmin template stays outside HOME (a build-time write to $HOME is shadowed by
# the JupyterHub volume mount) and is copied in on first launch by the startup hook.
mkdir -p /opt/share/kilo-template
cat > /opt/share/kilo-template/kilo.json <<'EOF'
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
rm -rf ${XDG_CONFIG_HOME}/kilo
ln -s /home/${NB_USER:-jovyan}/.config/kilo ${XDG_CONFIG_HOME}/kilo
chown -h ${NB_USER:-jovyan}:users ${XDG_CONFIG_HOME}/kilo
chown -R ${NB_USER:-jovyan}:users /opt/share/kilo-template

# Kilo Code (and Posit Assistant) pre-configuration via Jupyter server startup hook.
# /etc/jupyter/ is in Jupyter's config search path (outside $HOME, survives JupyterHub mounts).
# This script runs when the Jupyter server starts — before users access code-server.
# It repairs the $XDG_CONFIG_HOME/kilo -> ~/.config/kilo symlink and seeds the user's
# kilo.json from the image-baked template on first launch. The API key is not written
# into the file: {env:OPENAI_API_KEY} is resolved by Kilo at read time from the
# environment the extension host inherits.
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_server_config.py <<'PYEOF'
"""Jupyter server startup hook: seed per-user opencode, Kilo Code and Posit Assistant settings."""
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

def _setup_kilo():
    # Kilo reads its global config from $XDG_CONFIG_HOME/kilo, which this image points
    # outside $HOME so that image-baked config is not shadowed by the JupyterHub volume
    # mount -- but that also means anything Kilo *writes* there (custom providers and
    # models added from the UI, agents, MCP servers) is discarded on restart. The build
    # replaces that directory with a symlink to ~/.config/kilo, on the persistent HOME
    # volume; re-assert it here so a container whose /opt/share predates this change, or
    # in which something recreated a real directory, still ends up persistent.
    xdg = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", str(pathlib.Path.home() / ".config")))
    link = xdg / "kilo"
    target = pathlib.Path.home() / ".config/kilo"
    target.mkdir(parents=True, exist_ok=True)
    if link.resolve() != target.resolve():
        if link.is_symlink():
            link.unlink()
        elif link.is_dir():
            # Salvage anything already written into the ephemeral location.
            for item in link.iterdir():
                dest = target / item.name
                if not dest.exists():
                    shutil.move(str(item), str(dest))
            shutil.rmtree(link)
        link.parent.mkdir(parents=True, exist_ok=True)
        link.symlink_to(target)

    # Seed the NRP provider on first launch. The template uses {env:OPENAI_API_KEY},
    # which Kilo expands at read time, so no secret is written to disk. Later edits
    # from the Kilo UI land in this same file and now survive a restart; delete it and
    # restart to go back to the template.
    template = pathlib.Path("/opt/share/kilo-template/kilo.json")
    user_config = target / "kilo.json"
    if not user_config.exists() and template.exists():
        shutil.copyfile(template, user_config)

def _setup_posit_assistant():
    # Posit Assistant (the AI pane in RStudio) is baked into the image by
    # install_posit_assistant.sh, which also writes a managed block into R's
    # Renviron.site with the install path and the provider base URL.
    #
    # Why Renviron.site and not the environment: rserver hands rsession a
    # curated ~27-variable environment and drops everything else, so nothing
    # exported here ever reaches the RStudio session. R reads Renviron.site at
    # startup and putenv()s it into the rsession process, which the assistant's
    # Node backend inherits. Only the API key is missing from that block,
    # because it is a runtime secret -- fill it in now.
    #
    # Rewriting the whole block (rather than appending) keeps it idempotent
    # across restarts and means a rotated key never lingers.
    renviron = pathlib.Path(os.environ.get("R_HOME", "/usr/lib/R")) / "etc/Renviron.site"
    begin, end = "# >>> rocker-ml posit-assistant >>>", "# <<< rocker-ml posit-assistant <<<"
    api_key = os.environ.get("OPENAI_API_KEY", "")

    # An assistant the user updated from inside RStudio lives in the persistent
    # HOME and must win; RSTUDIO_POSIT_AI_PATH would otherwise shadow it.
    system_install = pathlib.Path("/etc/rstudio/pai/bin")
    user_install = pathlib.Path.home() / ".local/share/rstudio/pai/bin"
    use_system = ((system_install / "dist/server/main.js").exists()
                  and not (user_install / "dist/server/main.js").exists())

    lines = [begin, "# Managed by install_posit_assistant.sh and the Jupyter startup hook."]
    if use_system:
        lines.append(f"RSTUDIO_POSIT_AI_PATH={system_install}")
    lines.append("OPENAI_COMPATIBLE_BASE_URL=https://ellm.nrp-nautilus.io/v1")
    if api_key:
        lines.append(f"OPENAI_COMPATIBLE_API_KEY={api_key}")
    lines.append(end)

    try:
        existing = renviron.read_text() if renviron.exists() else ""
    except Exception:
        existing = ""
    if begin in existing and end in existing:
        head, rest = existing.split(begin, 1)
        existing = head + rest.split(end, 1)[1]
    renviron.write_text(existing.rstrip("\n") + "\n\n" + "\n".join(lines) + "\n")

    # Also export into this process, so terminals and any non-rsession consumer
    # (the `pa` CLI, code-server terminals) see the same provider config.
    os.environ.setdefault("OPENAI_COMPATIBLE_BASE_URL", "https://ellm.nrp-nautilus.io/v1")
    if api_key:
        os.environ.setdefault("OPENAI_COMPATIBLE_API_KEY", api_key)

    # Model choice is not env-configurable in the shipping assistant build, so
    # seed the user's settings file on first launch (same pattern as opencode).
    # It lives in the persistent HOME, so later edits in the UI stick; delete it
    # and restart the container to go back to the defaults below.
    settings_file = pathlib.Path.home() / ".posit/assistant/settings.json"
    if not settings_file.exists():
        settings_file.parent.mkdir(parents=True, exist_ok=True)
        settings_file.write_text(json.dumps({
            "model": {
                "provider": "openai-compatible",
                "id": "qwen3"
            }
        }, indent=2))


try:
    _setup_opencode()
except Exception as e:
    logger.error(f"opencode setup failed: {e}")

try:
    _setup_kilo()
except Exception as e:
    logger.error(f"Kilo Code setup failed: {e}")

try:
    _setup_posit_assistant()
except Exception as e:
    logger.error(f"Posit Assistant setup failed: {e}")
PYEOF
