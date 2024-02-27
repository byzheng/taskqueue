# define global variables
test_project <- "test_project"
test_resource <- "localhost"
test_slurm_resource <- "slurm"

#' Test whether db can be connected
#'
#' @return TRUE if test db is available.
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


#' Whether to test slurm workers
#'
#' @return TRUE if slurm workers can be tested
is_slurm <- function() {
    host <- Sys.getenv("PGTESTSLURMHOST")
    log <- Sys.getenv("PGTESTSLURMLOG")
    account <- Sys.getenv("PGTESTSLURMACCOUNT")
    working <- Sys.getenv("PGTESTSLURMWORKING")

    if (nchar(host) == 0 || nchar(log) == 0 || nchar(account) == 0 || nchar(working) == 0) {
        return(FALSE)
    }
    return(TRUE)
}
