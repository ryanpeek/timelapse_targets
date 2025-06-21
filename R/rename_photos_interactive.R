# Rename photos safely based on metadata and user confirmation
rename_photos_safely <- function(cam_default_img_name = "RCNX") {

  # libraries
  library(dplyr)
  library(glue)
  library(fs)
  library(purrr)
  library(readr)
  library(stringr)

  # create log dir and load names/params
  fs::dir_create("logs")
  source("_targets_user.R")
  ph_folder <- as.character(fs::path_file(user_directory))
  log_file <- glue("logs/rename_log_{site_id}_{ph_folder}.txt")

  # make log message function
  log_message <- function(msg, timestamp = TRUE) {
    entry <- if (timestamp) glue("[{Sys.time()}] {msg}") else msg
    message(entry)
    if (!is.null(log_file)) write(entry, file = log_file, append = TRUE)
  }

  # check if photos have been renamed
  default_named <- fs::dir_info(user_directory, type = "file", recurse = TRUE) |>
    mutate(filename = path_file(path)) |>
    filter(str_detect(filename, glue("^{cam_default_img_name}")))

  # get a count and check if done already
  if (nrow(default_named) == 0) {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}:"))
    log_message("Photos already renamed. Skipping renaming.")
    return("already_renamed")
  }

  # get metadata:
  photo_metadata_path <- glue("{exif_directory}/pheno_exif_{site_id}_{ph_folder}.csv.gz")
  photo_metadata <- read_csv(photo_metadata_path, show_col_types=FALSE)

  #### NEW CODE
  # Rename column in file list to match
  default_named <- default_named |>
    mutate(filename = path_file(path)) |>
    rename(full_path = path)

  # Join metadata to actual file list
  matched <- photo_metadata |>
    left_join(default_named, by = c("full_path" = "filename"))

  # Identify unmatched
  unmatched <- matched |> filter(is.na(full_path))

  if (nrow(unmatched) > 0) {
    log_message(glue("❌ {nrow(unmatched)} photo(s) in metadata could not be matched to files."))

    # Optionally write to a separate log for inspection
    unmatched_log_path <- glue("logs/unmatched_{site_id}_{ph_folder}.csv")
    readr::write_csv(unmatched, unmatched_log_path)
    log_message(glue("Unmatched metadata saved to: {unmatched_log_path}"))

    # Ask user whether to continue
    response <- tolower(trimws(readline("Some photos in metadata could not be matched to actual files. Proceed with partial renaming? (yes/no): ")))
    if (!response %in% c("yes", "y")) {
      log_message("User chose not to proceed due to unmatched files.")
      return("aborted_due_to_unmatched")
    }
  }

  # Filter out only matched rows for renaming
  matched <- matched |> filter(!is.na(full_path))




  ##########

  # create tally of dups
  duplicates_exist <- photo_metadata |>
    group_by(pheno_name) |>
    tally() |>
    filter(n > 1) |>
    nrow() > 0

  response <- tolower(trimws(readline("Photos appear un-renamed. Proceed with renaming? (yes/no): ")))
  if (!response %in% c("yes", "y")) {
    log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}: User chose not to rename. Exiting."))
    return("skipped_by_user")
  }

  # count how many need to be renamed?
  n_files <- nrow(photo_metadata)
  log_message(glue("Logged: {Sys.time()} for {site_id} from directory {ph_folder}:"))
  log_message(glue("Preparing to rename {n_files} photo(s)..."))

  sample_paths <- head(glue("{photo_metadata$full_path} → {photo_metadata$file_path}/{if (!duplicates_exist) photo_metadata$pheno_name else photo_metadata$pheno_name_uniq}"), 5)
  log_message("Example renames (first few):")
  walk(sample_paths, ~log_message(.x, timestamp = FALSE))

  rename_safely <- function(from, to) {
    tryCatch({
      if (fs::file_exists(from)) {
        fs::file_move(from, to)
      } else {
        log_message(glue("❌ File not found: {from}. Skipping."))
      }
    }, error = function(e) {
      log_message(glue("❌ Failed to rename {from} → {to}: {e$message}"))
    })
  }

  if (!duplicates_exist) {
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name}"),
      rename_safely
    )
    log_message(glue("✔ Attempted to rename {n_files} photos using `pheno_name`"))
    return("renamed_simple")
  } else {
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name_uniq}"),
      rename_safely
    )
    log_message(glue("✔ Attempted to rename {n_files} photos using `pheno_name_uniq` due to duplicates"))
    return("renamed_with_hash")
  }
}

