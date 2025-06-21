
#

#' Extract RGB-based metrics from a time series of images using a static ROI mask
#'
#' @param site_id A character ID for the site
#' @param mask_type The mask type used (e.g., "canopy", "veg")
#' @param exif_dir Directory where EXIF and photo data are stored
#' @param photo_exif_data A tibble of filtered EXIF photo metadata
#' @param timefilt A label for the time filter (default = "1200")
#' @param chunk_size Number of images to process per chunk
#' @param parallel Logical, whether to use parallel processing
#' @return A tibble of RGB and color channel metrics

extract_rgb_parallel <- function(site_id, mask_type, exif_dir, photo_exif_data, timefilt = "1200", chunk_size = 100, parallel = TRUE) {

  suppressPackageStartupMessages({
    library(readr)
    library(purrr)
    library(progressr)
    library(furrr)
    library(glue)
    library(terra)
    library(fs)
    library(tibble)
    library(dplyr)
  })

  message("Loading EXIF metadata...")
  exif_file <- glue::glue("{exif_dir}/pheno_exif_{site_id}_latest.csv.gz")
  photo_exif <- read_csv(exif_file, show_col_types = FALSE)

  message(glue("Reading ROI mask...{mask_type}"))
  mask_file <- glue::glue("{exif_dir}/ROI/{site_id}_{mask_type}.tif")
  if (!file.exists(mask_file)) stop("Mask file not found: ", mask_file)

  message("Using filtered photo paths...")
  photo_paths <- glue::glue("{exif_dir}/{photo_exif_data$file_folder}/{photo_exif_data$pheno_name}")
  if (length(photo_paths) == 0) stop("No photo paths found.")

  # Define a per-session mask loader to avoid reloading every image
  load_mask_once <- local({
    mask_cache <- NULL
    function(mask_path) {
      if (is.null(mask_cache)) {
        mask_cache <<- terra::rast(mask_path, noflip = TRUE)
      }
      mask_cache
    }
  })

  # function
  extract_metrics <- function(path, mask_file) {

    tryCatch({
      pheno_mask <- load_mask_once(mask_file) # cache this here
      img <- terra::rast(path, noflip = TRUE)

      img_cropped <- terra::crop(img, pheno_mask)
      img_masked <- terra::mask(img_cropped, pheno_mask, inverse = FALSE, maskvalues = 0)
      img_vals <- terra::values(img_masked, na.rm=TRUE)
      if (nrow(img_vals) == 0) return(NULL)

      RGB <- colMeans(img_vals)
      t <- rowSums(img_vals)
      ccMat <- sweep(img_vals, 1, t, "/")
      cc <- colMeans(ccMat, na.rm = TRUE)
      cc <- cc / sum(cc)
      std <- apply(ccMat, 2, sd)
      brightness <- mean(apply(img_vals, 2, max))
      darkness <- mean(apply(img_vals, 2, min))

      tibble(
        red = RGB[1], green = RGB[2], blue = RGB[3],
        rcc = cc[1], gcc = cc[2], bcc = cc[3],
        rcc.std = std[1], gcc.std = std[2], bcc.std = std[3],
        brightness = brightness, darkness = darkness, contrast = brightness - darkness,
        grR = gcc / rcc, rbR = rcc / bcc, gbR = gcc / bcc,
        GRVI = (gcc - rcc) / (gcc + rcc), exG = 2 * green - red - blue,
        file_name = fs::path_file(path),
        mask_type = mask_type
      )
    }, error = function(e) {
      message("⚠️ Error on: ", path)
      message("   ", e$message)
      NULL
    })
  }

  message("Splitting into chunks of size ", chunk_size, "...")
  chunks <- split(photo_paths, ceiling(seq_along(photo_paths) / chunk_size))

  if (parallel) {
    message("Setting up parallel plan...")
    future::plan(future::multisession,
                 workers = max(1, future::availableCores() - 1))
    on.exit({
      future::plan(future::sequential)
    }, add = TRUE)
  }

  handlers("txtprogressbar")
  message("Extracting ROI metrics...")

  metric_list <- progressr::with_progress({
    p <- progressr::progressor(along = chunks)
    map(chunks, function(chunk) {
      p()
      if (parallel) {
        furrr::future_map_dfr(
          chunk,
          extract_metrics,
          mask_file,
          .options = furrr::furrr_options(seed = TRUE, globals = TRUE)
        )
      } else {
        # return a list here to save size
        map(chunk, extract_metrics, mask_file)
      }
    })
  })

  # Flatten if serial (list-of-lists of tibbles)
  if (!parallel) {
    metric_list <- flatten(metric_list)
  }

  # Combine results safely
  if (length(metric_list) == 0 || all(map_lgl(metric_list, is.null))) {
    warning("⚠️ No metrics were extracted — all images may have failed.")
    return(NULL)
  }

  # then combine
  metric_df <- bind_rows(metric_list)
  if (nrow(metric_df) == 0) {
    warning("⚠️ metric_df is empty after combining chunks.")
    return(NULL)
  }

  final_df <- metric_df |>
    rename(pheno_name = file_name) |>
    left_join(photo_exif, by = "pheno_name")

  out_file <- glue::glue("{exif_dir}/pheno_metrics_{site_id}_{mask_type}_time_{timefilt}.csv.gz")
  write_csv(final_df, out_file)
  message(glue::glue("\u2714 Metrics saved to {out_file}"))

  invisible(final_df)
}



# library(bench)
# bench::mark(
#   parallel = extract_rgb_parallel(site_id, mask_type, exif_directory, photo_exif_noon, timefilt = "1200_p", chunk_size = 50, parallel = TRUE),
#   serial   = extract_rgb_parallel(site_id, mask_type, exif_directory, photo_exif_noon, timefilt = "1200_np", chunk_size = 50, parallel = FALSE),
#   iterations = 1,
#   check = FALSE
# )
