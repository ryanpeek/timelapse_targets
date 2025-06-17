select_photo_directory <- function() {
  message("Select a photo file to determine the target directory...")
  dirname(file.choose(new = FALSE))
}
