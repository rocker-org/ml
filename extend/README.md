# Spatial Extensions for Rocker ML Images

This folder contains the spatial extension images (`rocker/cuda-spatial` and `rocker/ml-spatial`) which add geospatial capabilities to the base ML images.

## Images

- **`rocker/cuda-spatial`** - GPU image with CUDA + RAPIDS + geospatial packages
- **`rocker/ml-spatial`** - CPU-only image with geospatial packages

## Key Features

### GDAL

These images use the GDAL that ships with the Ubuntu base (GDAL 3.12 on Ubuntu
26.04). Everything binds that one library:

- R's `sf`/`terra` come from r2u as prebuilt binaries linked against it
- the Python packages that wrap GEOS/PROJ/GDAL (`rasterio`, `fiona`, `pyogrio`,
  `pyproj`, `shapely`) are built from source against it, rather than taking
  wheels that vendor their own copies
- `gdal-bin` provides `ogrinfo`/`ogr2ogr` against the same library

The build fails if any Python binding reports a GDAL version other than
`gdal-config --version`, so a wheel silently reintroducing a second GDAL is a
build error rather than a surprise at runtime.

### Arrow/Parquet

Ubuntu does not enable GDAL's Arrow/Parquet drivers -- `libarrow-dev` is not in
GDAL's `Build-Depends`, and no Ubuntu package ships the drivers separately.
Upstream builds them as plugins, so these images compile just those two drivers
from the matching GDAL source against the distro's libgdal and libarrow, and
install them into `gdalplugins/`.

The result is `(Geo)Parquet` and `(Geo)Arrow` read/write available everywhere
that binds GDAL -- `sf`, `terra`, `ogr2ogr`, `pyogrio`, `fiona`, `geopandas` --
including remote files over `/vsis3` and `/vsicurl`:

```r
st_write(nc, "out.parquet", driver = "Parquet")
st_read("/vsis3/bucket/data.parquet")
```

Note `sf` does not map the `.parquet` extension to a driver, so `driver =
"Parquet"` is required when writing. Reading auto-detects.

The `arrow` and `geoarrow` R packages are also installed, with S3 and GCS
support, for working with (Geo)Parquet outside GDAL.

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
 
