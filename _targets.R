# TARGET Workflow to process timelapse imagery
# R. Peek

# USER PARAMETERS FROM _targets_user.R ------------------------------------
# source user parameters
if (file.exists("_targets_user.R")) {
  source("_targets_user.R")
} else {
  stop("Missing _targets_user.R file with your user parameters")
}

# Packages ----------------------------------------------------------------

library(targets)
library(tarchetypes)
library(tidyverse)
library(fs)
library(exiftoolr)
library(janitor)
library(digest)
library(glue)
library(hms)

# Set options for reproducibility and packages
tar_option_set(
  packages = c("tidyverse", "fs", "exiftoolr", "janitor", "digest", "glue", "hms", "magick")
)

# Source custom functions from the "R/" directory
purrr::walk(list.files("R", full.names = TRUE), source)


# Main Pipeline to Process Images -----------------------------------------

# this is the main pipeline to get metadata and save out

core_targets <-
  list(

    tar_target(
      photo_directory,
      {
        message(glue(">>> Using site_id: {site_id}"))
        user_directory
      }
      #cue = tar_cue(mode = "always")  # force re-run every time
    ),

    # this is more complicated to process multiple folders down the road
    # tar_target(
    #   unprocessed_folders,
    #   {
    #
    #     folder_paths <- fs::dir_ls(fs::path_dir(photo_directory), type="directory")
    #     folder_dates <- fs::path_file(folder_paths)
    #     # only keep dates that are YYYYMMDD
    #     is_date_folder <- grepl("^\\d{8}$", folder_dates)
    #     # now filter
    #     folder_paths <- folder_paths[is_date_folder]
    #     folder_dates <- folder_dates[is_date_folder]
    #
    #     expected_csvs <- glue("pheno_exif_{site_id}_{folder_dates}.csv.gz")
    #     csv_paths <- fs::path(path_dir(photo_directory), expected_csvs)
    #
    #     # only list dir where we are missing dir
    #     folder_paths[!fs::file_exists(csv_paths)]
    #   }
    # ),

    # this is just to check if folder already processed
    tar_target(
      exif_csv_path,
      {
        folder_date <- fs::path_file(photo_directory)
        glue("{fs::path_dir(photo_directory)}/pheno_exif_{site_id}_{folder_date}.csv.gz")
      }
    ),

    # Read list of photos
    tar_target(
      photo_list,
      fs::dir_info(photo_directory, type = "file", recurse = TRUE) |>
        filter(!fs::path_ext(path) == "AVI") |>
        mutate(
          file_name = fs::path_file(path),
          full_path = path
        ) |>
        relocate(c(file_name, full_path), .before = "path") |>
        select(-path)
    ),

    # Split into chunks
    tar_target(
      photo_chunks,
      split(photo_list$full_path, ceiling(seq_along(photo_list$full_path) / chunk_size)),
      iteration = "list"
    ),

    # First: Read EXIF from CSV if it exists
    tar_target(
      exif_data,
      {
        if (fs::file_exists(exif_csv_path)) {
          message(">>> Found existing EXIF CSV, skipping EXIF extraction")
          readr::read_csv(exif_csv_path)
        } else {
          NULL
        }
      }
    ),

    # Otherwise read EXIF in chunks
    tar_target(
      exif_data_chunks,
      {
        if (is.null(exif_data)) {
          message(">>> Reading EXIF metadata in chunks")
          exiftoolr::exif_read(photo_chunks) |> janitor::clean_names()
        } else {
          NULL
        }
      },
      pattern = map(photo_chunks),
      iteration = "list"
    ),

    # Format either the chunked or full data
    tar_target(
      photo_metadata,
      {
        if (!is.null(exif_data)) {
          # Already formatted, return directly
          exif_data
        } else {
          # Needs formatting first
          bind_rows(
            lapply(exif_data_chunks, format_exif_metadata, site_id = site_id)
          )
        }
      }
    ),

    # Merge with previous
    tar_target(
      merged_metadata,
      merge_with_previous(photo_metadata, photo_directory, site_id)
    ),

    # Save merged metadata
    tar_target(
      save_metadata,
      save_merged_metadata(merged_metadata, photo_metadata, photo_directory, site_id),
      format = "file"
    )
  )

# Timelapse Video Pipeline ------------------------------------------------

# THIS IS THE TIMELAPSE VIDEO CREATION SECTION
# only runs if the flag in "_targets_user.R" is TRUE
timelapse_targets <- if(make_timelapse_video){
  list(

    # set the filter time for photos between 12 and 1 to make a video
    tar_target(
      timelapse_metadata,
      {
        dat_filtered <- merged_metadata |>
          filter(
            as_date(datetime)>=date_start & as_date(datetime)<= date_end,
            hms::as_hms(datetime) >= hms::as_hms(time_start) & hms::as_hms(datetime) < hms::as_hms(time_end))

        # check to see if data exists
        if (nrow(dat_filtered) == 0){
          warning("No photos found for this specified date/time range. Check _targets_user.R file. Skipping video creation.")
        }
        dat_filtered
      }
    ),

    # build the image paths we need
    tar_target(
      timelapse_image_paths,
      {
        paths <- file.path(fs::path_dir(photo_directory), timelapse_metadata$file_folder,  timelapse_metadata$pheno_name)
        as.character(paths)
      }
    ),

    # write video out
    tar_target(
      timelapse_video_file,
      {
        # make location to save files
        vid_path = file.path(fs::path_dir(photo_directory), "videos")
        fs::dir_create(vid_path)
        # check if data exists
        if(nrow(timelapse_metadata)==0||length(timelapse_image_paths)==0)
        {
          message("Skipping timelapse video creation, no images to render.")
          temp_file <- file.path(vid_path, glue("README_{site_id}_no_images_for_video_{gsub(pattern = '-','',Sys.Date())}.txt"))
          # write message in file:
          msg <- glue("No timelapse video could be created due to lack of imagery.\n",
                      "Date filter: {date_start} to {date_end} \n",
                      "Time filter: {time_start} to {time_end} \n",
                      "Please check and adjust!")
          writeLines(msg, temp_file)
          return(temp_file)
        }
        # assuming data exists, proceed here
        vid_name = glue("{site_id}_{gsub(pattern = '-','',date_start)}_{gsub(pattern = '-','',date_end)}_video.mp4")
        output_path <- glue("{vid_path}/{vid_name}")

        # make photo stack to use
        timelapse_stack <- get_photo_stack(timelapse_image_paths, scale_w_h = "800x540")

        # write the video!
        message("Writing video...this may take a minute")
        image_write_video(image=timelapse_stack, path=output_path, framerate=20)
        stopifnot(file.exists(output_path))
        output_path
      },
      format = "file"
    )
  )
} else {
  list()
}

# now run it all!
core_targets |>
  append(timelapse_targets)


  # this works but we can't run interactively
    # tar_target(
    #   rename_status,
    #   rename_photos_safely(photo_metadata, log_file = "logs/rename_log.txt"),
    #   cue = tar_cue(mode = "always")
    # )
