

#' Test whether db can be connected
#'
#' @return TRUE if test db is available.
#' @export
is_test_db <- function() {
    taskqueue_options(host = Sys.getenv("PGTESTHOST"),
                      port = Sys.getenv("PGTESTPORT"),
                      user = Sys.getenv("PGTESTUSER"),
                      password = Sys.getenv("PGTESTPASSWORD"),
                      database = Sys.getenv("PGTESTDATABASE"))
    opt <- taskqueue_options()
    stopifnot(opt$user == "cluster_test")
    stopifnot(opt$database == "cluster_test")
    x <- try({
        con <- db_connect()
        on.exit(db_disconnect(con), add = TRUE)
    })
    if (inherits(x, "try-error")) {
        return(FALSE)
    }
    return(TRUE)
}
