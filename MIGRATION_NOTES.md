# Migration to pip-based Python with CUDA 13

## Summary of Changes

This migration replaces the conda-based setup with a pip-based Python environment to support CUDA 13 and the latest RAPIDS AI libraries.

## Key Changes

### Base Image
- **Before**: `rapidsai/ci-conda` (conda-based, CUDA 12)
- **After**: `nvidia/cuda:13.0.0-devel-ubuntu24.04` (pip-based, CUDA 13)
  - Uses `devel` flavor as required by RAPIDS for NVRTC/Numba support

### Python Environment
- **Before**: Conda environment at `/opt/conda`
- **After**: System-wide pip virtual environment at `/opt/venv`
  - Python 3.12 (default in Ubuntu 24.04)
  - User-writable with group permissions
  - Activated by default via `PATH` environment variable

### Package Management
- **Before**: `environment.yml` with mamba/conda packages
- **After**: `requirements.txt` with pip packages
  - RAPIDS packages use `-cu13` wheels from NVIDIA Python Package Index
  - PyTorch uses CUDA 13.0 wheels from PyTorch index

### Package Versions
All packages now use RAPIDS 25.12 stable release with CUDA 13 support:
- cudf-cu13
- cuml-cu13
- cugraph-cu13
- cuxfilter-cu13
- cucim-cu13
- raft-dask-cu13
- cuvs-cu13
- nx-cugraph-cu13

PyTorch now uses CUDA 13.0 wheels.

## Benefits

1. **CUDA 13 Support**: Latest CUDA toolkit with improved performance and features
2. **Faster Installation**: pip wheels install faster than conda packages
3. **Reduced Image Size**: No conda overhead
4. **Better NVIDIA Integration**: Direct use of NVIDIA's official CUDA base images
5. **Up-to-date Packages**: RAPIDS 25.12 with latest features

## Installation Notes

The RAPIDS pip packages are installed from the NVIDIA Python Package Index:
```
--extra-index-url=https://pypi.nvidia.com
```

PyTorch packages use the PyTorch CUDA 13.0 index:
```
--extra-index-url=https://download.pytorch.org/whl/cu130
```

## Compatibility

- **CUDA Version**: 13.0
- **Python Version**: 3.12
- **Ubuntu Version**: 24.04
- **NVIDIA Driver**: 580.65.06 or newer required

## References

- RAPIDS Installation Guide: https://docs.rapids.ai/install
- RAPIDS pip documentation: https://docs.rapids.ai/install/#pip
- NVIDIA CUDA Images: https://hub.docker.com/r/nvidia/cuda
