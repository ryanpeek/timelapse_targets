
# FUNCTIONS TO WRITE THE SITE_ID and DIRECTORY
library(glue)
library(fs)


# Select Folder -----------------------------------------------------------

# Function to get Folder with Photos:
select_dir <- function() {
  message("Select any image file WITHIN the folder you want to use:")
  dirname(file.choose(new = FALSE))
}

# Run:
selected_dir <- select_dir()

# Confirm
cat(glue::glue("Selected folder: {selected_dir}\n\n"))

# Update Directory/Path in targets_user file ------------------------------

# Load current _targets_user.R
user_file <- "user_parameters.R"
if (!file.exists(user_file)) stop("user_parameters.R not found")

user_lines <- readLines(user_file)

# Update or insert the photo_directory line
pattern <- "^\\s*user_directory\\s*<-.*$"

# Create new line
replacement_line <- glue::glue('user_directory <- "{selected_dir}"')

# Replace or insert
if (any(grepl(pattern, user_lines))) {
  user_lines <- sub(pattern, replacement_line, user_lines)
} else {
  user_lines <- c(user_lines, replacement_line)
}

# Write updated file
writeLines(user_lines, user_file)

# Update SITE_ID in targets_user file ------------------------------

# get the site id from path:
site_id <- fs::path_file(path_dir(selected_dir))

# select the pattern in line
pattern_site <- "^\\s*site_id\\s*<-.*$"

# Create new line
replacement_line_site <- glue::glue('site_id <- "{site_id}"')

# Replace or insert
if (any(grepl(pattern_site, user_lines))) {
  user_lines <- sub(pattern_site, replacement_line_site, user_lines)
} else {
  user_lines <- c(user_lines, replacement_line_site)
}

# Write updated file
writeLines(user_lines, user_file)

cat(glue("\n Site ID: {site_id} and photo directory updated in user_parameters.R\n"))
