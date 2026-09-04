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

## The venv must be built with `--copies`

`/opt/venv` is created with `python3 -m venv --copies`. **Do not drop `--copies`.**

A default venv symlinks `bin/python -> bin/python3 -> /usr/bin/pythonX.Y`, so its
`realpath` is the *system* interpreter. The VS Code Python extension's PATH locator
canonicalises every candidate and dedupes by resolved path, so the venv resolves to
the same file as `/usr/bin/python3` and is silently discarded. The symptom is that
`/opt/venv` never appears in the interpreter picker or the notebook kernel picker --
only `/bin/python3` and `/usr/bin/python3` -- even though `/opt/venv/bin` is first on
`PATH` and `$VIRTUAL_ENV` points at it. The extension log shows the collapse:

```
Found: /opt/venv/bin/python --> /usr/bin/python3.14   # seen, then deduped away
> /bin/python3      ... interpreterInfo.py            # only these two survive
> /usr/bin/python3  ... interpreterInfo.py
```

Being on `PATH` is the one way of being found that does *not* survive this, because
the PATH locator is the only one that dedupes. The venv locators (which key off
`pyvenv.cfg` and would preserve its identity) never see `/opt/venv`, since it is in
none of the directories they scan (`~/.virtualenvs`, `$WORKON_HOME`, `python.venvPath`,
or the workspace).

`--copies` gives the venv its own real interpreter binary, so its `realpath` stays
inside `/opt/venv` and it keeps a distinct identity. Cost is ~20MB.

A `python.venvPath` setting also works around this, but it would have to be seeded
into each user's `settings.json` at runtime (it cannot be baked into `$HOME`);
`--copies` fixes it at the source and needs no settings at all.

### Open VSX ships the pet-less build of ms-python

Related, and worth knowing before debugging this area: `code-server --install-extension
ms-python.python` resolves against **Open VSX**, which only ever serves the `universal`
VSIX. That build omits the `pet` native locator binary (`python-env-tools/bin/pet`) that
Microsoft bundles in the per-platform VSIXs. `ms-python.vscode-python-envs` -- pulled in
automatically as an `extensionPack` member -- shells out to `pet` for all discovery, so
it fails with `ENOENT` and reports zero environments, leaving its "Python Environments"
UI offering only *Create Environment*.

This is mostly cosmetic today: `python.useEnvironmentsExtension` defaults to `false`, so
`ms-python.python`'s own legacy locator (which needs no `pet`) is authoritative, and that
is also what `ms-toolsai.jupyter` consumes for notebook kernels. The `pet` binary is not
separately distributed -- `microsoft/python-environment-tools` publishes no release
assets -- so the only source is the Microsoft marketplace, whose terms target VS Code
proper. Hence: not vendored here.

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

**opencode and Kilo Code** respect `XDG_CONFIG_HOME`, but `/opt/share/xdg-config/` is
image-baked and not on the persistent HOME volume — so config they write there would
not survive a restart. Both directories are therefore symlinks into `~/.config`; see
[AI assistant configuration](#ai-assistant-configuration).

## opencode

Installed as both a CLI (`/usr/local/bin/opencode`) and a VS Code extension, with no
provider configured — see [AI assistant configuration](#ai-assistant-configuration).
Users run `opencode auth login` (or `/connect` in the TUI) and pick a provider; the
credentials land in `~/.local/share/opencode/auth.json` and the config in
`~/.config/opencode/opencode.json`, both on the persistent HOME volume, so both
survive a restart. GitHub Copilot works this way for anyone with a subscription
(device flow at `github.com/login/device`).

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

(3) alone is **not** enough under JupyterHub, and neither is any environment variable
exported by the Jupyter server. Two separate obstacles:

1. `jupyter-rsession-proxy` sets `RSTUDIO_CONFIG_DIR` to a fresh `tempfile.mkdtemp()` for
   every `rserver` it spawns. That variable short-circuits the whole XDG lookup, so
   `systemConfigDir()` becomes the temp dir and RStudio searches `<tmpdir>/pai/bin`.
   (Same code path as the `session-rpc-key` removal in `install_rstudio.sh`.)
2. `rserver` does **not** pass its environment to `rsession`. It builds a curated ~27-var
   environment (`RS_*`, `RSTUDIO_*`, `R_*`, plus `HOME`, `PATH`, `USER`, `LOGNAME`, `LANG`,
   `SHELL`, `LD_LIBRARY_PATH`, `XDG_CONFIG_HOME`) and drops everything else — verified on a
   live pod: 92 vars in `rserver`, 27 in `rsession`. `/etc/rstudio/env-vars` does not help
   either; `rserver` only `setenv()`s that into its own process.

So the config goes through **R's `Renviron.site`**, which is the one channel that reaches a
session: R `putenv()`s it into the `rsession` process at startup, and `SessionChat` launches
the assistant's Node backend with `core::system::environment()` — the full process env — so
the backend inherits it too. (RStudio's own source cites `~/.Renviron` as how proxy vars
reach that backend.) This is the same reason `set_renviron.sh` exists in this repo.

`install_posit_assistant.sh` writes a delimited managed block into `$(R RHOME)/etc/Renviron.site`
with `RSTUDIO_POSIT_AI_PATH`, and chowns the file to `$NB_USER`. The startup hook rewrites that
block each start, which keeps it idempotent. The hook drops `RSTUDIO_POSIT_AI_PATH` from the
block when the user has their own copy in `~/.local/share/rstudio/pai/bin`, so an in-IDE update
still wins.

No provider is configured. The assistant would read `OPENAI_COMPATIBLE_BASE_URL` /
`OPENAI_COMPATIBLE_API_KEY` for its "OpenAI Compatible" provider, and env vars outrank both
`~/.posit/ai/providers.json` and the settings UI — which is exactly why neither is set:
setting them would override whatever the user picks in the UI. Users configure a provider
there instead, and `~/.posit/assistant/settings.json` is HOME-resident so the choice sticks.

Note model choice is *not* env-configurable in the shipping build (the documented
`POSIT_ASSISTANT_SETTINGS_DEFAULT` / `_ENFORCED` variables are not in the 1.1.0 bundle —
only `POSIT_AI_PROVIDERS_DEFAULT` / `_ENFORCED` for `providers.json`).

The relevant RStudio prefs (`assistant`, `chat_provider`) already default to `posit`, so no
`/etc/rstudio/rstudio-prefs.json` entry is needed. `RSTUDIO_DISABLE_POSIT_ASSISTANT` is the
off switch if one is ever wanted.

## AI assistant configuration

The image pre-installs three assistants -- opencode (CLI + extension), Kilo Code
(VS Code extension) and Posit Assistant (the RStudio AI pane) -- and configures
**none** of them. No provider, no model, no endpoint, no API key. Users set up
whichever they want from the app's own UI, and the image's job is to make that
choice survive a container restart.

This is deliberate: an earlier version pre-seeded the NRP Nautilus endpoint and
read `OPENAI_API_KEY` from the environment. Deployments now hand users their own
keys interactively, so nothing here should depend on a hub-provided secret.

### Why config needed redirecting at all

opencode and Kilo Code both read their global config from `$XDG_CONFIG_HOME/<app>`,
and this image points `XDG_CONFIG_HOME` at `/opt/share/xdg-config` so that
image-baked config is not shadowed by the JupyterHub HOME mount. That directory
lives in the image, so anything the apps *write* there is discarded on restart --
which is precisely a user's provider, model, agents and MCP servers. Kilo v7 is an
opencode fork and keeps the whole of `kilo.json` there.

`install_llms.sh` replaces both with symlinks into the persistent HOME:

    /opt/share/xdg-config/opencode -> /home/jovyan/.config/opencode
    /opt/share/xdg-config/kilo     -> /home/jovyan/.config/kilo

so each app reads and writes `~/.config/<app>` without knowing anything about it.
`kilo debug paths` still prints the `/opt/share` path; it resolves into HOME.

Everything else was already HOME-resident and needed no work: `opencode auth
login` writes to `~/.local/share/opencode`, Kilo's `data`/`state`/`cache` dirs are
`~/.local/share/kilo`, `~/.local/state/kilo` and `~/.cache/kilo`, and Posit
Assistant's settings are in `~/.posit/assistant/settings.json`.

### The startup hook

`/etc/jupyter/jupyter_server_config.py` runs when the Jupyter server starts,
before anyone reaches code-server. `/etc/jupyter/` is in Jupyter's config search
path and outside `$HOME`, so it survives the volume mount. It does two things:

1. Re-asserts both symlinks -- repairing a container whose `/opt/share` predates
   this change, and moving anything already written to the ephemeral location
   into HOME first rather than dropping it.
2. Writes `RSTUDIO_POSIT_AI_PATH` into R's `Renviron.site`, so RStudio finds the
   baked-in assistant bundle instead of prompting each user to download it.

`Renviron.site` is the only channel that reaches `rsession`: rserver hands it a
curated ~27-variable environment and drops everything else, so nothing exported
by the Jupyter server arrives. The managed block is rewritten rather than
appended, which keeps it idempotent. It carries the install path and nothing
else.

A user-installed assistant under `~/.local/share/rstudio/pai/bin` wins over the
system one, since `RSTUDIO_POSIT_AI_PATH` would otherwise shadow it.

## Testing a change before merging

The release workflows (`build-ml.yml`, `build-cuda.yml`) only run on push to `master`, and
their `merge` job writes `:latest` — so they are not a pre-merge gate. `build-pr.yml` fills
that gap: on a pull request touching the Dockerfiles or `install*.sh` it builds amd64-only
images and pushes them to GHCR as `ghcr.io/rocker-org/{ml,cuda}:pr-<number>`, then runs
`smoke-test.sh` against the result. The job summary prints the `docker pull` / `docker run`
lines for hand-testing.

`smoke-test.sh` also runs locally against any tag (`bash smoke-test.sh rocker-ml:local`,
pairing with `run.sh`). It asserts R/Python/Jupyter/RStudio/quarto/opencode are present and
that the Jupyter startup hook keeps the assistant config dirs on the persistent HOME,
ships nothing pre-configured, and needs no API key. It does **not** cover anything
GPU (no GPU runners) or anything that needs a browser — the IDE panes still need a human.

Fork PRs are skipped: `GITHUB_TOKEN` is read-only for them, so the push would 403. PR tags
are not garbage-collected; prune them from the org's package settings occasionally.
