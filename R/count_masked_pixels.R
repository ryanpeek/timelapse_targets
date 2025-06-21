# get a pixel count

library(terra)
library(glue)

count_masked_pixels <- function(photo_path, mask_path, mask_type,
                                save_plot = TRUE) {
  stopifnot(file.exists(photo_path), file.exists(mask_path))

  # Load the photo and mask
  img <- terra::rast(photo_path, noflip = TRUE)
  img_mask <- terra::rast(mask_path)

  # Reproject mask if needed
  if (!compareGeom(img, img_mask, stopOnError = FALSE)) {
   img_mask <- terra::project(img_mask, img)
  }

  # Resample mask to match image if resolution differs
  if (!all(dim(img)[1:2] == dim(img_mask)[1:2])) {
   img_mask <- terra::resample(mask, img, method = "near")
  }

  # Count non-zero mask pixels (assuming 0 = outside ROI, 1 = inside),
  # ensure we only have the 1's
  # Ensure binary mask
  mask_bin <- img_mask[[1]] == 1
  pixel_count <- terra::global(mask_bin, fun = "sum", na.rm = TRUE)[1, 1]

  message(glue("{pixel_count} pixels selected in mask."))

  # Get pixel coords
  cell_ids <- which(values(mask_bin) == 1)
  coords <- terra::xyFromCell(mask_bin, cell_ids)

  # Get pixel dimensions
  pixel_w <- res(mask_bin)[1]
  pixel_h <- res(mask_bin)[2]

  # Create pixel boxes
  pixel_boxes <- vect(lapply(1:nrow(coords), function(i) {
    x <- coords[i, 1]
    y <- coords[i, 2]
    terra::ext(x - pixel_w / 2, x + pixel_w / 2,
               y - pixel_h / 2, y + pixel_h / 2) |> as.polygons()
  }))

  # show the plot
  plot(pixel_boxes, border = "orange4", col = alpha("orange", 0.2),
       main = glue("{mask_type}: {pixel_count} pixels selected"),
       axes = TRUE)


  if (save_plot) {
    roi_dir <- fs::path_dir(mask_path)
    plot_path <- glue("{roi_dir}/roi_pixel_plot_{mask_type}.png")

    # Plot and save
    dir.create(fs::path_dir(plot_path), showWarnings = FALSE)
    png(plot_path, width = 800, height = 800)
    plot(pixel_boxes, border = "blue", col = "lightblue",
         main = glue("{mask_type}: {pixel_count} pixels selected"),
         axes = TRUE)
    dev.off()

    message(glue("ROI pixel plot saved to: {plot_path}"))
  }

  return(pixel_count)
}
