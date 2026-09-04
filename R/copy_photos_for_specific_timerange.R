# Copy photos only within a certain time range
# useful for storing photos or subset for uploading to WI
# constrain to just 10-2 or 12pm photos

library(exiftoolr)
library(dplyr)
library(lubridate)
library(fs)
library(readr)
library(tictoc)

# Parameters --------------------------------------------------------------

source("set_photo_dir.R") # pick photo from folder we want to copy photos over from
tz        <- "America/Los_Angeles"
time_start  <- '12:00:00'
time_end    <- '12:10:00'

# select the directory we want to save TO
out_dir <- "F:/TIMELAPSE"

# extract a few pieces
exif_directory <- fs::path_dir(selected_dir)

# set site_id if using external drive and named site folders
(site_id <- fs::path_file(path_dir(selected_dir)))

# set site_id manually if reading directly from SD card
site_id <- "CCEC4"

# directory to save the photos into (i.e., "midday")
subset_dir_name <- "midday"

# Create out directory if it doesn't exist
fs::dir_create(glue("{out_dir}/{site_id}/{subset_dir_name}"))

# Check for Existing Metadata ---------------------------------------------

# Find Full Extracted list if it exists?
if(fs::file_exists(glue("{exif_directory}/pheno_exif_{site_id}_latest.csv.gz"))){
  df_pheno <- read_csv(glue("{exif_directory}/pheno_exif_{site_id}_latest.csv.gz")) |>
    # update full_path w current "full path"
    mutate(full_path=glue("{exif_directory}/{file_folder}/{pheno_name}"))
} else({
  glue("File doesn't exist, read in manually")
})


# Read in Files that Meet Filter Params -----------------------------------

# this can take a while

if(!exists("df_pheno", envir = .GlobalEnv)){
  tic("exif extraction")
  # get file list
  files <- fs::dir_ls(selected_dir, recurse = TRUE, type="file")
  print(glue("{nrow(files)} total photos...}"))
  # read in
  print(glue("Extracting metadata..."))
  df_pheno <- exiftoolr::exif_read(
  files,
  tags = c("FileName", "Directory", "DateTimeOriginal")) |>
  mutate(
    full_path = file.path(Directory, FileName),
    datetime  = lubridate::ymd_hms(DateTimeOriginal, tz = tz),
    photo_ymdhms = glue("{format(as_date(datetime), '%Y_%m_%d')}_{gsub(':', '', hms::as_hms(datetime))}"),
    pheno_name = glue("{site_id}_{photo_ymdhms}.{path_ext(FileName)}"))
  print(glue("Finished!"))
  toc()
} else({
  glue("File already in environment, using 'df_pheno'! ")
})

# set paths for photos we want to copy
df_keep <- df_pheno |>
  filter(
    format(datetime, "%H:%M:%S") >= time_start,
    format(datetime, "%H:%M:%S") <= time_end
  )

# double check paths are valid? Should return TRUE
nrow(df_keep)==sum(file_exists(df_keep$full_path))

# build paths for files to copy
keep_paths <- df_keep$full_path

# Validation: double check with additional filter and add renaming option:
df_keep <- df_keep  |>
  mutate(
    within_window = format(datetime, "%H:%M:%S") >= time_start & format(datetime, "%H:%M:%S") <= time_end
  ) |>
  mutate(
    dest_dir = glue("{out_dir}/{site_id}/{subset_dir_name}/{pheno_name}"))

# Check and Inspect -------------------------------------------------------

validation_issues <- df_keep |>
  filter(!within_window)

if (nrow(validation_issues) > 0) {
  warning("Some kept files fall OUTSIDE the expected time window!")
  print(validation_issues)
  stop("Aborting due to validation failure.")
}

cat("Total photos:", nrow(df_pheno), "\n")
cat("Photos kept:", length(keep_paths), "\n")
fs::dir_exists(glue("{out_dir}/{site_id}/{subset_dir_name}"))

# Copy Files ------------------------------------------------------------
tic("Copy files")
message(glue("Copying {nrow(df_keep)} photos into {out_dir}/{site_id}/{subset_dir_name}/..."))
fs::file_copy(path = df_keep$full_path, new_path = df_keep$dest_dir, overwrite = TRUE)
message(glue("Done!"))
toc()

