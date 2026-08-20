# Spatial Extensions for Rocker ML Images

This folder contains the spatial extension images (`rocker/cuda-spatial` and `rocker/ml-spatial`) which add geospatial capabilities to the base ML images.

## Images

- **`rocker/cuda-spatial`** - GPU image with CUDA + RAPIDS + geospatial packages
- **`rocker/ml-spatial`** - CPU-only image with geospatial packages

## Key Features

### GDAL

These images use the GDAL that ships with the Ubuntu base (GDAL 3.12 on Ubuntu
26.04). R's `sf`/`terra` come from r2u as prebuilt binaries linked against that
same system library, so there is a single, consistent GDAL throughout.

Ubuntu does not enable GDAL's Arrow/Parquet drivers, so `.parquet` is not
readable through `ogr2ogr`/`st_read()`. For GeoParquet use the `arrow` and
`geoarrow` R packages, or `geopandas`/`pyarrow` in Python.

Note that the Python geospatial wheels (`rasterio`, `fiona`, `pyogrio`) each
vendor their own copy of GDAL and do not use the system library.

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
 
