#!/bin/bash
# set_renviron.sh
# 
# Updates R_HOME/etc/Renviron to include specified environment variables.
# Usage:
#   set_renviron.sh [VAR1 VAR2 ...]
#
# If no arguments are provided, it attempts to forward a whitelist of common variables.

set -e

# Default whitelist of variables to forward if no arguments provided
DEFAULT_VARS="
SHELL
PYTHONBUFFERED
VIRTUAL_ENV
RETICULATE_PYTHON
LD_LIBRARY_PATH
PKG_CONFIG_PATH
PATH
"

if [ "$#" -gt 0 ]; then
    VARS_TO_FORWARD="$@"
else
    VARS_TO_FORWARD="$DEFAULT_VARS"
fi

# Determine R_HOME if not set
if [ -z "$R_HOME" ]; then
    # We try to get R_HOME from R executable
    if command -v R >/dev/null 2>&1; then
        R_HOME=$(R RHOME)
    else
        echo "Error: R_HOME not set and R not found in PATH"
        exit 1
    fi
fi

RENVIRON="${R_HOME}/etc/Renviron"

# Ensure the directory exists (it should)
if [ ! -d "$(dirname "$RENVIRON")" ]; then
    mkdir -p "$(dirname "$RENVIRON")"
fi

# Loop through vars
for VAR in $VARS_TO_FORWARD; do
    # Check if variable is set in the current environment
    if [ -n "${!VAR}" ]; then
        VAL="${!VAR}"
        
        # 1. Idempotency check: if the key=value is already exactly there, skip suitable for repeated runs
        if [ -f "$RENVIRON" ] && grep -Fqx "${VAR}=${VAL}" "$RENVIRON"; then
            continue
        fi

        # 2. Clean up previous entries for this key (overwrite)
        if [ -f "$RENVIRON" ]; then
            # We use sed to delete lines starting with VAR=
            sed -i "/^${VAR}=/d" "$RENVIRON"
        fi
        
        # 3. Append new value
        echo "${VAR}=${VAL}" >> "$RENVIRON"
        echo "Added ${VAR} to ${RENVIRON}"
    fi
done
