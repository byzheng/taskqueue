

# Variable, global to package's namespace.
# This function is not exported to user space and does not need to be documented.
TASKQUEUE_OPTIONS <- settings::options_manager(
    host = Sys.getenv("PGHOST"),
    port = Sys.getenv("PGPORT"),
    user = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    database = Sys.getenv("PGDATABASE")
    )


#' Set or get options for my package
#'
#' @param ... Option names to retrieve option values or \code{[key]=[value]} pairs to set options.
#'
#' @section Supported options:
#' The following options are supported
#' \itemize{
#'  \item{\code{host}}{host of postgreSQL database}
#'  \item{\code{port}}{port of postgreSQL database}
#'  \item{\code{user}}{user name of postgreSQL database}
#'  \item{\code{password}}{pasword of postgreSQL database}
#'  \item{\code{database}}{database name of postgreSQL database}
#' }
#'
#' @export
#' @return Options for task queue
taskqueue_options <- function(...){
    # protect against the use of reserved words.
    settings::stop_if_reserved(...)
    args <- list(...)
    if (sum(nchar(names(args)) == 0) > 0) {
        stop("all arguments should be named")
    }

    TASKQUEUE_OPTIONS(...)
}

#' Reset global options for pkg
#'
#' @export
#' @return no return
taskqueue_reset <- function() {
    settings::reset(TASKQUEUE_OPTIONS)
}
