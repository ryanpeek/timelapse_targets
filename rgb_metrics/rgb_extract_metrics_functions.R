# extract RGB metrics

#library(furrr)
#library(future)
library(data.table)
library(terra)


# Getting Metadata for ROI selection
load_photo_metadata <- function(photo_dir = NULL, site_id = NULL) {
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
    read_csv(csv_path_partial)
  }

  return(photo_exif)
}

# reads a single photo and generates the information/metrics of interest
ph_get_CCC <- function(path, pheno_mask){
  require(terra)

  img <- terra::rast(path, noflip=TRUE)
  img_masked <- terra::mask(img, pheno_mask, inverse=FALSE, maskvalues=0)
  img_matrix <- na.omit(as.matrix(img_masked))
  tbl <- as.data.frame(t(apply(img_matrix, 2, quantile, na.rm=TRUE, probs = c(0, 0.05, 0.10, 0.25, 0.5, 0.75, 0.90, 0.95, 1))))
  rownames(tbl) <- c('r','g','b')
  colnames(tbl) <- c('min','q5', 'q10','q25','q50','q75', 'q90','q95','max')
  RGB <- colMeans(img_matrix)
  t <- rowSums(img_matrix)
  ccMat <- apply(img_matrix, 2, '/', t)
  cc <- colMeans(ccMat, na.rm = TRUE)
  cc <- cc/sum(cc)
  tbl$cc <- cc
  tbl$std <- apply(ccMat, 2, sd)
  tbl$brightness <- mean(apply(img_matrix, 2, max))
  tbl$darkness <- mean(apply(img_matrix, 2, min))
  tbl$contrast <- tbl$brightness - tbl$darkness
  tbl$RGB <- RGB
  return(tbl)
}

# reads all the photos in the list and applies the above function
ph_make_CCC_ts <- function(photolist, pheno_mask) {
  require(data.table)

  n <- length(photolist)
  CCCT <- matrix(NA, nrow = n, ncol = 33)
  for (i in 1:n) {
    print(paste0("Extracting CCs for ", i))
    tbl <- ph_get_CCC(photolist[i], pheno_mask)
    if (!is.null(tbl))
      CCCT[i, ] <- c(tbl$RGB, tbl$cc, tbl$std, tbl$q5,
                     tbl$q10, tbl$q25, tbl$q50, tbl$q75, tbl$q90,
                     tbl$q95, tbl$brightness[1], tbl$darkness[1],
                     tbl$contrast[1])
  }

  CCCT <- as.data.table(CCCT)
  colnames(CCCT) <- c("red", "green", "blue", "rcc", "gcc",
                      "bcc", "rcc.std", "gcc.std", "bcc.std", "rcc05", "gcc05",
                      "bcc05", "rcc10", "gcc10", "bcc10", "rcc25", "gcc25",
                      "bcc25", "rcc50", "gcc50", "bcc50", "rcc75", "gcc75",
                      "bcc75", "rcc90", "gcc90", "bcc90", "rcc95", "gcc95",
                      "bcc95", "brightness", "darkness", "contrast")
  CCCT[, `:=`(grR, gcc/rcc)]
  CCCT[, `:=`(rbR, rcc/bcc)]
  CCCT[, `:=`(gbR, gcc/bcc)]
  CCCT[, `:=`(GRVI, (gcc - rcc)/(gcc + rcc))] # green-red vegetation index
  CCCT[, `:=`(exG, (2 * green - red - blue))] # excess green
  CCCT[, `:=`(file_name, (fs::path_file(photolist)))]
  return(CCCT)
}



### SIMPLE EXTRACT
extract_rgb_mean <- function(image_paths, roi_mask) {
  purrr::map_dfr(image_paths, function(path) {
    img <- terra::rast(path, noflip=TRUE)
    masked <- terra::mask(img, roi_mask)
    tibble(
      file = path,
      date = as.Date(stringr::str_extract(path, "\\d{8}")),
      mean_r = mean(masked[[1]][], na.rm = TRUE),
      mean_g = mean(masked[[2]][], na.rm = TRUE),
      mean_b = mean(masked[[3]][], na.rm = TRUE)
    )
  })
}

