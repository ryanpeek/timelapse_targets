Code to processing timelapse imagery for landscape change analysis (phenology/seasonality/fire/flow/etc).

This is part of the California Environmental Monitoring and Assessment Project (CEMAP).

This is a pilot project to use timelapse photography to document landscape change, phenology, and seasonality by taking photos every day at a set interval of time from a stationary location. The use of timelapse photography has been shown to be a suitable approach for monitoring ecosystem change. The code in this repository is used to process imagery to rename photos, create timelapse videos, create regions of interest (draw polygons on photos), and extract and calculate RGB metrics including gcc, rcc, GRVI, excess greenness, etc from each photo based on the region of interest. 

All code within is a work in progress. **NOTE: This code requires local [exiftools](https://exiftool.org/) installation!**

## [**Detailed Processing Imagery Instructions**](processing_imagery.md)

## Folder Structure for Timelapse Photos

Currently code is setup to run based on the following folder structure:
```
TIMELAPSE  
    --> SITE_ID  
        --> YYYYMMDD (folder with photos for given period of time ending with folder date)  
        --> YYYYMMDD (...)
```

All other files and folders will be created by the code.
