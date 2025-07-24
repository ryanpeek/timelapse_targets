get_photo_list <- function(photo_directory) {
  fs::dir_info(photo_directory, type = "file", recurse = TRUE) |>
    filter(!fs::path_ext(path) == "AVI") |>
    mutate(
      file_name = fs::path_file(path),
      full_path = path
    ) |>
    relocate(c(file_name, full_path), .before = "path") |>
    select(-path)
}
