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
