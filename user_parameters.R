library(fs)

# CHANGE MANUALLY -----------------------------------
chunk_size <- 250

# make timelapse video
make_timelapse_video <- TRUE # or change to FALSE

# Date filter for videos:
date_start <- as.Date("2024-04-01")
date_end <- as.Date("2025-10-06") # or as "YYYY-MM-DD"

# Time filter for videos, 24HR format
time_start <- "12:00:00"
time_end <- "12:15:00"

# ROI MASK TYPE IF IT EXISTS
mask_type <- "DB_01_01"

## OPTIONS:
## FROM Richardson et al
# https://www.nature.com/articles/sdata201828
# AG agriculture
# DB deciduous broadleaf
# DN deciduous needleleaf
# EB evergreen broadleaf
# EN evergreen needleleaf
# GR grassland
# MX mixed vegetation (generally EN/DN, DB/EN, or DB/EB)
# SH shrubs
# TN tundra (includes sedges, lichens, mosses, etc.)
# WT wetland
# WA water
# SN snow

# DO NOT CHANGE MANUALLY! -----------------------------
# these are updated automatically using `source("set_photo_dir.R")`
# select a photo inside the folder of interest
user_directory <- "/Volumes/CEMAF_pheno/TIMELAPSE_ST/STV1/20241016"
exif_directory <- fs::path_dir(user_directory)
site_id <- "STV1"
