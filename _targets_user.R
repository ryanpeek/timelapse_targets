library(fs)

# CHANGE MANUALLY -----------------------------------
chunk_size <- 200

# make timelapse video
make_timelapse_video <- TRUE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2016-12-01")
date_end <- as.Date("2017-03-01") # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "10:00:00"
time_end <- "13:10:00"

# ROI MASK TYPE IF IT EXISTS
mask_type <- "WA_01_02"

# DO NOT CHANGE MANUALLY! -----------------------------
# these are updated automatically using `source("set_photo_dir.R")`
# select a photo inside the folder of interest
user_directory <- "E:/TIMELAPSE_CWS/TUO-CLAV/20180329"
exif_directory <- fs::path_dir(user_directory)
site_id <- "TUO-CLAV"
