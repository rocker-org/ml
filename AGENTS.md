# Agent / AI Coding Guidelines

## JupyterHub Deployment Constraints

These images are deployed on Kubernetes via JupyterHub. That imposes hard constraints:

### $HOME is a mounted volume
JupyterHub bind-mounts a persistent volume over `$HOME` (`/home/jovyan`) at container start.
**Any files written into `/home/jovyan` during the Docker build are silently overwritten at runtime.**
Do not rely on anything in `/home/jovyan` being present at runtime.

### CMD and ENTRYPOINT are owned by JupyterHub
JupyterHub sets its own runtime command (`jupyterhub-singleuser ...`).
**Do not override CMD or ENTRYPOINT** in the Dockerfiles for deployment logic.
A simple `CMD ["jupyter", "lab", ...]` is acceptable as a local-testing fallback and is ignored by JupyterHub.

### No startup/init scripts via CMD
Do not use CMD to run setup scripts that copy configs or seed state at container start.
JupyterHub overrides CMD, so such scripts will never run in production.

## Persistent Storage Pattern

All persistent, image-baked configuration must live outside `$HOME`.
We use `/opt/share/` as the base for such files:

| Path | Purpose |
|---|---|
| `/opt/share/code-server/` | VS Code (code-server) extensions — set via `$CODE_EXTENSIONSDIR` |
| `/opt/share/xdg-config/` | XDG config for apps that respect `$XDG_CONFIG_HOME` |

### XDG_CONFIG_HOME
`ENV XDG_CONFIG_HOME=/opt/share/xdg-config` is set in both Dockerfiles.
Apps that follow the XDG Base Directory spec will read/write config here instead of
`~/.config`, keeping their config outside the JupyterHub volume mount.

**opencode** respects `XDG_CONFIG_HOME`, but `/opt/share/xdg-config/` is image-baked
and not on the persistent HOME volume — so user edits there would not survive a
container restart. Instead, the image ships a sysadmin **template** at
`/opt/share/xdg-config/opencode/opencode.json`, and `OPENCODE_CONFIG` (set in
`/etc/profile.d/opencode.sh` and in the jupyter server env) redirects opencode to
`$HOME/.config/opencode/opencode.json`. The Jupyter server startup hook seeds the
user copy from the template on first launch. Users edit freely and changes persist;
delete the user copy and restart to re-seed from the current template. The API key
is never stored in the image — `{env:OPENAI_API_KEY}` syntax makes opencode read it
from the environment at runtime.

## opencode Configuration

opencode reads `$HOME/.config/opencode/opencode.json` (via `OPENCODE_CONFIG`), seeded
on first launch from the image template at `/opt/share/xdg-config/opencode/opencode.json`.
Two providers are enabled out of the box:

- **NRP**: OpenAI-compatible endpoint, default model `qwen3`. Requires `OPENAI_API_KEY`
  injected at runtime. The `{env:OPENAI_API_KEY}` syntax means the key is never stored in
  the image.
- **GitHub Copilot**: Built-in provider. Users authenticate once via `/connect` in opencode
  (device flow at `github.com/login/device`). The token is stored in
  `~/.local/share/opencode/auth.json` (HOME persistent volume) and survives container
  restarts. Alternatively, inject `GITHUB_TOKEN` via JupyterHub to skip interactive auth.

## Roo Cline Configuration

Roo Cline stores its API provider config in VS Code **secret storage**, which falls back to
in-memory on Linux (no libsecret). This means secrets reset on every code-server restart.

To work around this, `/etc/jupyter/jupyter_server_config.py` is installed at build time.
This hook runs when the Jupyter server starts (before the user accesses code-server) and:

1. Reads `OPENAI_API_KEY` from the environment
2. Writes a Roo settings import file to `/tmp/roo-cline/nrp-settings.json`
3. Sets `roo-cline.autoImportSettingsPath` in `~/.local/share/code-server/User/settings.json`

Roo re-reads `autoImportSettingsPath` on every extension activation and re-imports the NRP
provider config (including API key) automatically each session.

`/etc/jupyter/` is in Jupyter's config search path and is outside `$HOME`, so it persists
across JupyterHub volume mounts. The generated `/tmp/roo-cline/nrp-settings.json` lives only
for the duration of the container session (correct: it gets regenerated each time with the
current `OPENAI_API_KEY`).

The `~/.local/share/code-server/User/settings.json` entry persists in the user's home
volume once written, so new users get it on first Jupyter start and it stays for subsequent
sessions.
