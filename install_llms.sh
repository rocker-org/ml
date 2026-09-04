#!/bin/bash

# Fail the build at the point of failure. Without this, a transient download
# failure in the opencode installer (a truncated tarball, an error page from the
# CDN) leaves the RUN layer green and silently ships an image with no opencode.
set -eo pipefail

# opencode cli - installer hardcodes $HOME/.opencode/bin, so move to /usr/local/bin
curl -fsSL https://opencode.ai/install | bash && \
  mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode && \
  rm -rf "${HOME}/.opencode"

# Config persistence for the AI assistants.
#
# Neither opencode nor Kilo Code is pre-configured with a provider, a model or a
# key: users pick their own from each app's own UI. The job here is only to make
# sure that choice is still there after a restart.
#
# Both read their global config from $XDG_CONFIG_HOME/<app>, and this image
# points XDG_CONFIG_HOME at /opt/share/xdg-config so that image-baked config is
# not shadowed by the JupyterHub HOME mount. That directory is image-resident,
# though, so anything the apps *write* there -- providers, models, agents, MCP
# servers, and for Kilo the whole of kilo.json -- is discarded when the container
# restarts. Symlink both into the persistent HOME so they are not.
#
# Credentials are already safe: `opencode auth login` writes to
# ~/.local/share/opencode, and Kilo's data/state/cache dirs are HOME-resident
# too. Only config needed redirecting.
for app in opencode kilo; do
    rm -rf "${XDG_CONFIG_HOME}/${app}"
    ln -s "/home/${NB_USER:-jovyan}/.config/${app}" "${XDG_CONFIG_HOME}/${app}"
    chown -h ${NB_USER:-jovyan}:users "${XDG_CONFIG_HOME}/${app}"
done

# Jupyter server startup hook.
# /etc/jupyter/ is in Jupyter's config search path (outside $HOME, survives JupyterHub mounts).
# This script runs when the Jupyter server starts — before users access code-server.
# It re-asserts the config symlinks above and points RStudio at the baked-in
# Posit Assistant. It configures no provider and reads no API key.
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_server_config.py <<'PYEOF'
"""Jupyter server startup hook: keep per-user AI assistant config on the persistent HOME."""
import os, pathlib, logging, shutil
logger = logging.getLogger(__name__)

def _persist_config_dirs():
    # opencode and Kilo Code both keep their global config under
    # $XDG_CONFIG_HOME/<app>, which this image points outside $HOME so that
    # image-baked config is not shadowed by the JupyterHub volume mount -- with
    # the side effect that anything the apps write there is thrown away on
    # restart. The build replaces both with symlinks into ~/.config; re-assert
    # them here so a container whose /opt/share predates that change, or in
    # which something recreated a real directory, still ends up persistent.
    #
    # Nothing is seeded into either: no provider, no model, no key. Users
    # configure the assistants interactively and this is what makes it stick.
    xdg = pathlib.Path(os.environ.get("XDG_CONFIG_HOME", str(pathlib.Path.home() / ".config")))
    for app in ("opencode", "kilo"):
        link = xdg / app
        target = pathlib.Path.home() / ".config" / app
        target.mkdir(parents=True, exist_ok=True)
        if link.resolve() == target.resolve():
            continue
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

def _setup_posit_assistant():
    # Posit Assistant (the AI pane in RStudio) is baked into the image by
    # install_posit_assistant.sh, which also writes a managed block into R's
    # Renviron.site with the install path. Point RStudio at it, and nothing else
    # -- no provider, no base URL, no key. Users choose a provider in the
    # assistant's own settings UI; ~/.posit/assistant/settings.json is on the
    # persistent HOME, so that choice survives a restart.
    #
    # Why Renviron.site and not the environment: rserver hands rsession a
    # curated ~27-variable environment and drops everything else, so nothing
    # exported here ever reaches the RStudio session. R reads Renviron.site at
    # startup and putenv()s it into the rsession process, which the assistant's
    # Node backend inherits.
    #
    # Rewriting the whole block (rather than appending) keeps it idempotent
    # across restarts.
    renviron = pathlib.Path(os.environ.get("R_HOME", "/usr/lib/R")) / "etc/Renviron.site"
    begin, end = "# >>> rocker-ml posit-assistant >>>", "# <<< rocker-ml posit-assistant <<<"

    # An assistant the user updated from inside RStudio lives in the persistent
    # HOME and must win; RSTUDIO_POSIT_AI_PATH would otherwise shadow it.
    system_install = pathlib.Path("/etc/rstudio/pai/bin")
    user_install = pathlib.Path.home() / ".local/share/rstudio/pai/bin"
    use_system = ((system_install / "dist/server/main.js").exists()
                  and not (user_install / "dist/server/main.js").exists())

    lines = [begin, "# Managed by install_posit_assistant.sh and the Jupyter startup hook."]
    if use_system:
        lines.append(f"RSTUDIO_POSIT_AI_PATH={system_install}")
    lines.append(end)

    try:
        existing = renviron.read_text() if renviron.exists() else ""
    except Exception:
        existing = ""
    if begin in existing and end in existing:
        head, rest = existing.split(begin, 1)
        existing = head + rest.split(end, 1)[1]
    renviron.write_text(existing.rstrip("\n") + "\n\n" + "\n".join(lines) + "\n")


try:
    _persist_config_dirs()
except Exception as e:
    logger.error(f"AI assistant config persistence failed: {e}")

try:
    _setup_posit_assistant()
except Exception as e:
    logger.error(f"Posit Assistant setup failed: {e}")
PYEOF
