

#' Check absolute path for Linux
#'
#' @param path File path to check
#'
#' @return No return is expected
.check_linux_absolute_path <- function(path) {
    if (!grepl("^/", path)) {
        stop("Absolute path for Linux is required: ", path)
    }
    if (!file.exists(path)) {
        stop("Cannot find the path: ", path)
    }
}
