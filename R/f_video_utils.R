# timelapse video utilities

library(av) # video codecs
library(fs) # file systems
library(glue) # pasting paths
library(magick) # for resizing images
library(purrr) # for looping


# stack and scale images:
get_photo_stack <- function(photo_paths, scale_w_h = "800x560") {
  purrr::map(photo_paths, ~ image_read(.x) |> image_scale(scale_w_h)) |> image_join()
}

# write video from stack
write_timelapse_video <- function(photo_stack, output_path, framerate = 20){
  fs::dir_create(fs::path_dir(output_path))
  image_write_video(image=photo_stack, path = output_path, framerate = framerate)
  message(glue("Video saved to: {output_path} using {framerate} fps"))
  output_path
}
