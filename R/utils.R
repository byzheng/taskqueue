

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

#' Check absolute path for system
#'
#' @param path File path to check
#'
#' @return No return is expected
.check_absolute_path <- function(path) {
    r <- NULL
    if (.Platform$OS.type == 'windows') {
        r <- .check_windows_absolute_path()
    } else if (.Platform$OS.type == "unix") {
        r <- .check_linux_absolute_path(path)
    } else {
        stop("Not implemented platform type")
    }
    r
}
