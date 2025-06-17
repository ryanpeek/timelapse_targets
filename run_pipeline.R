
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

## 4b. IF YOU HAVE >1000 photos, you can try to run things in parallel. This helps
# speed things up. This should work on any computer.
# With future (multisession/local multicore)
#library(future)
#plan(multisession)
#tar_make_future()

# rerun to check status and see if it worked?
tar_visnetwork(targets_only = TRUE)

## 5. Rename Photos ----------------------------------------------------------

# now rename photos...this script does this interactively and will log what happened
source("rename_photos_interactive.R")
rename_photos_safely(photo_metadata = tar_read(photo_metadata))

## 6. Create ROI --------------------------------------------------------------

library(tidyverse)
library(fs)
library(glue)
source("_targets_user.R")
source("R/create_polygon_roi.R")

# site_id and photo directory loaded from _targets_user
photo_exif <- load_photo_metadata(user_directory, site_id)

# see what the time span looks like and if image has shifted
ggplot(data=photo_exif, aes(x=datetime, y=image_height)) +
  geom_line(color="gray") +
  geom_point(pch=16, color=alpha("orange",0.7), size=4)+
  scale_x_datetime(date_breaks = "2 months", date_labels = "%b-%y") +
  theme_minimal()

# Filter to only Noon photos:
photo_exif_noon <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) < hms::as_hms(time_end))

# if you want a specific date range:
# photo_exif_noon <- photo_exif_noon |>
#  filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# Now draw on the photo?
make_polygon_roi(photo_exif_noon, index = 3, mask_type = "SH_01_01", user_directory)


