# Docker Image Optimization - Implementation Summary

**Date:** January 29, 2026  
**Status:** In Progress

## Overview

Implementing cleanup optimizations and splitting images into GPU (CUDA) and CPU (ML) variants to reduce image sizes.

---

## Completed Tasks

### ✅ 1. Added Aggressive Cleanup Commands

**Files Modified:**
- [Dockerfile](Dockerfile) - Added cleanup after every major RUN command
- [extend/Dockerfile](extend/Dockerfile) - Added cleanup after mamba and R installs

**Cleanup additions:**
```dockerfile
# After each major operation:
mamba clean -afy && \
find /opt/conda -type f -name '*.pyc' -delete && \
find /opt/conda -type f -name '*.pyo' -delete && \
find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true && \
find /opt/conda/lib -name '*.a' -delete 2>/dev/null || true && \
rm -rf /tmp/* /var/tmp/* /var/lib/apt/lists/*
```

**Expected Savings:** 200-400 MB across all layers

---

### ✅ 2. Removed Duplicate Quarto Installation  

**Files Modified:**
- [install.r](install.r) - Removed `quarto` R package

**Rationale:** RStudio Server already bundles Quarto (197MB at `/usr/lib/rstudio-server/bin/quarto`), and the PATH is already configured in the Dockerfile to include it.

**Expected Savings:** ~50-100 MB

---

### ✅ 3. CPU Base Image Research

**Selected:** `condaforge/miniforge3:latest`

**Comparison:**
| Base Image | OS | Size | Mamba | Platforms |
|------------|-----|------|-------|-----------|
| rapidsai/ci-conda | Ubuntu 24.04 | 3.96 GB | ✓ | amd64, arm64 |
| **condaforge/miniforge3** | **Ubuntu 24.04** | **420 MB** | **✓** | **amd64, arm64** |
| continuumio/miniconda3 | Debian 13 | 657 MB | ✗ | amd64, arm64 |

**Key Benefits:**
- **3.5 GB smaller** base (89% reduction!)
- Same Ubuntu 24.04 Noble as GPU base
- Built-in mamba support
- Multi-platform (amd64 + arm64)
- Active maintenance by conda-forge

---

### ✅ 4. Created CPU Variant Dockerfiles

**New Files Created:**
- [Dockerfile.cpu](Dockerfile.cpu) - CPU-only ML base image
- [environment.cpu.yml](environment.cpu.yml) - CPU-specific packages (pytorch-cpu instead of pytorch + cudf)
- [extend/Dockerfile.cpu](extend/Dockerfile.cpu) - CPU-only ML-Spatial image

**Key Differences from GPU Version:**
1. Base: `condaforge/miniforge3` instead of `rapidsai/ci-conda`
2. PyTorch: `pytorch-cpu` instead of `pytorch` (much smaller)
3. Removed: `cudf` (CUDA-specific DataFrame library)
4. User handling: Adapted for miniforge3's `ubuntu` user

---

### ✅ 5. Created Backup CUDA Dockerfiles

**New Files:**
- [Dockerfile.cuda](Dockerfile.cuda) - Backup of GPU version
- [extend/Dockerfile.cuda](extend/Dockerfile.cuda) - Backup of GPU spatial version

**Current Strategy:**
- `Dockerfile` / `extend/Dockerfile` = GPU/CUDA versions (unchanged for now)
- `Dockerfile.cpu` / `extend/Dockerfile.cpu` = New CPU versions

---

### ✅ 6. Updated GitHub Workflows

**New Workflows:**
1. [.github/workflows/build-cuda.yml](.github/workflows/build-cuda.yml) - Builds GPU base
   - Tags: `rocker/cuda:latest`, `ghcr.io/rocker-org/cuda:latest`
   - Platforms: linux/amd64, linux/arm64
   
2. [.github/workflows/build-ml.yml](.github/workflows/build-ml.yml) - Builds CPU base
   - Tags: `rocker/ml:latest`, `rocker/ml:cpu`, `ghcr.io/rocker-org/ml:latest`
   - Platforms: linux/amd64, linux/arm64

3. [.github/workflows/build-cuda-spatial.yml](.github/workflows/build-cuda-spatial.yml) - Builds GPU spatial
   - Tags: `rocker/cuda-spatial:latest`, `ghcr.io/rocker-org/cuda-spatial:latest`

4. [.github/workflows/build-ml-spatial.yml](.github/workflows/build-ml-spatial.yml) - Builds CPU spatial
   - Tags: `rocker/ml-spatial:latest`, `rocker/ml-spatial:cpu`

**Image Naming Convention:**
- **GPU (CUDA):** `rocker/cuda`, `rocker/cuda-spatial`
- **CPU (ML):** `rocker/ml`, `rocker/ml-spatial`

---

## Current Status: Building & Testing

### 🔄 In Progress

Building the CPU variant locally for size comparison:
```bash
docker build -f Dockerfile.cpu -t rocker/ml:cpu-test --build-arg NB_USER=jovyan .
```

**Build Issues Resolved:**
1. ✅ User creation - Fixed miniforge3's ubuntu→jovyan rename
2. ✅ Conda permissions - Fixed conda-meta directory permissions
3. ✅ Sudo installation - Added sudo package install
4. ✅ File permissions - Added --chown for COPY commands

---

## Expected Size Comparison

### Base Images

| Image | Before | After (Estimated) | Savings |
|-------|--------|-------------------|---------|
| **rocker/ml → rocker/cuda** (GPU) | 12.9 GB | ~12.5 GB | ~400 MB |
| **rocker/ml** (new CPU) | N/A | **~8-9 GB** | **~4 GB saved** |

### Extended Images

| Image | Before | After (Estimated) | Savings |
|-------|--------|-------------------|---------|
| **rocker/ml-spatial → rocker/cuda-spatial** (GPU) | 15.3 GB | ~14.8 GB | ~500 MB |
| **rocker/ml-spatial** (new CPU) | N/A | **~10-11 GB** | **~4.5 GB saved** |

**Total Potential Savings:** ~4-5 GB for CPU users compared to current CUDA images

---

## Size Reduction Breakdown

### Per-Image Savings

**GPU Images (rocker/cuda, rocker/cuda-spatial):**
- Cleanup optimizations: ~400-500 MB
- Quarto removal: ~50 MB
- **Total:** ~450-550 MB per image

**CPU Images (new rocker/ml, rocker/ml-spatial):**
- Smaller base image: ~3.5 GB
- No CUDA libraries in pytorch: ~500-800 MB  
- Cleanup optimizations: ~400-500 MB
- Quarto removal: ~50 MB
- **Total:** ~4-5 GB compared to GPU equivalent

---

## Next Steps

### Immediate (Today)

1. ⏳ **Complete CPU base build** - Currently in progress
2. 🔲 **Test CPU base image** - Verify Jupyter, RStudio, code-server all work
3. 🔲 **Build CPU spatial image** - Build extend/Dockerfile.cpu
4. 🔲 **Size comparison** - Document actual vs estimated sizes
5. 🔲 **Functionality testing** - Run test notebooks, check R packages

### Short Term (This Week)

6. 🔲 **Update documentation** - README with image variant descriptions
7. 🔲 **Tag strategy** - Decide on :latest, :cpu, :cuda tags
8. 🔲 **Push to registries** - Test workflow builds
9. 🔲 **Announce changes** - Update users about new variants

### Future Optimizations (Not Implemented Yet)

- Make AWS CLI optional (save ~137 MB)
- Review VS Code extensions (save ~100-200 MB)
- Audit spatial packages in environment.yml (potential 1-2 GB)
- Consider multi-stage builds (if needed)

---

## Testing Checklist

Once builds complete, verify:

- [ ] Jupyter Lab starts successfully
- [ ] RStudio Server starts and renders correctly
- [ ] code-server (VS Code) starts with all extensions working
- [ ] Quarto CLI accessible from RStudio (bundled version)
- [ ] R packages load without errors
- [ ] Python packages import correctly
- [ ] Conda environment is writable by jovyan user
- [ ] File permissions are correct for jovyan/ubuntu user
- [ ] Both amd64 and arm64 builds work (after CI)

---

## Files Changed Summary

**Modified:**
- ✏️ Dockerfile - Added cleanup commands
- ✏️ extend/Dockerfile - Added cleanup commands
- ✏️ install.r - Removed quarto package

**Created:**
- ➕ Dockerfile.cpu - CPU base image
- ➕ Dockerfile.cuda - GPU backup
- ➕ environment.cpu.yml - CPU package list
- ➕ extend/Dockerfile.cpu - CPU spatial image
- ➕ extend/Dockerfile.cuda - GPU spatial backup
- ➕ .github/workflows/build-cuda.yml
- ➕ .github/workflows/build-ml.yml
- ➕ .github/workflows/build-cuda-spatial.yml
- ➕ .github/workflows/build-ml-spatial.yml
- ➕ IMAGE_SIZE_OPTIMIZATION.md - Detailed analysis
- ➕ IMPLEMENTATION_SUMMARY.md - This file

---

## Notes & Decisions

1. **Why not drop packages yet?** - Need to evaluate risk to breaking workflows. Size reduction through cleanup and CPU variant is sufficient for now.

2. **Why not multi-stage builds?** - Added complexity with diminishing returns. Cleanup commands achieve most benefits.

3. **Image naming:** 
   - `rocker/cuda` = GPU-accelerated ML (was `rocker/ml`)
   - `rocker/ml` = CPU-only ML (new)
   - Clear differentiation for users choosing based on hardware

4. **Base image choice:** `condaforge/miniforge3` is the best match - same OS, has mamba, multi-platform, actively maintained.

5. **Quarto verification:** RStudio's bundled Quarto is already on PATH via:
   ```dockerfile
   ENV PATH=$PATH:/usr/lib/rstudio-server/bin/quarto/bin
   ```

---

## Build Log Location

Current build logs:
- `/tmp/build-ml-cpu-final.log` - Latest CPU base build

---

Last Updated: January 29, 2026 09:40 UTC
