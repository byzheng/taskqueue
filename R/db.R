
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

db_sql <- function(sql, method, con = NULL) {

    reconnect <- is.null(con)
    if (reconnect) {
        con <- db_connect()
    }
    p <- method(con, sql)
    if (reconnect) {
        db_disconnect(con)
    }
    p
}
