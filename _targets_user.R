library(fs)

# CHANGE MANUALLY -----------------------------------
chunk_size <- 200

# make timelapse video
make_timelapse_video <- TRUE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2015-10-01")
date_end <- as.Date("2016-03-01") # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "11:00:00"
time_end <- "13:10:00"

# ROI MASK TYPE IF IT EXISTS
mask_type <- "WA_01_03"

# DO NOT CHANGE MANUALLY! -----------------------------
# these are updated automatically using `source("set_photo_dir.R")`
# select a photo inside the folder of interest
user_directory <- "/Volumes/CEMAF_pheno/TIMELAPSE_CWS/TUO-CLAV/20180409"
exif_directory <- fs::path_dir(user_directory)
site_id <- "TUO-CLAV"
