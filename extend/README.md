# Spatial Extensions for Rocker ML Images

This folder contains the spatial extension images (`rocker/cuda-spatial` and `rocker/ml-spatial`) which add geospatial capabilities to the base ML images.

## Images

- **`rocker/cuda-spatial`** - GPU image with CUDA + RAPIDS + geospatial packages
- **`rocker/ml-spatial`** - CPU-only image with geospatial packages

## Key Features

### GDAL with Arrow/Parquet Support

These images use a **multi-stage build** to include GDAL 3.10 with full Arrow/Parquet/GeoParquet support:

- **GeoParquet** - Read/write GeoParquet files directly with GDAL
- **Arrow** - Apache Arrow integration for high-performance data exchange
- **Parquet** - Native Parquet format support in GDAL

The GDAL libraries are copied from the official `ghcr.io/osgeo/gdal:ubuntu-full` image, which is built with all drivers enabled including Arrow/Parquet support that Ubuntu's default GDAL package lacks.

### Included Packages

**R packages** (via `install.r`):
- `sf`, `terra`, `stars` - Spatial data handling
- `gdalcubes` - Earth observation data cubes
- `rstac` - SpatioTemporal Asset Catalog client
- `mapgl` - MapLibre GL visualization

**Python packages** (via `requirements.txt`):
- `geopandas`, `rasterio`, `fiona`, `pyogrio` - Core geospatial
- `xarray`, `rioxarray`, `odc-geo` - N-dimensional arrays
- `pystac`, `planetary-computer`, `earthaccess` - Data access
- `leafmap`, `maplibre`, `pydeck` - Visualization
- `dask`, `distributed` - Parallel computing

## Customizing

Edit `install.r` to add R packages and `requirements.txt` / `requirements-cpu.txt` for Python packages. Building the Dockerfile automatically resolves system dependencies via BSPM for R packages.

## Building

```bash
# GPU version (extends rocker/cuda)
docker build -f Dockerfile.cuda -t my-spatial-gpu .

# CPU version (extends rocker/ml)  
docker build -f Dockerfile.cpu -t my-spatial-cpu .
```

## Environment Variables

- `GDAL_DATA=/usr/local/share/gdal` - GDAL data files location
- `PROJ_DATA=/usr/local/share/proj` - PROJ datum grids location
- `CPL_VSIL_USE_TEMP_FILE_FOR_RANDOM_WRITE=YES` - Cloud-optimized GeoTIFF support
 
