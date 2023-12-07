# function related with tasks

#' Add tasks into a project
#'
#' @param project project name
#' @param num number of tasks
#' @param clean whether to clean existing tasks
#' @param con a connection to database
#'
#' @return no return
#' @export
task_add <- function(project, num, clean = TRUE, con = NULL) {
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    values <- paste(paste("(", seq_len(num), ")", sep = ""), collapse = ", ")
    sql <- sprintf("
        INSERT INTO task_%s
        (id) VALUES %s
        ON CONFLICT DO NOTHING
    ;", project, values)
    con <- db_connect(con)
    if (clean) {
        task_clean(project, con)
    }
    DBI::dbExecute(con, sql)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}


#' Clear all tasks in a project
#'
#' @param project project name
#' @param con a connection to database
#'
#' @return no return
#' @export
task_clean <- function(project, con = NULL) {
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    sql <- sprintf("TRUNCATE TABLE task_%s;", project)
    con <- db_connect(con)
    DBI::dbExecute(con, sql)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}


#' Get task status in a project
#'
#' @param project project name
#' @param con a connection to database
#'
#' @return a table to show task status
#' @export
task_status <- function(project, con = NULL) {
    sql <- sprintf("SELECT status, COUNT(*) FROM task_%s GROUP BY status", project)
    res <- db_sql(sql, DBI::dbGetQuery, con)
    res$status <- ifelse(is.na(res$status), "idle", res$status)
    return(res)
}

