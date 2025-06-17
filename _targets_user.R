# CHANGE MANUALLY
site_id <- "CampCreek_C04"
chunk_size <- 200

# make timelapse video?
make_timelapse_video <- FALSE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2024-04-01")
date_end <- as.Date(Sys.Date()) # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "12:00:00"
time_end <- "12:10:00"

# DO NOT CHANGE MANUALLY!
# to update run: source("set_photo_dir.R")
# select a photo inside the folder of interest
user_directory <- "E:/DTSM_TIMELAPSE/CampCreek_C04/20240920"
