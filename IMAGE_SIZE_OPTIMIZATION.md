# Docker Image Size Optimization Analysis

**Analysis Date:** January 28, 2026  
**Images Analyzed:**
- `rocker/ml:latest` - **12.9 GB**
- `rocker/ml-spatial:latest` - **15.3 GB**

---

## Executive Summary

The rocker/ml images are quite large, with opportunities to reduce size by **2-4 GB** through targeted optimizations. The biggest opportunities are:

1. Optimizing conda/mamba package installations (potential 1-2 GB savings)
2. Removing duplicate tools and bundled software (500MB-1GB savings)
3. Implementing multi-stage builds and better cleanup (300-500MB savings)

---

## Layer-by-Layer Breakdown

### Base Image (rocker/ml) - 12.9 GB

| Component | Layer Size | Installed Size | Notes |
|-----------|-----------|----------------|-------|
| Conda packages (environment.yml) | 5.53 GB | ~3.7 GB | Includes PyTorch, cudf, DuckDB, etc. |
| RStudio Server | 1.26 GB | 353 MB | Includes bundled Quarto (197MB) |
| install_utilities.sh | 758 MB | - | AWS CLI, rclone, uv, git tools |
| code-server installation | 600 MB | 232 MB | IDE binary |
| R packages (install.r) | 616 MB | - | tidyverse, arrow, reticulate, etc. |
| R spatial packages | 290 MB | - | sf, gdalcubes, terra |
| VS Code extensions | 333 MB | 162 MB | 10 extensions installed |
| R base installation | 412 MB | - | R + r2u packages |

### Extended Image (rocker/ml-spatial) - adds 2.4 GB

| Component | Layer Size | Notes |
|-----------|-----------|-------|
| Spatial conda packages | 2.32 GB | 50+ geospatial Python packages |
| Additional R packages | 21.6 MB | sf, stars, gdalcubes, rstac, terra, mapgl |

---

## Optimization Recommendations

### 🔴 HIGH PRIORITY - Large Impact (500MB - 2GB+ savings)

#### 1. Optimize Spatial Package Installation (Potential: 1-2 GB)

**Issue:** The `extend/environment.yml` adds 2.32 GB for spatial packages, many of which have overlapping dependencies or might not all be needed.

**Actions:**
- Review if all 50+ packages in `extend/environment.yml` are essential
- Check for packages that are already indirect dependencies
- Consider splitting into a "core spatial" and "extended spatial" image
- Look for lighter alternatives to heavy packages

**Packages to review:**
```yaml
# Heavy packages to verify necessity:
- cartopy          # Large, includes many map projections
- distributed      # Dask distributed - needed?
- earthaccess      # NASA API - niche use case?
- icechunk         # New zarr format - experimental?
- jupytergis       # JupyterLab extension - needed by all?
- leafmap          # Visualization - overlaps with maplibre?
- localtileserver  # Tile server - always needed?
- streamlit        # Web framework - different use case?
```

**Implementation:**
```bash
# In extend/Dockerfile, after mamba install, add:
RUN mamba clean -afy && \
    find /opt/conda -type f -name '*.a' -delete && \
    find /opt/conda -type f -name '*.pyc' -delete && \
    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
```

#### 2. Remove Duplicate Quarto Installation (Savings: ~50-100MB)

**Issue:** `install.r` installs the R `quarto` package, but RStudio Server bundles a full Quarto installation (197MB at `/usr/lib/rstudio-server/bin/quarto`).

**Action:**
```r
# In install.r, remove 'quarto' from the list:
install.packages(c(
'archive',
'languageserver',
'httpgd',
# 'quarto',  # REMOVE - already bundled with RStudio
'tidyverse',
...
))
```

#### 3. Make AWS CLI Installation Optional (Savings: ~137MB)

**Issue:** AWS CLI adds 137MB but may not be needed by all users. Tools like `rclone` (already installed) can handle S3.

**Actions:**
- Add an `AWS_CLI=true` build arg to conditionally install AWS CLI
- Or document that users can `apt install awscli` if needed (much smaller)
- Or rely on Python's `boto3` (already in conda env)

**Implementation in install_utilities.sh:**
```bash
# Optional AWS CLI install
if [ "${INSTALL_AWS_CLI:-false}" = "true" ]; then
  curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" && \
       unzip awscliv2.zip && \
       ./aws/install && \
       rm -rf aws/ awscliv2.zip
fi
```

#### 4. Review PyTorch and CUDA Dependencies (Potential: 500MB-1GB)

**Issue:** `environment.yml` includes `pytorch` and `cudf` which are GPU-focused and very large.

**Questions to answer:**
- Is GPU support actually used by most users?
- Could this be a separate GPU-enabled variant?
- Is CPU-only PyTorch sufficient for many use cases?

**Action:** Consider splitting into:
- `rocker/ml` (CPU-only, smaller)
- `rocker/ml-gpu` (includes PyTorch GPU, cuDF)

#### 5. Implement Multi-Stage Build (Savings: 200-500MB)

**Issue:** Build tools, headers, and static libraries remain in final image.

**Action:** Use multi-stage build pattern:
```dockerfile
# Build stage
FROM rapidsai/ci-conda AS builder
# ... install and build everything ...
RUN find /opt/conda -type f -name '*.a' -delete && \
    find /opt/conda -type f -name '*.la' -delete && \
    find /opt/conda/include -type f -delete

# Final stage
FROM rapidsai/ci-conda
COPY --from=builder /opt/conda /opt/conda
COPY --from=builder /usr/lib/R /usr/lib/R
# ... copy only runtime artifacts ...
```

---

### 🟡 MEDIUM PRIORITY - Medium Impact (100-500MB savings)

#### 6. Optimize RStudio Server Installation (Savings: 100-300MB)

**Issue:** RStudio Server adds 1.26GB layer for 353MB of files.

**Actions:**
- Strip debug symbols: `find /usr/lib/rstudio-server -name "*.so" -exec strip --strip-unneeded {} \;`
- Remove unnecessary RStudio components (desktop files, docs, samples)
- Consider using RStudio Server "minimal" if available

#### 7. Review VS Code Extensions (Savings: ~100-200MB)

**Issue:** 10 extensions add 333MB layer (162MB installed).

**Current extensions:**
```
ms-python.python           # Essential
ms-toolsai.jupyter        # Essential  
ms-vscode.live-server     # Needed?
quarto.quarto            # Duplicate with RStudio's Quarto?
posit.shiny              # Essential for R users
reditorsupport.r         # Essential for R users
alefragnani.project-manager  # Nice to have?
posit.air-vscode         # Experimental?
RooVeterinaryInc.roo-cline   # Specific use case?
sst-dev.opencode         # New/experimental?
```

**Action:** Mark some extensions as "recommended" in a `.vscode/extensions.json` file instead of pre-installing.

#### 8. Aggressive Cleanup After Each Major Layer (Savings: 200-300MB)

**Issue:** Package manager metadata, temp files, and caches remain.

**Action:** Add cleanup after every major RUN command:
```dockerfile
RUN <installation commands> && \
    # Clean apt
    apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    # Clean conda/mamba
    mamba clean -afy && \
    # Remove Python bytecode
    find /opt/conda -type f \( -name '*.pyc' -o -name '*.pyo' \) -delete && \
    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true && \
    # Remove static libraries
    find /opt/conda/lib -name '*.a' -delete && \
    # Remove conda package metadata
    rm -rf /opt/conda/conda-meta/*.json.bak
```

#### 9. Review install_utilities.sh Tools (Savings: ~50-100MB)

**Tools installed:**
- `rclone` - Large, but very useful
- `git-lfs` - Niche use case
- `opencode` CLI - New tool, adoption unclear
- `uv` - Fast pip alternative, useful

**Action:** Make git-lfs and opencode optional, or install on first use.

---

### 🟢 LOW PRIORITY - Quick Wins (<100MB each)

#### 10. Remove Python Bytecode Files (Savings: ~50-80MB)

**Issue:** 20,108 .pyc files found in conda environment.

**Action:**
```dockerfile
RUN find /opt/conda -type f -name '*.pyc' -delete && \
    find /opt/conda -type d -name '__pycache__' -exec rm -rf {} + 2>/dev/null || true
```

#### 11. Remove Static Libraries (Savings: ~8.5MB)

**Issue:** Static libraries (.a files) not needed at runtime.

**Action:**
```dockerfile
RUN find /opt/conda/lib /usr/lib /usr/local/lib -name '*.a' -delete 2>/dev/null || true
```

#### 12. Remove Development Headers (Savings: ~130MB)

**Issue:** Include files in `/opt/conda/include` not needed at runtime.

**Action:**
```dockerfile
RUN rm -rf /opt/conda/include/*
```

But NOTE: This may break some R packages that compile code. Test carefully.

#### 13. Deduplicate Python Packages

**Issue:** Some packages might be in both conda and pip.

**Action:** Audit with:
```bash
docker run --rm rocker/ml:latest bash -c "conda list | grep '<pip>' | cut -d' ' -f1 | sort > /tmp/pip.txt && conda list | grep -v '<pip>' | cut -d' ' -f1 | sort > /tmp/conda.txt && comm -12 /tmp/pip.txt /tmp/conda.txt"
```

---

## Implementation Plan

### Phase 1: Quick Wins (1-2 hours, ~200-400MB savings)
1. ✅ Remove duplicate Quarto from install.r
2. ✅ Add cleanup commands to remove .pyc, .a files
3. ✅ Add aggressive cleanup after each major RUN

### Phase 2: Medium Effort (1 day, ~500MB-1GB savings)
4. ⚠️ Review and trim VS Code extensions
5. ⚠️ Make AWS CLI optional
6. ⚠️ Review and optimize install_utilities.sh

### Phase 3: Major Refactor (2-3 days, ~1-2GB savings)
7. ⚠️ Audit spatial packages in extend/environment.yml
8. ⚠️ Consider CPU vs GPU image variants
9. ⚠️ Implement multi-stage builds

### Phase 4: Advanced (1 week, varies)
10. ⚠️ Consider using distroless or scratch-based base
11. ⚠️ Implement layer caching strategies
12. ⚠️ Create image variants (minimal, standard, full)

---

## Testing Checklist

After each optimization, verify:

- [ ] Jupyter Lab starts successfully
- [ ] RStudio Server starts and renders correctly
- [ ] code-server (VS Code) starts with all extensions working
- [ ] R packages load without errors
- [ ] Python packages import correctly
- [ ] GPU features work (if applicable)
- [ ] All example notebooks run successfully
- [ ] File permissions are correct for jovyan/ubuntu user

---

## Monitoring

Track image sizes over time:

```bash
# Get current sizes
docker images rocker/ml* --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# Analyze layer sizes
docker history rocker/ml:latest --no-trunc --format "table {{.Size}}\t{{.CreatedBy}}" | head -20
```

---

## Resources

- [Docker Multi-Stage Builds](https://docs.docker.com/build/building/multi-stage/)
- [Best practices for writing Dockerfiles](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
- [Slim Docker Images](https://github.com/slimtoolkit/slim)
- [Conda Package Management Best Practices](https://docs.conda.io/projects/conda/en/latest/user-guide/tasks/manage-environments.html#removing-packages)
