if (!requireNamespace("pacman", quietly = TRUE)) install.packages("pacman")

pacman::p_load(
  targets, # for pipeline
  tarchetypes, # for pipeline
  sf, # vector data
  terra, # raster/vect data
  tidyverse, # wrangling/plotting
  progressr, # progress bars
  furrr, # parallel processing
  stringr, # dealing with strings
  fs, # file names/dir
  purrr, # running on lists
  glue, # pasting
  scales, # plotting scales
  digest, # hash id
  exiftoolr, # exif photo info
  magick, # photo/video tools
  av, # video tools
  hms, # time stamp managing
  hrbrthemes, # ggplot themes
  ggimage, # adding images to ggplot
  plotly, # interactive plotting
  pacman # package manager
  )

tar_option_set(
  packages = character(0)  # pacman handles packages, so targets won't auto-load
)
