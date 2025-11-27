

# Variable, global to package's namespace.
# This function is not exported to user space and does not need to be documented.
TASKQUEUE_OPTIONS <- settings::options_manager(
    host = Sys.getenv("PGHOST"),
    port = Sys.getenv("PGPORT"),
    user = Sys.getenv("PGUSER"),
    password = Sys.getenv("PGPASSWORD"),
    database = Sys.getenv("PGDATABASE")
    )


#' Set or Get taskqueue Options
#'
#' Configure or retrieve database connection parameters for taskqueue.
#' Options are typically set via environment variables in \code{.Renviron},
#' but can be overridden programmatically.
#'
#' @param ... Option names to retrieve values (as strings), or key=value pairs
#'   to set options. All option names must be specified.
#'
#' @section Supported options:
#' \describe{
#'   \item{host}{PostgreSQL server hostname or IP address (from PGHOST)}
#'   \item{port}{PostgreSQL server port, typically 5432 (from PGPORT)}
#'   \item{user}{Database username (from PGUSER)}
#'   \item{password}{Database password (from PGPASSWORD)}
#'   \item{database}{Database name (from PGDATABASE)}
#' }
#'
#' @return If no arguments: list of all option values.  
#'   If argument names only: list of specified option values.  
#'   If setting values: invisibly returns updated options.
#'
#' @details
#' By default, options are read from environment variables set in \code{~/.Renviron}.
#' Use this function to override defaults temporarily or check current settings.
#'
#' Changes are session-specific and don't modify environment variables.
#'
#' @seealso \code{\link{taskqueue_reset}}, \code{\link{db_connect}}
#'
#' @examples
#' # View all current options
#' taskqueue_options()
#'
#' # Get specific option
#' taskqueue_options("host")
#'
#' # Set options (temporary override)
#' taskqueue_options(host = "localhost", port = 5432)
#'
#' # Reset to environment variable values
#' taskqueue_reset()
#' @export
taskqueue_options <- function(...){
    # protect against the use of reserved words.
    settings::stop_if_reserved(...)
    args <- list(...)
    if (sum(nchar(names(args)) == 0) > 0) {
        stop("all arguments should be named")
    }

    TASKQUEUE_OPTIONS(...)
}

#' Reset taskqueue Options to Defaults
#'
#' Resets all taskqueue options to their default values from environment variables.
#'
#' @return Invisibly returns NULL. Called for side effects (resetting options).
#'
#' @details
#' This function restores options to the values specified in environment variables
#' (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE). Any programmatic changes
#' made via \code{\link{taskqueue_options}} are discarded.
#'
#' Useful after temporarily modifying connection parameters.
#'
#' @seealso \code{\link{taskqueue_options}}
#'
#' @examples
#' # Override options temporarily
#' taskqueue_options(host = "test.server.com")
#'
#' # Reset to environment variable values
#' taskqueue_reset()
#' @export
taskqueue_reset <- function() {
    settings::reset(TASKQUEUE_OPTIONS)
}
