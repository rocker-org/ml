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

**Goose** fully respects `XDG_CONFIG_HOME`. Its config (including custom providers)
lives at `/opt/share/xdg-config/goose/`. Sessions and logs still go to
`~/.local/share/goose/` and `~/.local/state/goose/` (persistent volume — correct behavior).

## Goose Configuration

The NRP custom provider is defined at build time in `install_llms.sh` and stored at:
```
/opt/share/xdg-config/goose/custom_providers/nrp.json
```

At runtime, pass these env vars (e.g. via JupyterHub's `environment` config or `run.sh` locally):

```
OPENAI_API_KEY=<key>
GOOSE_PROVIDER=nrp
GOOSE_MODEL=minimax-m2
```

The NRP provider JSON already encodes the endpoint (`https://ellm.nrp-nautilus.io/v1`)
and model (`minimax-m2`), so `GOOSE_PROVIDER=nrp` is sufficient for provider selection.
