
# Load and run the pipeline
library(targets)

# RUNNING PIPELINE --------------------------------------------------------

## 1. Set Photo Directory --------------------------------------------------

# setup directory of photos:
source("set_photo_dir.R")
# navigate to folder and select image

## 2. Set Site ID ----------------------------------------------------------

# Open the "_targets_user.R" file and add/revise the SITE_ID to match dir names

## 3. Test and Visualize Pipeline ------------------------------------------

# this will show a visual of the pipeline. Helpful to see/identify issues.

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


## 6. Plot Photo Timespan ----------------------------------------

# get most recent merged dataset
library(tidyverse)
library(fs)
library(glue)
source("_targets_user.R")

merged_metadata <- read_csv(glue("{fs::path_dir(user_directory)}/pheno_exif_{site_id}_latest.csv.gz"))

#plot duration
ggplot() + geom_col(data=merged_metadata, aes(x=datetime, y=image_height), fill="orange", alpha=0.6)+ theme_minimal()+
  scale_x_datetime(date_breaks = "2 months", date_labels = "%b-%y")

