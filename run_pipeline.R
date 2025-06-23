
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
source("R/rename_photos_interactive.R")

# this DOES need to be run immediately after using the tar_make() approach to
# extract photo metadata

# specify whatever the basename is that we need to rename from, RCNX, MOLT, IMG, etc
rename_photos_safely(cam_default_img_name = "RCNX")

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
  geom_point(pch=16, color=alpha("orange",0.7), size=4) +
  labs(x="", y="Image Height (px)") +
  scale_x_datetime(date_breaks = "2 months", date_labels = "%b-%y") +
  theme_light()

# Filter photos to the time and date range specified in _targets_user.R
photo_exif_filt <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) <= hms::as_hms(time_end)) |>
 filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# note how many in full dataset vs. filt dataset:
nrow(photo_exif)
nrow(photo_exif_filt)

# specify mask type if using something different than in _targets_user
mask_type <- "WA_01_04"

# Now draw on the photo:
make_polygon_roi(photo_exif_filt, index = 8, mask_type = mask_type, user_directory, overwrite = TRUE)

# check how many pixels the mask has?
source("R/count_masked_pixels.R")

# run function
count_masked_pixels(
  photo_path = glue("{exif_directory}/{photo_exif_filt$file_folder[1]}/{photo_exif_filt$pheno_name[1]}"),
  mask_path = glue("{exif_directory}/ROI/{site_id}_{mask_type}.tif"),
  mask_type, save_plot = FALSE)


## 7. Generate Metrics ------------------------------------------------------

library(tidyverse)

# make sure to check params in targets_user
source("_targets_user.R")
source("R/load_photo_metadata.R")
source("rgb_metrics/run_rgb_parallel.R")

# site_id and photo directory loaded "latest.csv.gz"
photo_exif <- load_photo_metadata(user_directory, site_id)

# Filter photos to the time and date range specified in _targets_user.R
photo_exif_filt <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) <= hms::as_hms(time_end)) |>
  filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# note how many photos in full dataset vs. filt dataset:
nrow(photo_exif)
nrow(photo_exif_filt)

# plot to highlight:
# see what the time span looks like and if image has shifted
ggplot() +
  geom_line(data=photo_exif, aes(x=datetime, y=image_height), color="cyan4", lwd=2) +
  geom_point(data=photo_exif_filt, aes(x=datetime, y=image_height), pch=16, color=alpha("orange",0.7), size=3) +
  labs(x="", y="Image Height (px)", title="Selected Period for Extraction (orange)") +
  scale_x_datetime(date_breaks = "2 months", date_labels = "%b-%y") +
  theme_light()

# specify mask type if using something different than in _targets_user
mask_type <- "WA_01_04"

# specify the time filter for filename (timestart_timeend_datestart_dateend)
(timefilt <- glue("{strtrim(gsub(pattern = ':','',time_start), 4)}_{strtrim(gsub(pattern = ':','',time_end), 4)}_{gsub(pattern = '-','',date_start)}_{gsub(pattern = '-','',date_end)}"))

# run in parallel or not...turn the "parallel=TRUE" to FALSE if it's not working.
df <- extract_rgb_parallel(site_id, mask_type, exif_directory, photo_exif_filt, timefilt = timefilt, chunk_size = 100, parallel = TRUE)

# Plot --------------------------------------------------------------------

library(tidyverse)
library(ggimage)
library(plotly)
source("_targets_user.R")

# set parameters based on _targets_user.R
timefilt <- glue("{strtrim(gsub(pattern = ':','',time_start), 4)}_{strtrim(gsub(pattern = ':','',time_end), 4)}_{gsub(pattern = '-','',date_start)}_{gsub(pattern = '-','',date_end)}")

# manually
#timefilt <- "1100-1300"
mask_type <- "WA_01_04"

# load the data
df <- read_csv(glue("{exif_directory}/pheno_metrics_{site_id}_{mask_type}_time_{timefilt}.csv.gz"))

# try a second mask on top
photo_date_location <- max(df$datetime)-days(4)

# plot function with basic settings
ph_gg <- function(data, x_var, pheno_var, mask_type, site_id){
  ggplot() +
    geom_smooth(data=data,
                aes(x={{x_var}}, y={{pheno_var}}), method = "gam") +
    geom_point(data=data,
               aes(x={{x_var}}, y={{pheno_var}}),
               #fill=contrast),
               size=3, pch=21,
               fill="aquamarine4",
               alpha=0.6) +
    hrbrthemes::theme_ipsum_rc() +
    scale_x_datetime(date_breaks = "1 months", date_labels = "%b-%y") +
    labs(title=glue("{site_id}"),
         subtitle= glue("(Mask: {mask_type})"),
         x="") +
    geom_image(
      data = tibble(datetime = ymd_hms(glue("{photo_date_location}")), var = 0.5),
      aes(x=datetime, y=var, image = glue("{exif_directory}/ROI/{site_id}_{mask_type}_roi_masked.png")), size=0.55)
}

# to use function, specify the data, the x, and y, with no quotes:
(gg1 <- ph_gg(df, datetime, rcc, mask_type, site_id))

# interactive plotly
ggplotly(gg1)
