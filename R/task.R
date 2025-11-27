# function related with tasks

#' Add Tasks to a Project
#'
#' Creates a specified number of tasks in a project's task table. Each task
#' is assigned a unique ID and initially has idle (NULL) status.
#'
#' @param project Character string specifying the project name.
#' @param num Integer specifying the number of tasks to create.
#' @param clean Logical indicating whether to delete existing tasks before adding
#'   new ones. Default is TRUE.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (adding tasks to database).
#'
#' @details
#' Tasks are created with sequential IDs from 1 to \code{num}. Each task initially
#' has NULL status (idle) and will be assigned to workers after the project is started.
#'
#' If \code{clean = TRUE}, all existing tasks are removed using \code{\link{task_clean}}
#' before adding new tasks. If FALSE, new tasks are added but existing tasks remain
#' (duplicates are ignored due to primary key constraints).
#'
#' Your worker function will receive the task ID as its first argument.
#'
#' @seealso \code{\link{task_clean}}, \code{\link{task_status}},
#'   \code{\link{worker}}, \code{\link{project_start}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Add 100 tasks to a project
#' task_add("simulation_study", num = 100)
#'
#' # Add tasks without cleaning existing ones
#' task_add("simulation_study", num = 50, clean = FALSE)
#'
#' # Check task status
#' task_status("simulation_study")
#' }
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


#' Remove All Tasks from a Project
#'
#' Deletes all tasks from a project's task table. This is a destructive
#' operation that removes all task data and history.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (truncating task table).
#'
#' @details
#' Uses SQL TRUNCATE to efficiently remove all rows from the task table.
#' This is faster than DELETE but cannot be rolled back.
#'
#' \strong{Warning:} All task history, including completion status and runtime
#' information, will be permanently lost.
#'
#' This function is automatically called by \code{\link{task_add}} when
#' \code{clean = TRUE}.
#'
#' @seealso \code{\link{task_add}}, \code{\link{task_reset}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Remove all tasks
#' task_clean("simulation_study")
#'
#' # Add new tasks
#' task_add("simulation_study", num = 200)
#' }
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


#' Get Task Status Summary
#'
#' Returns a summary table showing the number and proportion of tasks in each
#' status for a project.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return A data frame with one row per status, containing:
#'   \item{status}{Task status: "idle", "working", "finished", or "failed"}
#'   \item{count}{Number of tasks with this status (integer)}
#'   \item{ratio}{Proportion of tasks with this status (numeric)}
#'
#' @details
#' Task statuses:
#' \itemize{
#'   \item \strong{idle} (NULL in database): Task not yet started
#'   \item \strong{working}: Task currently being processed by a worker
#'   \item \strong{finished}: Task completed successfully
#'   \item \strong{failed}: Task encountered an error
#' }
#'
#' Use this function to monitor progress and identify problems.
#'
#' @seealso \code{\link{task_get}}, \code{\link{task_reset}},
#'   \code{\link{project_status}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Check task status
#' status <- task_status("simulation_study")
#' print(status)
#'
#' # Calculate completion percentage
#' finished <- status$count[status$status == "finished"]
#' total <- sum(status$count)
#' pct_complete <- 100 * finished / total
#' }
#' @export
task_status <- function(project, con = NULL) {
    sql <- sprintf("SELECT status, COUNT(*) FROM task_%s GROUP BY status", project)
    res <- db_sql(sql, DBI::dbGetQuery, con)
    res$status <- ifelse(is.na(res$status), "idle", res$status)
    res$count <- as.integer(res$count)
    res$ratio <- res$count / sum(res$count)
    return(res)
}




#' Reset Task Status to Idle
#'
#' Resets tasks with specified statuses back to idle (NULL) state, clearing
#' their execution history. This allows them to be picked up by workers again.
#'
#' @param project Character string specifying the project name.
#' @param status Character vector of statuses to reset. Can include "working",
#'   "failed", "finished", or "all". Default is c("working", "failed").
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (resetting task status).
#'
#' @details
#' Resetting tasks clears:
#' \itemize{
#'   \item Status (set to NULL/idle)
#'   \item Start time
#'   \item Finish time
#'   \item Error messages
#' }
#'
#' Common use cases:
#' \itemize{
#'   \item Reset failed tasks after fixing code: \code{status = "failed"}
#'   \item Reset interrupted tasks: \code{status = "working"}
#'   \item Re-run everything: \code{status = "all"}
#' }
#'
#' Specifying \code{status = "all"} resets all tasks regardless of current status.
#'
#' @seealso \code{\link{task_status}}, \code{\link{task_add}},
#'   \code{\link{project_reset}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Reset only failed tasks
#' task_reset("simulation_study", status = "failed")
#'
#' # Reset working tasks (e.g., after project_stop)
#' task_reset("simulation_study", status = "working")
#'
#' # Reset all tasks to start over
#' task_reset("simulation_study", status = "all")
#'
#' # Check status after reset
#' task_status("simulation_study")
#' }
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

#' Get Detailed Task Information
#'
#' Retrieves detailed information about tasks with specified statuses, including
#' execution times and error messages.
#'
#' @param project Character string specifying the project name.
#' @param status Character vector of statuses to retrieve. Can include "working",
#'   "failed", "finished", or "all". Default is "failed".
#' @param limit Maximum number of tasks to return (integer). Default is 10.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return A data frame with detailed task information:
#'   \item{id}{Task ID}
#'   \item{status}{Current status}
#'   \item{start}{Start timestamp}
#'   \item{finish}{Finish timestamp}
#'   \item{message}{Error message (for failed tasks) or NULL}
#'   \item{runtime}{Calculated runtime in seconds}
#'
#' @details
#' Useful for:
#' \itemize{
#'   \item Debugging failed tasks (examine error messages)
#'   \item Analyzing runtime patterns
#'   \item Identifying slow tasks
#' }
#'
#' The \code{runtime} column is calculated as the difference between finish and
#' start times in seconds.
#'
#' Specifying \code{status = "all"} returns tasks of any status.
#'
#' @seealso \code{\link{task_status}}, \code{\link{task_reset}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Get first 10 failed tasks
#' failed <- task_get("simulation_study", status = "failed")
#' print(failed$message)  # View error messages
#'
#' # Get all finished tasks
#' finished <- task_get("simulation_study", status = "finished", limit = 1000)
#' hist(finished$runtime, main = "Task Runtime Distribution")
#'
#' # Get tasks of any status
#' all_tasks <- task_get("simulation_study", status = "all", limit = 50)
#' }
#' @export
task_get <- function(project, status = c("failed"), limit = 10, con = NULL) {
    stopifnot(is.numeric(limit))
    if (length(limit) != 1) {
        stop("limit should be single value")
    }

    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)
    if (new_connection) {
        on.exit(db_disconnect(con), add = TRUE)
    }
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
