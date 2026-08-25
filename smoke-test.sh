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
