

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
    if (.Platform$OS.type == "windows") {
        r <- .check_windows_absolute_path(path)
    } else if (.Platform$OS.type == "unix") {
        r <- .check_linux_absolute_path(path)
    } else {
        stop("Not implemented platform type")
    }
    r
}


.is_bin_on_path <- function(bin) {
    if (.Platform$OS.type == "unix") {
        exit_code <- suppressWarnings(system2("command", args = c("-v", bin), stdout = FALSE))
    } else if (.Platform$OS.type == "windows") {
        exit_code <- suppressWarnings(system2("where", args = bin, stdout = FALSE,
                                             stderr = FALSE))
    } else {
        stop("Only support unix and windows")
    }
    return(exit_code == 0)
}


.hostname <- function() {
    if (.Platform$OS.type == "unix") {
        hosts <- system("hostname -A", intern = TRUE)
        hosts <- tolower(strsplit(hosts, " ")[[1]])
    } else if (.Platform$OS.type == "windows") {
        hosts <- tolower(paste0(Sys.getenv("COMPUTERNAME"), ".",
                       Sys.getenv("USERDNSDOMAIN")))
    } else {
        stop("Not support")
    }
    hosts
}

.is_local <- function(h) {
    hosts <- .hostname()
    if (h %in% hosts) {
        return(TRUE)
    }
    return(FALSE)
}

.check_arg_name <- function(arguments) {
    if (is.null(arguments) || length(arguments) == 0) {
        return(invisible())
    }
    n_arguments <- names(arguments)
    if (sum(is.null(n_arguments)) > 0 || sum(nchar(n_arguments) == 0)) {
        stop("All arguments should be names")
    }
}


.sys_now <- function() {
    format(Sys.time(), "%Y-%m-%d %H:%M:%S")
}

.cmd_remote <- function(host, username, cmd) {
    if (!is.null(username)) {
        host <- paste0(stringr::str_trim(username), "@", host)
    }
    if (!.is_local(host)) {
        if (.is_bin_on_path("ssh")) {
            cmd <- sprintf("ssh %s '%s'",
                           host, cmd)
        } else {
            stop("Cannot find ssh command")
        }
    }
    cmd
}
