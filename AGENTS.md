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

### sudo, secure_path and Ubuntu 26.04's sudo-rs
`sudo` resolves commands with `secure_path` from `/etc/sudoers`, not the caller's PATH,
and Ubuntu's default does not include `${VIRTUAL_ENV}/bin`. Left alone, `sudo pip install`
silently installs into the **system** python instead of `/opt/venv`, and `sudo jupyter`
is not found. Fixed by `sudoers-venv`, installed as `/etc/sudoers.d/zz-venv`.

Ubuntu 26.04 also makes **sudo-rs** the default `/usr/bin/sudo` (GNU sudo remains at
`/usr/bin/sudo.ws`). sudo-rs does **not** implement `--preserve-env` -- it warns and
ignores it -- so do not rely on that flag to carry the environment across a privilege
drop. Use `Defaults env_keep`, which sudo-rs does honour.

The `zz-` prefix is deliberate: `sudoers.d` is read in lexical order and later `Defaults`
win, so anything setting `secure_path` must sort last.

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

## Posit Assistant Configuration

RStudio 2026.04.0+ ships the AI pane, but not the assistant itself: on first use RStudio
downloads a Node bundle from `cdn.posit.co` into `~/.local/share/rstudio/pai/bin`. That is
a per-user, network-dependent step, so `install_posit_assistant.sh` bakes the bundle in at
build time instead. Version and checksum are resolved from
`https://cdn.posit.co/posit-ai/manifest.json` (keyed by wire-protocol version; we take the
highest, matching the current stable RStudio) — nothing is pinned.

Install location is `/etc/rstudio/pai/bin`, the system-wide path RStudio searches
(`ChatInstallation.cpp`, `locatePositAssistantInstallation`):

1. `$RSTUDIO_POSIT_AI_PATH`
2. `~/.local/share/rstudio/pai/bin`
3. `/etc/rstudio/pai/bin`  ← we use this

Deliberately *not* `RSTUDIO_POSIT_AI_PATH`: that would shadow (2), so a user who lets
RStudio update the assistant would keep getting the image-baked copy. With (3), an updated
copy in the persistent HOME wins.

Runtime config comes from `_setup_posit_assistant()` in the Jupyter startup hook. The
assistant reads `OPENAI_COMPATIBLE_BASE_URL` / `OPENAI_COMPATIBLE_API_KEY` for its
"OpenAI Compatible" provider, and env vars outrank both `~/.posit/ai/providers.json` and
the settings UI. `rserver` is spawned by jupyter-rsession-proxy as a child of the Jupyter
server, so exporting them in the hook is enough.

Model choice is *not* env-configurable in the shipping build (the documented
`POSIT_ASSISTANT_SETTINGS_DEFAULT` / `_ENFORCED` variables are not in the 1.1.0 bundle —
only `POSIT_AI_PROVIDERS_DEFAULT` / `_ENFORCED` for `providers.json`). So the hook seeds
`~/.posit/assistant/settings.json` on first launch, opencode-style: HOME-resident, user
edits persist, delete and restart to re-seed.

The relevant RStudio prefs (`assistant`, `chat_provider`) already default to `posit`, so no
`/etc/rstudio/rstudio-prefs.json` entry is needed. `RSTUDIO_DISABLE_POSIT_ASSISTANT` is the
off switch if one is ever wanted.

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

## Testing a change before merging

The release workflows (`build-ml.yml`, `build-cuda.yml`) only run on push to `master`, and
their `merge` job writes `:latest` — so they are not a pre-merge gate. `build-pr.yml` fills
that gap: on a pull request touching the Dockerfiles or `install*.sh` it builds amd64-only
images and pushes them to GHCR as `ghcr.io/rocker-org/{ml,cuda}:pr-<number>`, then runs
`smoke-test.sh` against the result. The job summary prints the `docker pull` / `docker run`
lines for hand-testing.

`smoke-test.sh` also runs locally against any tag (`bash smoke-test.sh rocker-ml:local`,
pairing with `run.sh`). It asserts R/Python/Jupyter/RStudio/quarto/opencode are present and
that the Jupyter startup hook actually seeds the opencode, Roo and Posit Assistant config
when executed with an `OPENAI_API_KEY` in the environment. It does **not** cover anything
GPU (no GPU runners) or anything that needs a browser — the IDE panes still need a human.

Fork PRs are skipped: `GITHUB_TOKEN` is read-only for them, so the push would 403. PR tags
are not garbage-collected; prune them from the org's package settings occasionally.
