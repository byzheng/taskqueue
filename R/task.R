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
    res$ratio <- res$count / sum(res$count)
    return(res)
}




#' Reset status of all tasks in a project to NULL
#'
#' @param project project name
#' @param status status to reset (e.g. working, failed, or all), all tasks if status = all
#' @param con connection to database
#'
#' @return no return
#' @export
task_reset <- function(project, status = c("working", "failed"), con = NULL) {
    if ("all" %in% status) {
        status <- c("working", "failed", "finished")
    }
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)

    sql <- "SELECT unnest(enum_range(NULL::task_status));"
    define_status <- db_sql(sql, DBI::dbGetQuery, con)
    pos <- !(status %in% define_status$unnest)
    if (sum(pos) > 0) {
        stop("Cannot find status: ", paste(status[pos], sep = ", "))
    }
    status_sql <- paste(paste0("'", status, "'"), collapse = ", ")
    sql <- sprintf("UPDATE task_%s
                   SET status=NULL,
                       start=NULL,
                       finish=NULL,
                       message=NULL
                   WHERE status in (%s);",
                   project, status_sql)
    a <- db_sql(sql, DBI::dbExecute, con)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}

#' Get tasks by status
#'
#' @param project project name
#' @param status status to reset (e.g. working, failed, or all), all tasks if status = all
#' @param limit number of rows to return
#' @param con connection to database
#'
#' @return A data frame of tasks
#' @export
task_get <- function(project, status = c("failed"), limit = 10, con = NULL) {
    stopifnot(is.numeric(limit))
    if (length(limit) != 1) {
        stop("limit should be single value")
    }

    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)

    if ("all" %in% status) {
        status_sql <- "true"
    } else {
        sql <- "SELECT unnest(enum_range(NULL::task_status));"
        define_status <- db_sql(sql, DBI::dbGetQuery, con)
        pos <- !(status %in% define_status$unnest )
        if (sum(pos) > 0) {
            stop("Cannot find status: ", paste(status[pos], sep = ", "))
        }
        status_sql <- paste0("status in (", paste(paste0("'", status, "'"), collapse = ", "), ")")
    }
    sql <- sprintf("SELECT * FROM task_%s WHERE %s LIMIT %s;",
                   project, status_sql, limit)
    a <- db_sql(sql, DBI::dbGetQuery, con)

    if (new_connection) {
        db_disconnect(con)
    }
    a$runtime <- (as.numeric(a$finish) - as.numeric(a$start))
    a
}
