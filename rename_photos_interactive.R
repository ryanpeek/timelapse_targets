# rename safely OUTSIDE of targets package

# Load necessary libraries
library(dplyr)
library(glue)
library(fs)
library(purrr)
library(stringr)

# Define the interactive rename function
rename_photos_safely <- function(photo_metadata,
                                 cam_default_img_name = "RCNX",
                                 log_file = "logs/rename_log.txt") {
  log_message <- function(msg) {
    message(msg)
    if (!is.null(log_file)) write(msg, file = log_file, append = TRUE)
  }

  fs::dir_create("logs")

  source("_targets_user.R")
  ph_folder <- as.character(fs::path_file(user_directory))

  default_named <- photo_metadata |>
    filter(str_detect(file_name, glue("^{cam_default_img_name}")))

  if (nrow(default_named) == 0) {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}:"))
    log_message("Photos already renamed. Skipping renaming.")
    return("already_renamed")
  }

  duplicates_exist <- photo_metadata |>
    group_by(pheno_name) |>
    tally() |>
    filter(n > 1) |>
    nrow() > 0

  # Prompt user
  response <- tolower(trimws(readline("Photos appear un-renamed. Proceed with renaming? (yes/no): ")))

  if (!response %in% c("yes", "y")) {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}: User chose not to rename. Exiting."))
    return("skipped_by_user")
  }

  if (!duplicates_exist) {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}:"))
    log_message("No duplicates. Renaming using `pheno_name`...")
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name}"),
      ~{
        log_message(glue("Renaming {.x} → {.y}"))
        fs::file_move(.x, .y)
      }
    )
    return("renamed_simple")
  } else {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}:"))
    log_message("Duplicates found! Using `pheno_name_uniq`...")
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name_uniq}"),
      ~{
        log_message(glue("Renaming {.x} → {.y}"))
        fs::file_move(.x, .y)
      }
    )
    return("renamed_with_hash")
  }
}
