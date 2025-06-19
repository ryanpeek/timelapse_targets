library(fs)

# CHANGE MANUALLY -----------------------------------
chunk_size <- 200

# make timelapse video
make_timelapse_video <- FALSE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2016-12-01")
date_end <- as.Date("2017-03-01") # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "12:00:00"
time_end <- "12:10:00"

# ROI MASK TYPE IF IT EXISTS
mask_type <- "GR_01_01"

# DO NOT CHANGE MANUALLY! -----------------------------
# these are updated automatically using `source("set_photo_dir.R")`
# select a photo inside the folder of interest
user_directory <- "E:/TIMELAPSE_CWS/TUO-CLAV/20180409"
exif_directory <- fs::path_dir(user_directory)
site_id <- "TUO-CLAV"
