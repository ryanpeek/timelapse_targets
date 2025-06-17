# get the folder with photos:
select_dir <- function() {
  message("Select any image file WITHIN the folder you want to use:")
  dirname(file.choose(new = FALSE))
}
# run this
selected_dir <- select_dir()

# Confirm
cat(glue::glue("Selected folder: {selected_dir}\n\n"))

# Load current _targets_user.R
user_file <- "_targets_user.R"
if (!file.exists(user_file)) stop("_targets_user.R not found")

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

cat("\n ✅ User directory updated in _targets_user.R\n")
