
# flexible approach to merging files even if "latest" doesn't exist
merge_with_previous <- function(current_metadata, photo_directory, site_id) {
  metadata_path <- fs::path_dir(photo_directory)
  latest_file <- glue("{metadata_path}/pheno_exif_{site_id}_latest.csv.gz")

  # Find all matching historical files (exclude *_latest.csv.gz)
  all_files <- fs::dir_ls(metadata_path, regexp = glue("pheno_exif_{site_id}_.+\\.csv\\.gz$"))
  dated_files <- all_files[!grepl("_latest\\.csv\\.gz$", all_files)]

  if (length(dated_files) > 0) {
    message(glue("Found {length(dated_files)} previous metadata files. Merging..."))

    previous_dfs <- purrr::map(dated_files, ~ {
      readr::read_csv(.x, show_col_types = FALSE) |>
        mutate(file_folder = as.character(file_folder))  # enforce type
    })

    previous_combined <- bind_rows(previous_dfs)
  } else {
    message("No previous dated metadata files found.")
    previous_combined <- tibble()
  }

  # Combine all: previous + current (file_folder type enforced)
  current_metadata <- current_metadata |> mutate(file_folder = as.character(file_folder))

  combined_metadata <- bind_rows(previous_combined, current_metadata) |>
    distinct(pheno_name_uniq, .keep_all = TRUE) |>
    arrange(datetime)

  message(glue("Final merged metadata has {nrow(combined_metadata)} rows."))

  return(combined_metadata)
}
