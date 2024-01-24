
# Projects

# Create resource table if not exist
.table_resource <- function(con = NULL) {
    sql <- c("
        CREATE TABLE IF NOT EXISTS public.resource
        (
            id SERIAL NOT NULL,
            name character varying COLLATE pg_catalog.\"default\" NOT NULL,
            type character varying COLLATE pg_catalog.\"default\" NOT NULL,
            host character varying COLLATE pg_catalog.\"default\" NOT NULL,
            nodename character varying COLLATE pg_catalog.\"default\" NOT NULL,
            workers integer NOT NULL,
            log_folder character varying COLLATE pg_catalog.\"default\",
            CONSTRAINT resource_pkey PRIMARY KEY (id),
            CONSTRAINT resource_unique_name UNIQUE (name),
            CONSTRAINT resource_unique_host UNIQUE (host),
            CONSTRAINT resource_unique_namename UNIQUE (nodename)
        );")
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}

#' Get all resource
#'
#' @return a data frame for all resources
#' @export
resource_list <- function() {
    sql <- "SELECT * FROM resource where TRUE"
    con <- db_connect()
    resources <- DBI::dbGetQuery(con, sql)
    db_disconnect(con)
    resources
}

#' Get a resource
#'
#' @param resource resource name
#' @param con a db connection
#'
#' @return a data frame for selected resource
#' @export
resource_get <- function(resource, con = NULL) {
    sql <- sprintf("SELECT * from resource where name='%s'", resource)
    r <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(r) == 0) {
        stop("Cannot find resource: ", resource)
    }
    r
}


#' Add a new resource
#'
#' @param name resource name
#' @param type resource type (e.g. slurm or computer)
#' @param host host name
#' @param workers worker number
#' @param log_folder log folder which has to be absolute path.
#' @param nodename nodename obtained by Sys.info()
#' @param con a db connection
#'
#' @return no return
#' @export
resource_add <- function(name,
                         type = c("slurm", "computer"),
                         host,
                         workers,
                         log_folder,
                         nodename = strsplit(host, "\\.")[[1]][1],
                         con = NULL)
{
    # Check argument

    stopifnot(length(name) == 1)
    stopifnot(length(type) == 1)
    stopifnot(length(host) == 1)
    stopifnot(length(log_folder) == 1)
    stopifnot(length(workers) == 1)
    stopifnot(is.character(name))
    stopifnot(is.character(type))
    stopifnot(is.character(host))
    stopifnot(is.character(log_folder))
    stopifnot(is.numeric(workers))
    stopifnot(workers > 0)
    match.arg(type)

    if (!(.check_windows_absolute_path(log_folder) |
        .check_linux_absolute_path(log_folder))) {
        stop("Require an absolute path for windows or linux as log_folder: ",
             log_folder)
    }

    if (!dir.exists(log_folder)) {
        warning("Cannot find folder in the local computer.",
                " Please make sure the log_folder is existed and accessable in the target host.")
    }
    .table_resource(con)
    sql <- sprintf("INSERT INTO resource
                          (name, type, host, nodename, workers, log_folder)
                   VALUES ('%s', '%s', '%s', '%s', '%s', '%s')
                   ON CONFLICT ON CONSTRAINT resource_unique_name
                   DO UPDATE SET type='%s', host='%s',
                   nodename='%s', workers='%s',
                   log_folder='%s';",
                   name, type, host, nodename, workers, log_folder,
                   type, host, nodename, workers, log_folder)
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}
