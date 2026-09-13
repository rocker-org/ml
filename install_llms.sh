#!/bin/bash

# Fail the build at the point of failure. Without this, a transient download
# failure in the opencode installer (a truncated tarball, an error page from the
# CDN) leaves the RUN layer green and silently ships an image with no opencode.
set -eo pipefail

# opencode cli.
#
# The upstream installer hardcodes $HOME/.opencode/bin, which is wiped the
# moment JupyterHub mounts a PVC over $HOME -- and is not on anyone's PATH
# besides. Move the binary to /usr/local/bin, which is image-resident, already
# on the default PATH for every shell (login or not, jovyan or root) and needs
# no PATH edits, profile.d drop-in or shell rc to be found.
#
# The installer leaves the binary owned by the UID that built the release
# tarball (1001), so chown it like any other system binary.
curl -fsSL https://opencode.ai/install | bash
mv "${HOME}/.opencode/bin/opencode" /usr/local/bin/opencode
chown root:root /usr/local/bin/opencode
chmod 0755 /usr/local/bin/opencode
rm -rf "${HOME}/.opencode"

# Config for the AI assistants.
#
# Neither opencode nor Kilo Code is pre-configured with a provider, a model or a
# key: users pick their own from each app's own UI. The job here is only to make
# sure that choice is still there after a restart -- and that is now the default
# behaviour, because both apps write their global config to
# $XDG_CONFIG_HOME/<app> and this image no longer redirects XDG_CONFIG_HOME.
# So config lands in ~/.config/opencode and ~/.config/kilo, on the persistent
# HOME volume, with nothing to symlink or repair at startup.
#
# The redirect (XDG_CONFIG_HOME=/opt/share/xdg-config) existed to keep the old
# pre-seeded goose config out of the JupyterHub HOME mount. Nothing is pre-seeded
# any more, so it bought nothing and cost correctness: /opt/share is image-baked,
# so anything the apps wrote there was discarded on restart, and the symlinks
# used to work around that dangled in any container whose ~/.config did not
# already exist -- `opencode` then died at startup with
# `EEXIST: file already exists, mkdir /opt/share/xdg-config/opencode`, because
# mkdir() on a dangling symlink reports EEXIST. A plain `docker run rocker/ml`
# hit that on every invocation.
#
# Credentials were already safe and stay where they were: `opencode auth login`
# writes ~/.local/share/opencode, and Kilo's data/state/cache dirs are
# HOME-resident too.

# Jupyter server startup hook.
# /etc/jupyter/ is in Jupyter's config search path (outside $HOME, survives JupyterHub mounts).
# This script runs when the Jupyter server starts — before users access code-server.
# Its only job is pointing RStudio at the baked-in Posit Assistant; opencode and
# Kilo Code need nothing here now that their config is plain ~/.config. It
# configures no provider and reads no API key.
mkdir -p /etc/jupyter
cat > /etc/jupyter/jupyter_server_config.py <<'PYEOF'
"""Jupyter server startup hook: point RStudio at the baked-in Posit Assistant."""
import os, json, pathlib, logging
logger = logging.getLogger(__name__)

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
    # HOME, and a *newer* one there must win; RSTUDIO_POSIT_AI_PATH would
    # otherwise shadow it. But HOME outlives the image: a bundle RStudio
    # downloaded there under an older release keeps winning over every
    # subsequent rebuild, which is how a fresh image ends up serving a stale
    # assistant. So compare versions rather than merely checking existence, and
    # only stand aside when the user's copy is genuinely ahead.
    system_install = pathlib.Path("/etc/rstudio/pai/bin")
    user_install = pathlib.Path.home() / ".local/share/rstudio/pai/bin"

    def _version(install):
        if not (install / "dist/server/main.js").exists():
            return None
        try:
            v = json.loads((install / "package.json").read_text())["version"]
        except Exception:
            return ()
        # "1.3.0" -> (1, 3, 0); anything unparseable sorts below every real
        # version, so a readable version always beats an unreadable one.
        try:
            return tuple(int(n) for n in v.split("."))
        except ValueError:
            return ()

    system_version, user_version = _version(system_install), _version(user_install)
    use_system = system_version is not None and (
        user_version is None or user_version <= system_version)

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
    _setup_posit_assistant()
except Exception as e:
    logger.error(f"Posit Assistant setup failed: {e}")
PYEOF
