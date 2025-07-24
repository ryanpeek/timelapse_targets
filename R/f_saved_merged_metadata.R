
save_merged_metadata <- function(merged_metadata, current_metadata, photo_directory, site_id) {
  metadata_path <- fs::path_dir(photo_directory)
  fs::dir_create(metadata_path)

  # Extract folder name (e.g., "20230411")
  folder_name <- fs::path_file(photo_directory)

  if (grepl("^\\d{8}$", folder_name)) {
    folder_date <- folder_name
  } else {
    warning("Photo directory name does not look like a date (YYYYMMDD). Using today's date instead.")
    folder_date <- format(Sys.Date(), "%Y%m%d")
  }

  latest_file <- glue("{metadata_path}/pheno_exif_{site_id}_latest.csv.gz")
  dated_file  <- glue("{metadata_path}/pheno_exif_{site_id}_{folder_date}.csv.gz")

  # Save merged full set as "latest"
  readr::write_csv(merged_metadata, latest_file)

  # Save only current folder's data as dated file
  readr::write_csv(current_metadata, dated_file)

  message(glue("Saved:\n- Latest merged metadata → {latest_file}\n- Dated snapshot for {folder_date} → {dated_file}"))

  return(latest_file)
}
