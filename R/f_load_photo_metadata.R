
# Getting Metadata
load_photo_metadata <- function(photo_dir = NULL, site_id = NULL) {
  library(glue)
  library(fs)
  library(readr)

  if (is.null(photo_dir)) {
    photo_dir <- dirname(file.choose(new = FALSE))
  }
  exif_path <- fs::path_dir(photo_dir)
  photo_date_dir <- basename(photo_dir)

  csv_path_complete <- glue("{exif_path}/pheno_exif_{site_id}_latest.csv.gz")
  csv_path_partial <- glue("{exif_path}/pheno_exif_{site_id}_{photo_date_dir}.csv.gz")

  photo_exif <- if (file_exists(csv_path_complete)) {
    read_csv(csv_path_complete)
  } else {
    read.csv(csv_path_partial)
  }

  return(photo_exif)
}
