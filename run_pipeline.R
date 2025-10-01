# Timelapse Imagery Processing Pipeline -------------------------------
## Updated: 2025-07-24
## Author: R. Peek

# this pipeline helps process timelapse camera imagery from raw game cameras.
# to run, first we need to load/install packages. The automated workflow will:
# - ask for photo directory
# - extract metadata from imagery
# - merge metadata with pre-existing imagery data if it exists
# - generate a timelapse video if TRUE in user_parameters

# The manual pipeline then starts from there:
# - rename photos
# - create regions of interest (ROI)
# - generate metrics
# - plot & explore metrics

## 0. Check exiftools is installed ---------------------

## this process only needs to be done ONCE per R installation (version)

## 1. Download the ExifTool Windows Executable (stand-alone) version (.zip) from here:

## https://exiftool.org/, look for Windows Executable: exiftool-xx.xx.zip
## Download to default downloads folder (i.e., Downloads/exiftool-12.87.zip)

## 2. create path to the downloaded tool:

## make sure the version number matches what you have Downloaded
# path_to_exif_zip <- r'(C:\Users\USERNAME\Downloads\exiftool-12.99_64.zip)'

## 3. Check path works!

# if(fs::file_exists(path_to_exif_zip)=="TRUE") {
#   print("Path is legit!")
# } else( "Path is borked...double check")

## 4. Now install

## Install package:
# install.packages("exiftoolr")
# library(exiftoolr)
## this only needs to be done once!
# install_exiftool(local_exiftool = path_to_exif_zip)

## Check EXIF works:
# exif_version()
# should get "Using ExifTool version XX.XX" and the version


# A: AUTOMATED PIPELINE --------------------------------------------------------

# check for packages and load
# note, this may take a minute or two the first time
source("R/packages.R")

## 1. Set Photo Directory/Site ID -----------------------------------------

# setup directory of photos:
# navigate to folder and select ANY image in the folder
# you plan to process imagery
source("set_photo_dir.R")

## 2. Check Date-Time Parameters and Timelapse Video ------------------------------

# Open the "user_parameters.R" file:
## verify the site ID and folders look correct
## make any changes to date ranges and time window you want to process
## change the timelapse video flag to TRUE / FALSE

# if we make any changes, we need to reload them here:
source("user_parameters.R")

## 3. Visualize & Run Pipeline ---------------------------------------------

# this will show a visual of the pipeline. Helpful to see/identify issues.

# visualize
tar_visnetwork(targets_only = TRUE) # all things should be blue

# Run the pipeline (uses the "_targets.R" file by default)
tar_make() # extracts metadata, merges metadata with preexisting metadata, and saves out.

### To Force Rename Photos:
# We need to delete the pheno_exif output files for the specific date (pheno_exif_SITE_ID_YYYYMMDD.csv.gz and pheno_exif_SITE_ID_latest.csv.gz)
# Then rename a single photo in the folder of interest with "RCNX" at the start.
# Then we need to delete the metadata associated with our pipeline with tar_destroy()
# it's ok! we can rerun and regenerate everything. Select "yes" (1) and hit enter.
# rerun tar_make() and it will regenerate everything!

# rerun to check status and see if it worked?
tar_visnetwork(targets_only = TRUE)
# all things should be green if success
# if failure, it will stop at that step and be red

# B: INTERACTIVE PIPELINE ------------------------------

## 1. Create Region of Interest (ROI) -------------------------------------------------------------

# now draw a region of interest on your photo for metric extraction
source("user_parameters.R")
source("R/packages.R")
source("R/create_polygon_roi.R")

# site_id and photo directory loaded from user_parameters
photo_exif <- load_photo_metadata(user_directory, site_id)

# see what the time span looks like and if image has shifted
# expect line to be horizontal an largely unbroken
ggplot(data=photo_exif, aes(x=datetime, y=image_height)) +
  geom_line(color="gray") +
  geom_point(pch=16, color=alpha("orange",0.7), size=4) +
  labs(x="", y="Image Height (px)") +
  scale_x_datetime(date_breaks = "2 month", date_labels = "%b-%y") +
  theme_light()

# Filter photos to the time and date range specified in user_parameters.R
# this helps reduce processing. You can always extract for
# every photo if you want by using the full "photo_exif"
photo_exif_filt <- photo_exif |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) <= hms::as_hms(time_end)) |>
 filter(as_date(datetime)>=date_start & as_date(datetime)<= date_end)

# note how many in full dataset vs. filt dataset:
nrow(photo_exif)
nrow(photo_exif_filt)

# specify mask type if using something different than in user_parameters
mask_type
# if photo field of view and frame is identical to previous set,
# and adding new ROI of same type, use _01_02
# if field of focus/view has shifted, use _02_01

# change if you want something new/different
#mask_type <- "WA_01_01"

# Now draw on the photo. If you want a different photo date, change the "index=" value. Make sure to hit escape to save.
make_polygon_roi(photo_exif_filt, index = 25, mask_type = mask_type, user_directory, overwrite = TRUE)

## IMPORTANT NOTE: RSTUDIO HAS A GLITCH THAT CAUSES ORTHOGONAL SHIFT IN
## DRAWN POLYGON. TO AVOID TRY ONE OF FOLLOWING:
# - use View > Actual Size
# - On Windows: use a X11 window: x11() then run function above
# - On macosx: use a quartz window: quartz() then run function above


# should return a pixel count. If you need to abort and restart, just hit escape, and rerun the make_polygon_roi() function.

# check how many pixels the mask has?
source("R/f_count_masked_pixels.R")

# this will count the total pixels in the mask, and provide a gridded plot
# of the ROI to get a sense of density of pixels.
# use save_plot = TRUE to save this out if you prefer.
count_masked_pixels(
  photo_path = glue("{exif_directory}/{photo_exif_filt$file_folder[1]}/{photo_exif_filt$pheno_name[1]}"),
  mask_path = glue("{exif_directory}/ROI/{site_id}_{mask_type}.tif"),
  mask_type, save_plot = FALSE)


## 2. Generate Metrics ------------------------------------------------------

# can start pipeline here too:
source("R/packages.R")

# make sure to check parameters in user_parameters
source("user_parameters.R")
source("R/f_load_photo_metadata.R")
source("R/run_rgb_parallel.R")

# site_id and photo directory loaded "latest.csv.gz"
photo_exif <- load_photo_metadata(user_directory, site_id)

# Filter photos to the time and date range specified in user_parameters.R
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

# specify ROI type if using something different than in user_parameters
mask_type
#mask_type <- "WA_01_01"

# specify the time filter for filename (timestart_timeend_datestart_dateend)
(timefilt <- glue("{strtrim(gsub(pattern = ':','',time_start), 4)}_{strtrim(gsub(pattern = ':','',time_end), 4)}_{gsub(pattern = '-','',date_start)}_{gsub(pattern = '-','',date_end)}"))

# run in parallel or not...turn the "parallel=TRUE" to FALSE if it's not working.
# chunk size can vary but ~100 is best
df <- extract_rgb_parallel(site_id, mask_type, exif_directory, photo_exif_filt, timefilt = timefilt, chunk_size = 150, parallel = FALSE)

## 3. Plot ---------------------------------------------------------------

# can also start here with pipeline

source("R/packages.R")
source("user_parameters.R")

# set parameters based on user_parameters.R
timefilt <- glue("{strtrim(gsub(pattern = ':','',time_start), 4)}_{strtrim(gsub(pattern = ':','',time_end), 4)}_{gsub(pattern = '-','',date_start)}_{gsub(pattern = '-','',date_end)}")

# check ROI mask type you are using from user_parameters
mask_type

# manually
#mask_type <- "WA_01_01"

# load the data
df <- read_csv(glue("{exif_directory}/pheno_metrics_{site_id}_{mask_type}_time_{timefilt}.csv.gz"))

# where image will be on top, change days if long time series
photo_date_location <- max(df$datetime)-days(20)

# plot function with basic settings
ph_gg <- function(data, x_var, pheno_var, mask_type, site_id, img_var_y){
  ggplot() +
    geom_smooth(data=data,
                aes(x={{x_var}}, y={{pheno_var}}), method = "gam") +
    geom_point(data=data,
               aes(x={{x_var}}, y={{pheno_var}}),
               #fill=contrast),
               size=3, pch=21,
               fill="aquamarine4",
               alpha=0.6) +
    cowplot::theme_half_open() + cowplot::background_grid(major=c("xy"))+
    #hrbrthemes::theme_ipsum_rc() +
    theme(axis.text.x = element_text(angle = -90, vjust = 0.5, hjust = 1)) +
    #scale_y_continuous(limits=c(0.32, 0.45))+
    scale_x_datetime(date_breaks = "2 month", date_labels = "%m-%d-%y") +
    labs(title=glue("{site_id}"),
         subtitle= glue("(Mask: {mask_type})"),
         x="") +
    geom_image(
      data = tibble(datetime = ymd_hms(glue("{photo_date_location}")), var = img_var_y),
      aes(x=datetime, y=var, image = glue("{exif_directory}/ROI/{site_id}_{mask_type}_roi_masked.png")), size=0.5)
}

# to use function, specify the data, the x, and y, with no quotes:

# Variable options: gcc, rcc, GRVI, exG, grR, rbR, gbR, bcc, rcc.std

(gg1 <- ph_gg(df, datetime, exG, mask_type, site_id, 20))

# save out:
varname <- "exG"
fs::dir_create(glue("{exif_directory}/figs"))
ggsave(glue("{exif_directory}/figs/{varname}_{site_id}_{mask_type}_midday.png"), width = 11, height = 8.5, dpi = 300, bg = "white")

# interactive plotly
#ggplotly(gg1)

# find earliest (lowest val):
df |>
  mutate(yr = year(datetime), mon = month(datetime), wk = week(datetime)) |>
  slice_min(GRVI, by=c(yr), n=2) |> # top 2 results
  select(datetime, yr, wk, GRVI, gcc, exG, gbR, rcc) |>
  View()

# find latest (highest)
df |>
  mutate(yr = year(datetime), mon = month(datetime), wk = week(datetime)) |>
  slice_max(bcc, by=c(yr), prop=.02) |> # top 2%
  select(datetime, yr, wk, GRVI, gcc, exG, gbR, rcc) |>
  View()

