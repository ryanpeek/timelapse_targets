# delete photos not within time frame
# useful to clean up space AFTER photos are uploaded to WI
# constrain to just 10-2 or 12pm photos

library(exiftoolr)
library(dplyr)
library(fs)

# Parameters --------------------------------------------------------------

source("set_photo_dir.R") # creates "selected_dir" as object in R
source("user_parameters.R")
tz        <- "America/Los_Angeles"
time_start  <- '11:30:00'
time_end    <- '12:30:00'
dry_run   <- TRUE

# extract a few pieces
exif_directory <- fs::path_dir(selected_dir)
site_id <- fs::path_file(path_dir(selected_dir))

# List Files --------------------------------------------------------------

files <- fs::dir_ls(selected_dir, recurse = TRUE, type="file")

# Read in Files that Meet Filter Params -----------------------------------

df <- exiftoolr::exif_read(
  files,
  tags = c("FileName", "Directory", "DateTimeOriginal")) |>
  mutate(
    full_path = file.path(Directory, FileName),
    datetime  = lubridate::ymd_hms(DateTimeOriginal, tz = tz)
  )

df_keep <- df |>
  filter(
    format(datetime, "%H:%M:%S") >= time_start,
    format(datetime, "%H:%M:%S") <= time_end
  )

# build paths for files to keep
keep_paths <- df_keep$full_path

# Validation
df_keep <- df_keep  |>
  mutate(
    within_window = format(datetime, "%H:%M:%S") >= time_start & format(datetime, "%H:%M:%S") <= time_end
  )

# validation
validation_issues <- df_keep |>
  filter(!within_window)

if (nrow(validation_issues) > 0) {
  warning("Some kept files fall OUTSIDE the expected time window!")
  print(validation_issues)
  stop("Aborting due to validation failure.")
}

# Get Delete Paths -------------------------------------------------------

# build paths for files to DELETE
delete_paths <- setdiff(files, keep_paths)

# Check and Inspect -------------------------------------------------------

cat("Total photos:", length(files), "\n")
cat("Photos kept:", length(keep_paths), "\n")
cat("Photos to delete:", length(delete_paths), "\n\n")

# Preview first few files
#print(head(delete_paths, 20))


# Delete Files ------------------------------------------------------------

dry_run   <- FALSE

if (dry_run) {
  message("DRY RUN: No files deleted.")
} else {
  paths <- delete_paths[fs::file_exists(delete_paths)]
  fs::file_delete(paths)
  message(length(paths), " files deleted.")
}

# Log these changes
write.csv(
  df_keep,
  file=glue("{exif_directory}/logs/{Sys.Date()}_{site_id}_kept_files_{fs::path_file(selected_dir)}.csv"),
  row.names = FALSE
)

write.csv(
  data.frame(full_path = delete_paths),
  file=glue("{exif_directory}/logs/{Sys.Date()}_{site_id}_deleted_files_{fs::path_file(selected_dir)}.csv"),
  row.names = FALSE
)


