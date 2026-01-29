#!/bin/bash
# Clean up conda environment to reduce image size
mamba clean -afy
find /opt/conda -type f -name '*.pyc' -delete
find /opt/conda -type f -name '*.pyo' -delete
find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
find /opt/conda/lib -name '*.a' -delete 2>/dev/null || true
rm -rf /tmp/* 2>/dev/null || true
