
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
            username character(255) COLLATE pg_catalog.\"default\",
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

#' List All Computing Resources
#'
#' Retrieves all computing resources registered in the database.
#'
#' @return A data frame containing information about all resources, with columns:
#'   \item{id}{Unique resource identifier}
#'   \item{name}{Resource name}
#'   \item{type}{Resource type (e.g., "slurm", "computer")}
#'   \item{host}{Hostname or IP address}
#'   \item{username}{Username for SSH connection}
#'   \item{nodename}{Node name as reported by Sys.info()}
#'   \item{workers}{Maximum number of concurrent workers}
#'   \item{log_folder}{Absolute path to log file directory}
#'
#' @seealso \code{\link{resource_add}}, \code{\link{resource_get}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # List all resources
#' resources <- resource_list()
#' print(resources)
#'
#' # Find SLURM resources
#' slurm_resources <- resources[resources$type == "slurm", ]
#' }
#' @export
resource_list <- function() {
    sql <- "SELECT * FROM resource where TRUE"
    con <- db_connect()
    resources <- DBI::dbGetQuery(con, sql)
    db_disconnect(con)
    resources
}

#' Get Information for a Specific Resource
#'
#' Retrieves detailed information about a single computing resource by name.
#'
#' @param resource Character string specifying the resource name.
#' @param con An optional database connection. If NULL, a new connection is created
#'   and closed automatically.
#'
#' @return A single-row data frame containing resource information. Stops with
#'   an error if the resource is not found.
#'
#' @details
#' The returned data frame contains all resource configuration details needed
#' for worker deployment, including connection information and resource limits.
#'
#' @seealso \code{\link{resource_add}}, \code{\link{resource_list}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Get specific resource
#' hpc_info <- resource_get("hpc")
#' print(hpc_info$workers)  # Maximum workers
#' print(hpc_info$log_folder)  # Log directory
#' }
#' @export
resource_get <- function(resource, con = NULL) {
    sql <- sprintf("SELECT * from resource where name='%s'", resource)
    r <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(r) == 0) {
        stop("Cannot find resource: ", resource)
    }
    r
}


#' Add a New Computing Resource
#'
#' Registers a new computing resource (HPC cluster or computer) in the database
#' for use with taskqueue projects.
#'
#' @param name Character string for the resource name. Must be unique.
#' @param type Type of resource. Currently supported: \code{"slurm"} for SLURM
#'   clusters or \code{"computer"} for standalone machines.
#' @param host Hostname or IP address of the resource. For SLURM clusters,
#'   this should be the login/head node.
#' @param workers Maximum number of concurrent workers/cores available on this
#'   resource (integer).
#' @param log_folder Absolute path to the directory where log files will be stored.
#'   Must be an absolute path (Linux or Windows format). Directory will contain
#'   subdirectories for each project.
#' @param username Username for SSH connection to the resource. If NULL (default),
#'   uses the current user from \code{Sys.info()["user"]}.
#' @param nodename Node name as obtained by \code{Sys.info()["nodename"]} on the
#'   resource. Default extracts the hostname from \code{host}.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (adding resource to database).
#'
#' @details
#' The \code{log_folder} is critical for troubleshooting. It stores:
#' \itemize{
#'   \item SLURM job output and error files
#'   \item Task execution logs
#'   \item R worker scripts
#' }
#'
#' Choose a high-speed storage location if possible due to frequent I/O operations.
#'
#' If a resource with the same \code{name} already exists, this function will
#' fail due to uniqueness constraints.
#'
#' @seealso \code{\link{resource_get}}, \code{\link{resource_list}},
#'   \code{\link{project_resource_add}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Add a SLURM cluster resource
#' resource_add(
#'   name = "hpc",
#'   type = "slurm",
#'   host = "hpc.university.edu",
#'   workers = 500,
#'   log_folder = "/home/user/taskqueue_logs/"
#' )
#'
#' # Add with explicit username
#' resource_add(
#'   name = "hpc2",
#'   type = "slurm",
#'   host = "cluster.lab.org",
#'   workers = 200,
#'   log_folder = "/scratch/taskqueue/logs/",
#'   username = "johndoe"
#' )
#'
#' # Verify resource was added
#' resource_list()
#' }
#' @export
resource_add <- function(name,
                         type = c("slurm", "computer"),
                         host,
                         workers,
                         log_folder,
                         username = NULL,
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
    if (!is.null(username)) {
        stopifnot(length(username) == 1)
        stopifnot(is.character(username))
    } else {
        username <- Sys.info()[["user"]]
    }
    stopifnot(workers > 0)
    match.arg(type)

    if (!(.check_windows_absolute_path(log_folder) |
        .check_linux_absolute_path(log_folder))) {
        stop("Require an absolute path for windows or linux as log_folder: ",
             log_folder)
    }

    if (!dir.exists(log_folder)) {
        dir.create(log_folder, recursive = TRUE)
        # warning("Cannot find folder in the local computer.",
        #         " Please make sure the log_folder is existed and accessable in the target host.")
    }
    .table_resource(con)
    if (!is.null(username)) {
        sql <- sprintf("INSERT INTO resource
                          (name, type, host, username, nodename, workers, log_folder)
                   VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s')
                   ON CONFLICT ON CONSTRAINT resource_unique_name
                   DO UPDATE SET type='%s', host='%s', username='%s',
                   nodename='%s', workers='%s',
                   log_folder='%s';",
                   name, type, host, username, nodename, workers, log_folder,
                   type, host, username, nodename, workers, log_folder)
    } else {
        sql <- sprintf("INSERT INTO resource
                          (name, type, host, nodename, workers, log_folder)
                   VALUES ('%s', '%s', '%s', '%s', '%s', '%s')
                   ON CONFLICT ON CONSTRAINT resource_unique_name
                   DO UPDATE SET type='%s', host='%s',
                   nodename='%s', workers='%s',
                   log_folder='%s';",
                       name, type, host, nodename, workers, log_folder,
                       type, host, nodename, workers, log_folder)
    }
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}
