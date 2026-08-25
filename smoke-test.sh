#!/bin/bash
# Smoke-test a built image. Checks that the pieces the Dockerfiles install are
# actually present and wired up -- not a substitute for opening the IDEs by
# hand, but enough to catch a silently broken layer.
#
# Usage: bash smoke-test.sh [IMAGE]     (default: rocker-ml:local, as built by run.sh)

set -euo pipefail

IMAGE="${1:-rocker-ml:local}"
echo "Smoke-testing ${IMAGE}"

run() {
    docker run --rm --user jovyan -e OPENAI_API_KEY=smoke-test-key "$IMAGE" bash -lc "$1"
}

fail=0
check() {
    local name="$1"; shift
    if run "$*" >/tmp/smoke.out 2>&1; then
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

# The bundle being on disk is not enough: RStudio has to resolve it. Emulate
# locatePositAssistantInstallation() under the environment jupyter-rsession-proxy
# actually gives rserver -- it sets RSTUDIO_CONFIG_DIR to a fresh mkdtemp(),
# which short-circuits the /etc/rstudio lookup. This is the check that would
# have caught the assistant silently not being found on JupyterHub.
check "posit assistant resolves under rsession-proxy env" "
    export RSTUDIO_CONFIG_DIR=\\$(mktemp -d)
    python3 - <<'EOF'
import os, pathlib, runpy, sys
runpy.run_path('/etc/jupyter/jupyter_server_config.py')

def valid(p):
    p = pathlib.Path(p)
    return ((p / 'dist/server/main.js').exists()
            and (p / 'dist/client/index.html').exists())

# RStudio's search order, in order.
candidates = []
if os.environ.get('RSTUDIO_POSIT_AI_PATH'):
    candidates.append(os.environ['RSTUDIO_POSIT_AI_PATH'])
candidates.append(str(pathlib.Path.home() / '.local/share/rstudio/pai/bin'))
# systemConfigDir(): RSTUDIO_CONFIG_DIR short-circuits it, else XDG_CONFIG_DIRS, else /etc.
sysdir = os.environ.get('RSTUDIO_CONFIG_DIR')
candidates.append(f'{sysdir}/pai/bin' if sysdir else '/etc/rstudio/pai/bin')

found = next((c for c in candidates if valid(c)), None)
assert found, f'RStudio would find no assistant install; searched {candidates}'
print('resolves to', found, file=sys.stderr)
EOF"

# Execute the Jupyter startup hook the way the server would, then assert it
# produced the per-user config and the provider environment.
check "startup hook configures AI tools" "
    python3 - <<'EOF'
import os, json, pathlib, runpy, sys
runpy.run_path('/etc/jupyter/jupyter_server_config.py')
home = pathlib.Path.home()
assert (home / '.config/opencode/opencode.json').exists(), 'opencode config not seeded'
s = json.loads((home / '.posit/assistant/settings.json').read_text())
assert s['model']['provider'] == 'openai-compatible', s
assert os.environ['OPENAI_COMPATIBLE_API_KEY'] == 'smoke-test-key'
assert os.environ['OPENAI_COMPATIBLE_BASE_URL'].startswith('https://'), os.environ['OPENAI_COMPATIBLE_BASE_URL']
assert json.loads(pathlib.Path('/tmp/roo-cline/nrp-settings.json').read_text())
EOF"

if [ "$fail" -ne 0 ]; then
    echo "smoke test FAILED"
    exit 1
fi
echo "smoke test passed"
