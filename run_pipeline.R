
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
# specify whatever the basename is that we need to rename from
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

# Filter to only Noon photos:
photo_exif_noon <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) < hms::as_hms(time_end))

# if you want a specific date range:
photo_exif_noon <- photo_exif_noon |>
 filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# Now draw on the photo?
make_polygon_roi(photo_exif_noon, index = 200, mask_type = "GR_01_01", user_directory, overwrite = TRUE)

## 7. Generate Metrics ------------------------------------------------------

library(tidyverse)
library(glue)

source("_targets_user.R")
source("R/load_photo_metadata.R")
source("rgb_metrics/run_rgb_vectorized.R")
source("rgb_metrics/run_rgb_parallel.R")
#source("rgb_metrics/extract_rgb_metrics.R")

# site_id and photo directory loaded "latest.csv.gz"
photo_exif <- load_photo_metadata(user_directory, site_id)

# filter to time period of interest
photo_exif_noon <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) &
      hms::as_hms(datetime) < hms::as_hms(time_end))

# for date range use this:
photo_exif_noon <- photo_exif_noon |>
  filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# run standard vectorized
system.time(
  df <- extract_rgb_vect(site_id, mask_type, exif_directory, photo_exif_noon, timefilt = "1200"))

# run in parallel
system.time(
  df <- extract_rgb_parallel(site_id, mask_type, exif_directory, photo_exif_noon, timefilt = "1200", chunk_size = 100, parallel = TRUE))


# tst
timefilt <- "1200"
df <- read_csv(glue("{exif_directory}/pheno_metrics_{site_id}_{mask_type}_time_{timefilt}.csv.gz"))

# Plot --------------------------------------------------------------------

library(tidyverse)
library(ggimage)

# ambient light filter
filt_ambient_light <- 8000
filt_contrast <- 150
df_f <- df |>
  filter(#ambient_light >= filt_ambient_light &
           contrast > filt_contrast)
photo_date_location <- max(df_f$datetime)-days(40)

library(plotly)

#ggplotly(
ggplot() +
  geom_smooth(data=df_f,
              aes(x=datetime, y=GRVI), method = "gam") +
  geom_point(data=df_f,
             aes(x=datetime, y=GRVI),
             #fill=contrast),
             size=3, pch=21,
             fill="aquamarine4",
             alpha=0.6) +
  hrbrthemes::theme_ipsum_rc() +
  scale_fill_viridis_c(option = "D", direction = -1) +
  scale_x_datetime(date_breaks = "1 months", date_labels = "%b-%y") +
  labs(title=glue("{site_id}"),
       subtitle= glue("(Mask: {mask_type})"),
       x="",
       caption=glue("Data filters: \nambient light > {filt_ambient_light}\ncontrast > {filt_contrast}")) +
  geom_image(
    data = tibble(datetime = ymd_hms(glue("{photo_date_location}")), gcc = .4),
    aes(x=datetime, y=gcc, image = glue("{exif_directory}/ROI/{site_id}_{mask_type}_roi_masked.png")), size=0.5)
#)

