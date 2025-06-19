
# wrapper to grab data and extract

extract_rgb_vect <- function(site_id, mask_type, exif_dir, photo_exif_data, timefilt="1200") {
  library(readr)
  library(dplyr)
  library(purrr)
  library(fs)
  #library(furrr)
  library(terra)
  library(progressr)

  # if (parallel) {
  #   future::plan(future::multisession, workers = future::availableCores() - 1)
  #   on.exit(future::plan(future::sequential), add = TRUE)
  # }

  message("Loading EXIF metadata...")
  exif_file <- glue::glue("{exif_dir}/pheno_exif_{site_id}_latest.csv.gz")
  photo_exif <- read_csv(exif_file, show_col_types = FALSE)

  message("Reading ROI mask...")
  mask_file <- glue::glue("{exif_dir}/ROI/{site_id}_{mask_type}.tif")
  pheno_mask <- terra::rast(mask_file, noflip=TRUE)

  message("using filtered photo paths...")
  photo_paths <- glue::glue("{exif_dir}/{photo_exif_data$file_folder}/{photo_exif_data$pheno_name}")

  message("Extracting ROI metrics...")

  handlers("txtprogressbar")
  progressr::with_progress({
    p <- progressr::progressor(along = photo_paths)

    metric_df <- purrr::map_dfr(photo_paths, function(path) {
      p()
      tryCatch({
        img <- terra::rast(path, noflip = TRUE)
        img_masked <- terra::mask(img, pheno_mask, inverse = FALSE, maskvalues = 0)
        img_matrix <- na.omit(as.matrix(img_masked))

        if (nrow(img_matrix) == 0) return(NULL)

        RGB <- colMeans(img_matrix)
        t <- rowSums(img_matrix)
        ccMat <- sweep(img_matrix, 1, t, "/")
        cc <- colMeans(ccMat, na.rm = TRUE)
        cc <- cc / sum(cc)

        #quant <- apply(img_matrix, 2, quantile, probs = c(0, 0.05, 0.1, 0.25, 0.5, 0.75, 0.9, 0.95, 1), na.rm = TRUE)
        std <- apply(ccMat, 2, sd)

        brightness <- mean(apply(img_matrix, 2, max))
        darkness <- mean(apply(img_matrix, 2, min))

        tibble(
          red = RGB[1], green = RGB[2], blue = RGB[3],
          rcc = cc[1], gcc = cc[2], bcc = cc[3],
          rcc.std = std[1], gcc.std = std[2], bcc.std = std[3],
          #rcc05 = quant[2,1], gcc05 = quant[2,2], bcc05 = quant[2,3],
          #rcc10 = quant[3,1], gcc10 = quant[3,2], bcc10 = quant[3,3],
          #rcc25 = quant[4,1], gcc25 = quant[4,2], bcc25 = quant[4,3],
          #rcc50 = quant[5,1], gcc50 = quant[5,2], bcc50 = quant[5,3],
          #rcc75 = quant[6,1], gcc75 = quant[6,2], bcc75 = quant[6,3],
          #rcc90 = quant[7,1], gcc90 = quant[7,2], bcc90 = quant[7,3],
          #rcc95 = quant[8,1], gcc95 = quant[8,2], bcc95 = quant[8,3],
          brightness = brightness,
          darkness = darkness,
          contrast = brightness - darkness,
          grR = gcc / rcc,
          rbR = rcc / bcc,
          gbR = gcc / bcc,
          GRVI = (gcc - rcc) / (gcc + rcc),
          exG = 2 * green - red - blue,
          file_name = fs::path_file(path)
        )
      }, error = function(e) NULL)
    })
  })

  final_df <- metric_df |>
    dplyr::rename(pheno_name = file_name) |>
    dplyr::left_join(photo_exif, by = "pheno_name")

  out_file <- glue::glue("{exif_dir}/pheno_metrics_{site_id}_{mask_type}_time_{timefilt}.csv.gz")
  readr::write_csv(final_df, out_file)
  message(glue::glue("✔ Metrics saved to {out_file}"))

  return(invisible(final_df))
}
