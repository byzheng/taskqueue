
#' Connect to postgreSQL db
#'
#' @param con An existing connection. Return the existing connection if not null
#' @return a connection object as produced by dbConnect
#' @examples
#' \dontrun{
#' con <- db_connect()
#' }
#' @export
db_connect <- function(con = NULL)
{
    # Check existing connection
    if (!is.null(con)) {
        con_class <- class(con)
        if (con_class == "PqConnection" && attr(con_class, "package") == "RPostgres") {
            return(con)
        }
    }
    con <- DBI::dbConnect(
        RPostgres::Postgres(),
        dbname = SCHEDULE_OPTIONS("database"),
        host = SCHEDULE_OPTIONS("host"),
        port = SCHEDULE_OPTIONS("port"),
        user = SCHEDULE_OPTIONS("user"),
        password = SCHEDULE_OPTIONS("password"))
    DBI::dbExecute(con, "set client_min_messages to WARNING")
    return(con)
}

#' Disconnect to db
#' @param con a connection object as produced by dbConnect.
#' @examples
#' \dontrun{
#' con <- db_disconnect()
#' dbDisconnect(con)
#' }
#' @return no return values
#' @export
db_disconnect <- function(con)
{
    invisible(RPostgres::dbDisconnect(con))
}

#' Initialize PostgreSQL database for taskqueue
#'
#' @return no return
#' @export
db_init <- function() {
    con <- db_connect()
    .types(con)
    .table_project(con)
    .table_resource(con)
    .table_project_resource(con)
    db_disconnect(con)
    return(invisible())
}

#' Clean all tables and definition
#'
#' @return No return
db_clean <- function() {
    con <- db_connect()
    # Delete project tables
    projects <- project_list(con)
    for (i in seq(along = projects[[1]])) {
        sql <- sprintf("DROP TABLE IF EXISTS public.%s", projects$table[i])
        a <- db_sql(sql, DBI::dbExecute, con)
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

    db_disconnect(con)
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
    }
    for (i in seq(along = sql)) {
        p <- method(con, sql[i])
    }
    if (reconnect) {
        db_disconnect(con)
    }
    p
}


