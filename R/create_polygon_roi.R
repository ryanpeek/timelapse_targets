# function to get draw polygon
library(terra)
library(fs)
library(glue)

source("R/load_photo_metadata.R")

# draw a polygon function
draw_poly_roi <- function (col = "#80303080", lty = 1, ...) {
  xy <- locator(2)
  lines(xy$x, xy$y, lty = lty)

  while(is.list(c1 <- locator(1))) {
    xy$x <- c(xy$x, c1$x)
    xy$y <- c(xy$y, c1$y)
    lines(xy$x, xy$y, lty = lty)
  }
  xy <- data.frame(xy)
  xy <- rbind(xy, xy[1, ])
  polygon(xy$x, xy$y, lty = lty, col = col, ...)

  invisible(xy)
}

# make polygon
make_polygon_roi <- function(photo_exif_noon,
                             user_directory,
                             index = 3,
                             mask_type = "ROI_01",
                             overwrite = FALSE) {

  # paths
  stopifnot(fs::dir_exists(user_directory))
  exif_path <- fs::path_dir(user_directory)
  img_path <- glue("{exif_path}/{photo_exif_noon$file_folder[index]}/{photo_exif_noon$pheno_name[index]}")
  stopifnot(fs::file_exists(img_path))

  # save path
  fs::dir_create(glue("{exif_path}/ROI"))

  # Load image
  #if (grepl("\\.tif(f)?$", img_path, ignore.case = TRUE)) {
  img <- terra::rast(img_path, noflip=TRUE)
  #} else {
  #  img2 <- magick::image_read(img_path)
  #  img2 <- as.raster(img2)
  #}

  plotRGB(img) #main = basename(img_path))
  message("🖍️  Draw a polygon on the image. Press ESC or finish when done.")
  poly_out <- draw_poly_roi()

  if (is.null(poly_out)) {
    warning("No polygon drawn.")
    return(invisible(NULL))
  }

  poly_out <- terra::vect(cbind(poly_out$x, poly_out$y), "polygons")
  plot(poly_out, col=alpha("yellow", 0.6), add=TRUE)

  # Rasterize and convert to binary
  poly_rast <- terra::rasterize(poly_out, img)
  poly_rast[is.na(poly_rast)] <- 0

  # Count number of pixels in the polygon (non-zero)
  pixel_count <- global(poly_rast != 0, fun = "sum", na.rm = TRUE)[1, 1]
  message(glue("{pixel_count} pixels selected in the ROI polygon."))

  # Save raster
  save_path <- glue("{exif_path}/ROI/{site_id}_{mask_type}")
  if (!is.null(save_path)) {
    terra::writeRaster(poly_rast, filename = glue("{save_path}.tif"),
                       overwrite=overwrite)
  }
  # save plot
  png(glue("{save_path}_roi_masked.png"),
      width=800, # smaller
      #width = 2048, height = 1440, # full size
      bg = "transparent")
  terra::plotRGB(img)
  plot(poly_rast, col = c(alpha("white", 0), alpha("yellow", 0.8)), legend = FALSE, add = TRUE, axes=FALSE)
  dev.off()

  return(list(out_rast = poly_rast, out_poly = poly_out))
}

