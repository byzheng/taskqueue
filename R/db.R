
#' Connect to PostgreSQL Database
#'
#' Establishes a connection to the PostgreSQL database using credentials from
#' environment variables or \code{taskqueue_options()}. If a valid connection
#' is provided, it returns that connection instead of creating a new one.
#'
#' @param con An existing database connection object. If provided and valid,
#'   this connection is returned. If NULL (default), a new connection is created.
#'
#' @return A PqConnection object from the RPostgres package that can be used
#'   for database operations.
#'
#' @details
#' Connection parameters are read from environment variables set in \code{.Renviron}:
#' \itemize{
#'   \item \code{PGHOST}: Database server hostname
#'   \item \code{PGPORT}: Database server port (typically 5432)
#'   \item \code{PGUSER}: Database username
#'   \item \code{PGPASSWORD}: Database password
#'   \item \code{PGDATABASE}: Database name
#' }
#'
#' The function automatically sets \code{client_min_messages} to WARNING to
#' reduce console output noise.
#'
#' @seealso \code{\link{db_disconnect}}, \code{\link{taskqueue_options}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Create a new connection
#' con <- db_connect()
#'
#' # Reuse existing connection
#' con2 <- db_connect(con)
#'
#' # Always disconnect when done
#' db_disconnect(con)
#' }
#' @export
db_connect <- function(con = NULL) {
    # Check existing connection
    if (!is.null(con)) {
        con_class <- class(con)
        if (con_class == "PqConnection" && attr(con_class, "package") == "RPostgres") {
            return(con)
        }
    }
    con <- DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = TASKQUEUE_OPTIONS("database"),
        host = TASKQUEUE_OPTIONS("host"),
        port = TASKQUEUE_OPTIONS("port"),
        user = TASKQUEUE_OPTIONS("user"),
        password = TASKQUEUE_OPTIONS("password"))
    DBI::dbExecute(con, "set client_min_messages to WARNING")
    return(con)
}

#' Disconnect from PostgreSQL Database
#'
#' Safely closes a database connection. Checks if the connection is valid
#' before attempting to disconnect.
#'
#' @param con A connection object as produced by \code{\link{db_connect}} or
#'   \code{DBI::dbConnect}.
#'
#' @return Invisibly returns NULL. Called for side effects.
#'
#' @details
#' This function wraps \code{RPostgres::dbDisconnect()} with a validity check
#' to avoid errors when disconnecting an already-closed connection.
#'
#' @seealso \code{\link{db_connect}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Connect and disconnect
#' con <- db_connect()
#' # ... perform database operations ...
#' db_disconnect(con)
#'
#' # Safe to call on.exit to ensure cleanup
#' con <- db_connect()
#' on.exit(db_disconnect(con), add = TRUE)
#' }
#' @export
db_disconnect <- function(con) {
    if (DBI::dbIsValid(con)) {
        invisible(RPostgres::dbDisconnect(con))
    }
    return(invisible())
}

#' Initialize PostgreSQL Database for taskqueue
#'
#' Creates the necessary database schema for taskqueue, including all required
#' tables, types, and constraints. This function must be run once before using
#' taskqueue for the first time.
#'
#' @return Invisibly returns NULL. Called for side effects (creating database schema).
#'
#' @details
#' This function creates:
#' \itemize{
#'   \item Custom PostgreSQL types (e.g., \code{task_status} enum)
#'   \item \code{project} table for managing projects
#'   \item \code{resource} table for computing resources
#'   \item \code{project_resource} table for project-resource associations
#' }
#'
#' It is safe to call this function multiple times; existing tables and types
#' will not be modified or deleted.
#'
#' @seealso \code{\link{db_clean}}, \code{\link{db_connect}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Initialize database (run once)
#' db_init()
#'
#' # Verify initialization
#' con <- db_connect()
#' DBI::dbListTables(con)
#' db_disconnect(con)
#' }
#' @export
db_init <- function() {
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    .types(con)
    .table_project(con)
    .table_resource(con)
    .table_project_resource(con)
    return(invisible())
}

#' Clean All Tables and Definitions from Database
#'
#' Removes all taskqueue-related tables, types, and data from the PostgreSQL
#' database. This is a destructive operation that cannot be undone.
#'
#' @return Invisibly returns NULL. Called for side effects (dropping database objects).
#'
#' @details
#' This function drops:
#' \itemize{
#'   \item All project task tables
#'   \item The \code{project_resource} table
#'   \item The \code{project} table
#'   \item The \code{resource} table
#'   \item All custom types (e.g., \code{task_status})
#' }
#'
#' \strong{Warning:} This permanently deletes all projects, tasks, and configurations.
#' Use with extreme caution, typically only for testing or complete resets.
#'
#' After cleaning, you must call \code{\link{db_init}} to recreate the schema
#' before using taskqueue again.
#'
#' @seealso \code{\link{db_init}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Clean entire database (destructive!)
#' db_clean()
#'
#' # Reinitialize after cleaning
#' db_init()
#' }
#' @export
db_clean <- function() {
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    # Delete project tables
    projects <- project_list(con)
    if (!is.null(projects)) {
        for (i in seq(along = projects[[1]])) {
            sql <- sprintf("DROP TABLE IF EXISTS public.%s", projects$table[i])
            a <- db_sql(sql, DBI::dbExecute, con)
        }
    }
    # Delete project resource
    sql <- "DROP TABLE IF EXISTS public.project_resource"
    a <- db_sql(sql, DBI::dbExecute, con)

    # Delete project
    sql <- "DROP TABLE IF EXISTS public.project"
    a <- db_sql(sql, DBI::dbExecute, con)
    # Delete resource
    sql <- "DROP TABLE IF EXISTS public.resource"
    a <- db_sql(sql, DBI::dbExecute, con)

    # Delete any other tables
    sql <- "select * from information_schema.tables where table_schema='public'"
    tables <- db_sql(sql, DBI::dbGetQuery, con)

    for (i in seq(along = tables$table_name)) {
        sql <- sprintf("DROP TABLE IF EXISTS public.%s", tables$table_name[i])
        a <- db_sql(sql, DBI::dbExecute, con)
    }
    # delete types
    sql <- "DROP TYPE IF EXISTS public.task_status;"
    a <- db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}


#' A Wrapper function for DBI interface
#'
#' @param sql multile sql statements
#' @param method method of DBI
#' @param con a connection
#'
#' @return Results of last sql statement with method for DBI interface
db_sql <- function(sql, method, con = NULL) {

    reconnect <- is.null(con)
    if (reconnect) {
        con <- db_connect()
        on.exit(db_disconnect(con), add = TRUE)
    }
    for (i in seq(along = sql)) {
        p <- method(con, sql[i])
    }
    p
}



#' Check whether a table is existed
#'
#' @param table table name
#' @param con a connection
#'
#' @return logical value
table_exist <- function(table, con = NULL) {
    stopifnot(length(table) == 1)
    sql <- sprintf("SELECT EXISTS (
        SELECT 1
        FROM pg_tables
        WHERE schemaname = 'public'
        AND tablename = '%s'
    );", table)
    as.logical(db_sql(sql, DBI::dbGetQuery, con = con))
}




#' Test Database Connection
#'
#' Checks whether a connection to the PostgreSQL database can be established
#' with the current configuration.
#'
#' @return Logical. \code{TRUE} if the database can be connected successfully,
#'   \code{FALSE} otherwise.
#'
#' @details
#' This function attempts to create a database connection using the credentials
#' in environment variables or \code{taskqueue_options()}. It returns FALSE if
#' the connection fails for any reason (wrong credentials, network issues,
#' PostgreSQL not running, etc.).
#'
#' Useful for testing database configuration before running workers or adding tasks.
#'
#' @seealso \code{\link{db_connect}}, \code{\link{taskqueue_options}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Test connection
#' if (is_db_connect()) {
#'   message("Database is accessible")
#'   db_init()
#' } else {
#'   stop("Cannot connect to database. Check .Renviron settings.")
#' }
#' }
#' @export
is_db_connect <- function() {
    x <- try({
        con <- db_connect()
        on.exit(db_disconnect(con), add = TRUE)
    })
    if (inherits(x, "try-error")) {
        return(FALSE)
    }
    return(TRUE)
}
