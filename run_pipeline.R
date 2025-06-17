
# Load and run the pipeline
library(targets)

# RUNNING PIPELINE --------------------------------------------------------

## 1. Set Photo Directory --------------------------------------------------

# setup directory of photos:
source("set_photo_dir.R")
# make sure to find the window that pops open, navigate to folder and select image

## 2. Set Site ID ----------------------------------------------------------

# Open the "_targets_user.R" file and add/revise the SITE_ID to match dir names

## 3. Test and Visualize Pipeline ------------------------------------------

# this will test if things are going to function and show a visual
# of the pipeline. Not required but helpful to see/identify issues.

# visualize
tar_visnetwork(targets_only = TRUE)

## 4. Run Extract Photo Pipeline ---------------------------------------------

# Run the pipeline
tar_make() # this defaults to _targets.R
# this extracts metadata, merges metadata with preexisting metadata, and saves out.

## 4b. IF YOU HAVE >1000 photos, can try to run things in parallel. This helps
# speed things up. This should work on any computer.
# With future (multisession/local multicore)
library(future)
plan(multisession)
tar_make_future()

## 5. Rename Photos ----------------------------------------------------------

# now rename photos...this script does this interactively and will log what happened
source("rename_photos_interactive.R")
rename_photos_safely(photo_metadata = tar_read(photo_metadata))

## 6. Make a Video Manually -----------------------------------------------------------

# use video utils and _targets_user.R


## 7. Plot Photo Timespan ----------------------------------------

# get most recent merged dataset
tar_load(merged_metadata)
library(tidyverse)
merged_metadata <- read_csv("F:/TIMELAPSE/R5_dtsm/CSVER_C10/pheno_exif_CSVER_C10_latest.csv.gz")

#plot duration
ggplot() + geom_point(data=merged_metadata, aes(x=datetime, y=site_id), pch=16, alpha=0.6)

