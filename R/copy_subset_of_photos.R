# COPY JUST SPECIFIC TIME STAMPS INTO NEW DIRECTORY
# This code will only work functionally if the photos have already been renamed
# using the code to rename as SITEID_YYYY_MM_DD_HHMMSS.JPG
# It WILL NOT WORK if photos are in an alternate format
# this can be used to only grab 1 photo per day for analysis and storage efficiency
# R. Peek, 2025-Oct

# Library -----------------------------------------------------------------

library(tidyverse)
library(glue)
library(fs)

# Set Params --------------------------------------------------------------

# Time filter: here we only grab photos (inclusive of) these times
time_start <- "12:00:00"
time_end <- "12:10:00"

# Directory of photo origin location
photo_root <- "/Volumes/Extreme SSD/Stream_Timelapse/"
fs::dir_exists(photo_root)

# Out directory
out_dir <- "/Volumes/CEMAF_pheno/TIMELAPSE_ST/"
fs::dir_create(out_dir)
fs::dir_exists(out_dir)

# log outpath
log_path <- file.path(out_dir, "copy_log.csv")

# flags for copying/updates
skip_existing_folders <- TRUE   # if TRUE, skip site/date folders that already exist

# List Photos -------------------------------------------------------------

# this can take a few min!

# List all photos recursively
photo_list <- list.files(photo_root,
                         pattern = "(?i)\\.(jpe?g|png)$",
                         recursive = TRUE,
                         full.names = TRUE,
                         ignore.case = TRUE)

# Create Data Frame -------------------------------------------------------

# create the df for filtering
photo_df <- photo_list |>
  as_tibble() |> rename(path=value) |>
  mutate(
    file_name = path_file(path),
    dir_path = path_dir(path),
    dir_date = basename(dir_path),
    pheno_name = gsub("\\.(jpg|jpeg|png)$", "", file_name, ignore.case = TRUE)) |>
  separate(
    pheno_name,
    into = c("site_id", "year", "month", "day", "time_str"),
    sep = "_",
    remove = FALSE
  ) |>
  mutate(
    date = suppressWarnings(ymd(glue("{year}-{month}-{day}"))),
    time = suppressWarnings(hms::as_hms(
      paste0(
        substr(time_str, 1, 2), ":",
        substr(time_str, 3, 4), ":",
        substr(time_str, 5, 6)
      ))),
    datetime = ymd_hms(paste(date, time))
  ) |>
  select(-c(time_str, year, month, day))

# Filter to Specific Time Frame -------------------------------------------

photo_filt <- photo_df |>
  filter(
    hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) <= hms::as_hms(time_end)) |>
  mutate(dest_dir = glue("{out_dir}/{site_id}/{dir_date}/{file_name}"))

# (a) Skip site/date folders if skip_existing_folders = TRUE
if (skip_existing_folders) {
  existing_dirs <- fs::dir_ls(out_dir, type = "directory", recurse = TRUE) |>
    path_norm()
  photo_filt <- photo_filt |>
    filter(!path_dir(dest_dir) %in% existing_dirs)
}

# Optional: check what was selected
photo_filt |>
  #count(site_id, name="n_photos")
  summarise(n_photos = n_distinct(path), .by = site_id)

# Create Directories for Output ---------------------------------------------

# create directories
dirs_to_create <- photo_filt |>
  distinct(site_id, dir_date) |>
  mutate(dest_dir = glue("{out_dir}/{site_id}/{dir_date}")) |>
  pull(dest_dir)

# Create all unique directories
fs::dir_create(dirs_to_create)

# Copy Photos -------------------------------------------------------------

# use vectorized approach
fs::file_copy(path = photo_filt$path, new_path = photo_filt$dest_dir, overwrite = TRUE)

message(glue("Copied {nrow(photo_filt)} photos into {out_dir}"))

# Validation --------------------------------------------------------------

# Write log
photo_filt |>
  select(site_id, dir_date, date, time, datetime, path, dest_dir) |>
  write_csv(log_path, append = file.exists(log_path))

message(glue("✅ Copy log written to {log_path}"))

# Count source photos per site/date
src_summary <- photo_filt |>
  count(site_id, dir_date, name = "src_count")

# Count photos actually in new destination folders
dst_summary <- fs::dir_info(out_dir, recurse = TRUE, glob = "*.JPG") |>
  mutate(
    dir_date = basename(path_dir(path)),
    site_id  = basename(path_dir(path_dir(path)))
  ) |>
  count(site_id, dir_date, name = "dst_count")

# Combine and show mismatches
validation <- full_join(src_summary, dst_summary, by = c("site_id", "dir_date")) |>
  mutate(match = src_count == dst_count,
         date_ph_copied = Sys.Date())

print(validation)

# Optionally write the validation table
write_csv(validation, file.path(out_dir, "copy_validation_summary.csv"))
message("✅ Validation summary written and displayed above.")

