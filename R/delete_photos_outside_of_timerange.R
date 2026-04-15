# delete photos not within time frame
# useful to clean up space AFTER photos are uploaded to WI
# constrain to just 10-2 or 12pm photos

library(exiftoolr)
library(dplyr)
library(fs)

# Parameters --------------------------------------------------------------

source("set_photo_dir.R") # creates "selected_dir" as object in R
source("user_parameters.R")
tz        <- "America/Los_Angeles"         # adjust if needed
time_start  <- '11:00:00'                            # 10 AM
time_end    <- '13:00:00'                            # 2 PM
dry_run   <- TRUE

# extract a few pieces
exif_directory <- fs::path_dir(selected_dir)
site_id <- fs::path_file(path_dir(selected_dir))


# Use Exiftools to filter -------------------------------------------------

exif_filter <- sprintf(
  "$Time ge '%s' and $Time lt '%s'",
  time_start,
  time_end
)

# List Files --------------------------------------------------------------

files <- fs::dir_ls(selected_dir, recurse = TRUE, type="file")

# Read in Files that Meet Filter Params -----------------------------------

df_keep <- exiftoolr::exif_read(
  files,
  tags = c("FileName", "Directory", "DatetimeOriginal"),
  args = c("-if", exif_filter)) |>
  mutate(
    full_path = file.path(Directory, FileName),
    datetime  = ymd_hms(DateTimeOriginal, tz = tz),
    time_str  = format(datetime, "%H:%M:%S")
  )


# build paths for files to keep
keep_paths <- df_keep$full_path

# Validation
df_keep <- df_keep  |>
  mutate(
    within_window = time_str >= start_time & time_str <= end_time
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
print(head(delete_paths, 20))


# Delete Files ------------------------------------------------------------

if (dry_run) {
  message("DRY RUN: No files deleted.")
} else {
  paths <- delete_paths[fs::file_exists(delete_paths)]
  fs::file_delete(paths)
  message(length(paths), " files deleted.")
}

# Log these changes
write.csv(
  df_keep  |> select(full_path, DateTimeOriginal, datetime, time_str),
  file=glue("{exif_directory}/logs/{Sys.Date}_kept_files.csv"),
  row.names = FALSE
)

write.csv(
  data.frame(full_path = delete_paths),
  file=glue("{exif_directory}/logs/{Sys.Date}_deleted_files.csv"),
  row.names = FALSE
)


