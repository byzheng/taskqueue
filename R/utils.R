

#' Check absolute path for Linux
#'
#' @param path File path to check
#'
#' @return No return is expected
.check_linux_absolute_path <- function(path) {
    grepl("^/", path)
}


#' Check absolute path for Windows
#'
#' @param path File path to check
#'
#' @return No return is expected
.check_windows_absolute_path <- function(path) {
    grepl("^[a-zA-Z]{1}:(/|\\\\).+$", path)
}
