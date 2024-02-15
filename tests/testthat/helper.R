

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
    if (opt$user != "cluster_test" || opt$database != "cluster_test") {
        return(FALSE)
    }
    x <- try({
        con <- db_connect()
        on.exit(db_disconnect(con), add = TRUE)
    })
    if (inherits(x, "try-error")) {
        return(FALSE)
    }
    return(TRUE)
}
