
rename_photos_safely <- function(photo_metadata,
                                 cam_default_img_name = "RCNX",
                                 dry_run = TRUE,
                                 log_file = NULL,
                                 ask_user = interactive()) {
  log_message <- function(msg) {
    message(msg)
    if (!is.null(log_file)) write(msg, file = log_file, append = TRUE)
  }

  default_named <- photo_metadata |>
    filter(str_detect(file_name, glue("^{cam_default_img_name}")))

  if (nrow(default_named) == 0) {
    log_message("✅ Photos already renamed. Skipping renaming.")
    return("already_renamed")
  }

  duplicates_exist <- photo_metadata |>
    group_by(pheno_name) |>
    tally() |>
    filter(n > 1) |>
    nrow() > 0

  if (ask_user && dry_run) {
    prompt <- "Photos appear un-renamed. Proceed with renaming? (yes/no): "
    response <- tolower(trimws(readline(prompt)))

    if (response %in% c("yes", "y")) {
      dry_run <- FALSE
      log_message("🟢 Proceeding with actual renaming.")
    } else {
      log_message("🟡 Dry-run mode: no files will be renamed.")
    }
  }

  if (!duplicates_exist) {
    log_message("✅ No duplicates. Renaming using `pheno_name`...")
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name}"),
      ~{
        if (dry_run) {
          log_message(glue("DRY RUN: would move {.x} → {.y}"))
        } else {
          fs::file_move(.x, .y)
        }
      }
    )
    return(if (dry_run) "dry_run_simple" else "renamed_simple")
  } else {
    log_message("⚠️ Duplicates found. Appending unique hash to filenames...")
    walk2(
      photo_metadata$full_path,
      glue("{photo_metadata$file_path}/{photo_metadata$pheno_name_uniq}"),
      ~{
        if (dry_run) {
          log_message(glue("DRY RUN: would move {.x} → {.y}"))
        } else {
          fs::file_move(.x, .y)
        }
      }
    )
    return(if (dry_run) "dry_run_hash" else "renamed_with_hash")
  }
}
