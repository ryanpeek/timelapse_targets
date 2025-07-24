library(fs)

# CHANGE MANUALLY -----------------------------------
chunk_size <- 250

# make timelapse video
make_timelapse_video <- TRUE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2024-04-01")
date_end <- as.Date("2025-08-01") # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "11:00:00"
time_end <- "13:00:00"

# ROI MASK TYPE IF IT EXISTS
mask_type <- "WA_01_01"

# DO NOT CHANGE MANUALLY! -----------------------------
# these are updated automatically using `source("set_photo_dir.R")`
# select a photo inside the folder of interest
user_directory <- "D:/TIMELAPSE_CRGP/BLRO-R2/20250602"
exif_directory <- fs::path_dir(user_directory)
site_id <- "BLRO-R2"
