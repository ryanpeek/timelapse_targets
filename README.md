Code to processing timelapse imagery for landscape change analysis (phenology/seasonality/fire/flow/etc).

This is part of the California Environmental Monitoring and Assessment Project (CEMAP).

This is a pilot project to use timelapse photography to document landscape change, phenology, and seasonality by taking photos every day at a set interval of time from a stationary location. Field methods are described here. The use of timelapse photography has been shown to be a suitable approach for monitoring ecosystem change. The code in this repository is used to process imagery to rename photos, create timelapse videos, create regions of interest (draw polygons on photos), and extract and calculate RGB metrics including gcc, rcc, GRVI, excess greenness, etc from each photo based on the region of interest. 

All code within is a work in progress.

## Requires exiftools Installation

Currently the code requires a local installation of [exiftools](https://exiftool.org/). This can be done locally or for all users. Basic instructions:
 1. Download the stand-alone executable (if on Windows) (.zip) from here: https://exiftool.org/, remember where you saved to computer (i.e., Downloads/exiftool-12.87.zip)
 2. Install exiftoolr in R `install.packages("exiftoolr")`
 3. Connect your downloaded exiftools to R:
    - `library(exiftoolr)`
    - `install_exiftool(local_exiftool = "complete_path_to_zipfile/exiftool-XX.XX_vv.zip")` (i.e., "Downloads/exiftool-12.99_64.zip")
 4. Check it worked!
    - `exif_version()` # should get "Using ExifTool version XX.XX"

## Folder Structure for Timelapse Photos

Currently code is setup to run based on the following folder structure:
```
TIMELAPSE  
    --> SITE_ID  
        --> YYYYMMDD (folder with photos for given period of time ending with folder date)  
        --> YYYYMMDD (...)
```

All other files and folders will be created by the code.
