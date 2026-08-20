# Copy photos only within a certain time range
# useful for storing photos or subset for uploading to WI
# constrain to just 10-2 or 12pm photos

library(exiftoolr)
library(dplyr)
library(lubridate)
library(fs)

# Parameters --------------------------------------------------------------

source("set_photo_dir.R") # pick photo from folder we want to copy photos over from
#source("user_parameters.R")
date_start <- as.Date("2025-08-20")
date_end <- as.Date("2026-08-13") # or as "YYYY-MM-DD"
tz        <- "America/Los_Angeles"
time_start  <- '12:00:00'
time_end    <- '12:10:00'

# select the directory we want to save TO
out_dir <- "F:/TIMELAPSE_CRGP"

# extract a few pieces
exif_directory <- fs::path_dir(selected_dir)

# set site_id if using external drive and named site folders
(site_id <- fs::path_file(path_dir(selected_dir)))

# set site_id manually if reading directly from SD card
site_id <- "SALM13A"

# directory to save the photos into (i.e., "midday")
subset_dir_name <- "midday"

# Create out directory if it doesn't exist
fs::dir_create(glue("{out_dir}/{site_id}/{subset_dir_name}"))


# List Files --------------------------------------------------------------

files <- fs::dir_ls(selected_dir, recurse = TRUE, type="file")

# check number of photos in folder with this number?
length(files)

# Read in Files that Meet Filter Params -----------------------------------

# this can take a while
df <- exiftoolr::exif_read(
  files,
  tags = c("FileName", "Directory", "DateTimeOriginal")) |>
  mutate(
    full_path = file.path(Directory, FileName),
    datetime  = lubridate::ymd_hms(DateTimeOriginal, tz = tz)
  )

# set paths for photos we want to copy
df_keep <- df |>
  filter(
    format(datetime, "%H:%M:%S") >= time_start,
    format(datetime, "%H:%M:%S") <= time_end
  )

# build paths for files to copy
keep_paths <- df_keep$full_path

# Validation: double check with additional filter and add renaming option:
df_keep <- df_keep  |>
  mutate(
    within_window = format(datetime, "%H:%M:%S") >= time_start & format(datetime, "%H:%M:%S") <= time_end
  ) |>
  mutate(
    photo_ymdhms = glue("{format(as_date(datetime), '%Y_%m_%d')}_{gsub(':', '', hms::as_hms(datetime))}"),
    pheno_name = glue("{site_id}_{photo_ymdhms}.{path_ext(FileName)}"),
    dest_dir = glue("{out_dir}/{site_id}/{subset_dir_name}/{pheno_name}"))

# validation warning check
validation_issues <- df_keep |>
  filter(!within_window)

if (nrow(validation_issues) > 0) {
  warning("Some kept files fall OUTSIDE the expected time window!")
  print(validation_issues)
  stop("Aborting due to validation failure.")
}

# Check and Inspect -------------------------------------------------------

cat("Total photos:", length(files), "\n")
cat("Photos kept:", length(keep_paths), "\n")
fs::dir_exists(glue("{out_dir}/{site_id}/{subset_dir_name}"))

# Copy Files ------------------------------------------------------------

message(glue("Copying {nrow(df_keep)} photos into {out_dir}/{site_id}/{subset_dir_name}/..."))
fs::file_copy(path = df_keep$SourceFile, new_path = df_keep$dest_dir, overwrite = TRUE)
message(glue("Done!"))


