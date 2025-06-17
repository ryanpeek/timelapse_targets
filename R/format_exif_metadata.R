# get exif metadata

format_exif_metadata <- function(exif_data_chunk, site_id) {
  exif_data_chunk |>
    select(any_of(c(
      "directory", "file_name", "file_number", "create_date", "exposure_time",
      "moon_phase", "ambient_temperature", "ambient_temperature_fahrenheit",
      "ambient_infrared", "ambient_light", "serial_number", "image_size",
      "image_width", "image_height", "battery_voltage", "battery_voltage_avg"
    ))) |>
    rename(
      file_path = directory,
      datetime = create_date,
      exposure = exposure_time
    ) |>
    filter(!is.na(datetime), !is.na(file_name)) |>
    mutate(
      file_path = as.character(file_path),
      site_id = site_id,
      file_folder = as.character(path_file(file_path)),
      datetime = ymd_hms(datetime),
      photo_ymdhms = glue("{format(as_date(datetime), '%Y_%m_%d')}_{gsub(':', '', hms::as_hms(datetime))}"),
      pheno_name = glue("{site_id}_{photo_ymdhms}.{path_ext(file_name)}"),
      hashid = map_vec(glue("{file_path}/{file_name}"), ~digest::digest(.x, algo = "crc32", serialize = FALSE)),
      pheno_name_uniq = glue("{site_id}_{photo_ymdhms}_{hashid}.{path_ext(file_name)}"),
      full_path = glue("{file_path}/{file_name}"),
      rel_path = glue("TIMELAPSE/{site_id}/{file_folder}/{pheno_name}")
    ) |>

    arrange(datetime) |>
    filter(!is.na(datetime))
}
