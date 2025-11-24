

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
#' \itemize{
#'   \item \code{host}: Host of PostgreSQL database
#'   \item \code{port}: Port of PostgreSQL database
#'   \item \code{user}: User name of PostgreSQL database
#'   \item \code{password}: Password of PostgreSQL database
#'   \item \code{database}: Database name of PostgreSQL database
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
