#!/bin/bash
# Smoke-test a built image. Checks that the pieces the Dockerfiles install are
# actually present and wired up -- not a substitute for opening the IDEs by
# hand, but enough to catch a silently broken layer.
#
# Usage: bash smoke-test.sh [IMAGE]     (default: rocker-ml:local, as built by run.sh)

set -uo pipefail

IMAGE="${1:-rocker-ml:local}"
echo "Smoke-testing ${IMAGE}"

fail=0

# One-liner check: runs in a login shell inside the image.
check() {
    local name="$1"; shift
    if docker run --rm --user jovyan -e OPENAI_API_KEY=smoke-test-key "$IMAGE" \
            bash -lc "$*" >/tmp/smoke.out 2>&1; then
        echo "ok    ${name}"
    else
        echo "FAIL  ${name}"
        sed 's/^/      | /' /tmp/smoke.out
        fail=1
    fi
}

# Script check: reads the script from stdin, so it can contain any quoting.
check_script() {
    local name="$1"
    if docker run --rm -i --user jovyan -e OPENAI_API_KEY=smoke-test-key "$IMAGE" \
            bash -s >/tmp/smoke.out 2>&1; then
        echo "ok    ${name}"
    else
        echo "FAIL  ${name}"
        sed 's/^/      | /' /tmp/smoke.out
        fail=1
    fi
}

check "R runs"                  "R --version"
check "python venv is default"  "test \"\$(command -v python3)\" = /opt/venv/bin/python3"
check "jupyter runs"            "jupyter --version"
check "RStudio server installed" "test -x /usr/lib/rstudio-server/bin/rserver"
check "quarto on PATH"          "command -v quarto"
check "opencode installed"      "command -v opencode"
check "code-server extensions"  "ls /opt/share/code-server | grep -qi kilocode"

# Posit Assistant: RStudio only treats the directory as an install when all
# three of these exist (ChatInstallation.cpp verifyPositAiInstallation).
check "posit assistant bundle" "
    test -f /etc/rstudio/pai/bin/dist/server/main.js &&
    test -f /etc/rstudio/pai/bin/dist/client/index.html &&
    test -f /etc/rstudio/pai/bin/package.json"
check "posit assistant readable by user" "head -c1 /etc/rstudio/pai/bin/dist/server/main.js >/dev/null"

# The bundle being on disk is not enough, and neither is exporting variables
# from the Jupyter server: rserver hands rsession a curated ~27-variable
# environment and drops everything else. R's Renviron.site is what actually
# gets through. Run the startup hook, then read the variables back from an R
# process started with a DELIBERATELY EMPTY environment -- if they show up
# there, they came from Renviron.site, which is exactly how rsession and the
# assistant's Node backend will get them.
check_script "assistant config reaches an rsession-like environment" <<'SCRIPT'
set -e
python3 -c 'import runpy; runpy.run_path("/etc/jupyter/jupyter_server_config.py")'

# Mimic what rserver gives a session: none of the Jupyter environment, plus the
# temp RSTUDIO_CONFIG_DIR the rsession-proxy sets (which breaks the /etc lookup).
env -i HOME="$HOME" PATH=/usr/local/bin:/usr/bin:/bin LANG=C \
    RSTUDIO_CONFIG_DIR="$(mktemp -d)" \
    R -q -s -e 'cat(Sys.getenv("RSTUDIO_POSIT_AI_PATH"), Sys.getenv("OPENAI_COMPATIBLE_API_KEY"), Sys.getenv("OPENAI_COMPATIBLE_BASE_URL"), Sys.getenv("RSTUDIO_CONFIG_DIR"), sep="\n")' \
    > /tmp/rsession-env

python3 - <<'PY'
import pathlib
path, key, url, cfgdir = pathlib.Path('/tmp/rsession-env').read_text().splitlines()

def valid(p):
    p = pathlib.Path(p)
    return (p / 'dist/server/main.js').exists() and (p / 'dist/client/index.html').exists()

# RStudio's search order (ChatInstallation.cpp locatePositAssistantInstallation).
candidates = [c for c in (
    path,
    str(pathlib.Path.home() / '.local/share/rstudio/pai/bin'),
    f'{cfgdir}/pai/bin' if cfgdir else '/etc/rstudio/pai/bin',
) if c]

found = next((c for c in candidates if valid(c)), None)
assert found, f'RStudio would find no assistant install; searched {candidates}'
assert key == 'smoke-test-key', f'provider API key did not reach the session: {key!r}'
assert url.startswith('https://'), f'provider base URL did not reach the session: {url!r}'
print(f'resolves to {found}, credentials present')
PY
SCRIPT

# The hook is also responsible for the per-user config files.
check_script "startup hook seeds per-user AI config" <<'SCRIPT'
set -e
python3 - <<'PY'
import json, pathlib, runpy
runpy.run_path('/etc/jupyter/jupyter_server_config.py')
home = pathlib.Path.home()
assert (home / '.config/opencode/opencode.json').exists(), 'opencode config not seeded'
s = json.loads((home / '.posit/assistant/settings.json').read_text())
assert s['model']['provider'] == 'openai-compatible', s

# Kilo's config dir must resolve into the persistent HOME, not $XDG_CONFIG_HOME,
# or every custom model a user adds is lost on restart.
import os
link = pathlib.Path(os.environ.get('XDG_CONFIG_HOME', str(home / '.config'))) / 'kilo'
target = home / '.config/kilo'
assert link.resolve() == target.resolve(), f'{link} -> {link.resolve()}, expected {target}'
k = json.loads((target / 'kilo.json').read_text())
assert 'nrp' in k['provider'], k
PY
SCRIPT

# A user-added model must survive the hook re-running on the next container start.
check_script "kilo config survives a restart" <<'SCRIPT'
set -e
python3 - <<'PY'
import json, pathlib, runpy
runpy.run_path('/etc/jupyter/jupyter_server_config.py')
cfg = pathlib.Path.home() / '.config/kilo/kilo.json'
data = json.loads(cfg.read_text())
data['provider']['nrp']['models']['smoke-test-model'] = {'name': 'Smoke Test'}
cfg.write_text(json.dumps(data, indent=2))
runpy.run_path('/etc/jupyter/jupyter_server_config.py')
data = json.loads(cfg.read_text())
assert 'smoke-test-model' in data['provider']['nrp']['models'], 'user edit was clobbered'
PY
SCRIPT

# Running the hook twice must not duplicate the managed Renviron block.
check_script "startup hook is idempotent" <<'SCRIPT'
set -e
for _ in 1 2 3; do
    python3 -c 'import runpy; runpy.run_path("/etc/jupyter/jupyter_server_config.py")'
done
n=$(grep -c '>>> rocker-ml posit-assistant >>>' /usr/lib/R/etc/Renviron.site)
test "$n" -eq 1 || { echo "managed block appears $n times"; exit 1; }
SCRIPT

if [ "$fail" -ne 0 ]; then
    echo "smoke test FAILED"
    exit 1
fi
echo "smoke test passed"
