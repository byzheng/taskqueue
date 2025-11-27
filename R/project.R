
# Projects
# Create types
.types <- function(con = NULL) {

    sql <- "SELECT * FROM pg_type WHERE typname = 'task_status'"
    status_types <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(status_types) == 0) {
        sql <- "CREATE TYPE task_status AS ENUM ('working', 'finished', 'failed');"
        db_sql(sql, DBI::dbExecute, con)
    }
}
# Create project table if not exist
.table_project <- function(con = NULL) {
    sql <- c("
        CREATE TABLE IF NOT EXISTS public.project
        (
            id SERIAL NOT NULL,
            name character varying COLLATE pg_catalog.\"default\" NOT NULL,
            \"table\" character varying COLLATE pg_catalog.\"default\" NOT NULL,
            status boolean,
            memory integer NOT NULL DEFAULT 10,
            CONSTRAINT project_pkey PRIMARY KEY (id),
            CONSTRAINT project_unique_name UNIQUE (name)
        );",
        "COMMENT ON COLUMN public.project.memory
            IS 'Memory requirement in GB';
    ")
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}


#' Create a New Project
#'
#' Creates a new project in the database for managing a set of related tasks.
#' Each project has its own task table and configuration.
#'
#' @param project Character string for the project name. Must be unique and
#'   cannot be a reserved name (e.g., "config").
#' @param memory Memory requirement in gigabytes (GB) for each task in this
#'   project. Default is 10 GB.
#'
#' @return Invisibly returns NULL. Called for side effects (creating project in database).
#'
#' @details
#' This function:
#' \itemize{
#'   \item Creates a new entry in the \code{project} table
#'   \item Creates a dedicated task table named \code{task_<project>}
#'   \item Sets default memory requirements for all tasks
#' }
#'
#' If a project with the same name already exists, the memory requirement is
#' updated but the task table remains unchanged.
#'
#' After creating a project, you must:
#' \enumerate{
#'   \item Assign resources with \code{\link{project_resource_add}}
#'   \item Add tasks with \code{\link{task_add}}
#'   \item Start the project with \code{\link{project_start}}
#' }
#'
#' @seealso \code{\link{project_start}}, \code{\link{project_resource_add}},
#'   \code{\link{task_add}}, \code{\link{project_delete}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Create a project with default memory
#' project_add("simulation_study")
#'
#' # Create with higher memory requirement
#' project_add("big_data_analysis", memory = 64)
#'
#' # Verify project was created
#' project_list()
#' }
#' @export
project_add <- function(project, memory = 10) {
    stopifnot(length(project) == 1)
    stopifnot(is.character(project))
    stopifnot(length(memory) == 1)
    stopifnot(is.numeric(memory))

    conserved_name <- c("config")
    if (project %in% conserved_name) {
        stop("Cannot use ", project)
    }

    table <- paste("task", project, sep = "_")
    con <- db_connect()
    # Add types
    sql <- "SELECT * FROM pg_type WHERE typname = 'task_status'"
    status_types <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(status_types) == 0) {
        sql <- "CREATE TYPE task_status AS ENUM ('working', 'finished', 'failed');"
        db_sql(sql, DBI::dbExecute, con)
    }
    # Add settings
    .table_project(con)

    sql <- sprintf("INSERT INTO project
                           (name, \"table\", status, memory)
                    VALUES ('%s', '%s', FALSE, '%s')
                    ON CONFLICT ON CONSTRAINT project_unique_name
                    DO UPDATE SET memory='%s'",
                    project, table, memory, memory)
    res <- DBI::dbExecute(con, sql)

    # create a new table
    sql <- sprintf('CREATE TABLE IF NOT EXISTS %s (
         	"id" INTEGER NULL DEFAULT NULL,
        	"status" task_status NULL DEFAULT NULL,
        	"start" timestamp with time zone,
            "finish" timestamp with time zone,
            "message" text COLLATE pg_catalog."default",
        	PRIMARY KEY ("id")
        )
        ;', table)
    res <- DBI::dbExecute(con, sql)
    db_disconnect(con)
    return(invisible())
}



#' Start a Project
#'
#' Activates a project to allow workers to begin consuming tasks. Workers will
#' only process tasks from started projects.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (updating project status).
#'
#' @details
#' Starting a project sets its \code{status} field to TRUE in the database.
#' Workers check this status before requesting new tasks. If a project is
#' stopped (status = FALSE), workers will terminate instead of processing tasks.
#'
#' You must start a project before deploying workers with \code{\link{worker}}
#' or \code{\link{worker_slurm}}.
#'
#' @seealso \code{\link{project_stop}}, \code{\link{project_add}},
#'   \code{\link{worker}}, \code{\link{worker_slurm}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Start project to enable workers
#' project_start("simulation_study")
#'
#' # Deploy workers after starting
#' worker_slurm("simulation_study", "hpc", fun = my_function)
#' }
#' @export
project_start <- function(project, con = NULL) {
    sql <- sprintf("UPDATE project SET status=TRUE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}


#' Stop a Project
#'
#' Deactivates a project and cancels all running SLURM jobs associated with it.
#' Workers will terminate after completing their current task.
#'
#' @param project Character string specifying the project name.
#'
#' @return Invisibly returns NULL. Called for side effects (stopping project and jobs).
#'
#' @details
#' This function:
#' \itemize{
#'   \item Sets the project status to FALSE, preventing workers from taking new tasks
#'   \item Cancels all SLURM jobs associated with this project using \code{scancel}
#'   \item Resets the job list for all project resources
#' }
#'
#' Active workers will complete their current task before shutting down. Tasks
#' in \code{working} status when the project stops should be reset to \code{idle}
#' using \code{\link{project_reset}} or \code{\link{task_reset}}.
#'
#' @seealso \code{\link{project_start}}, \code{\link{project_reset}},
#'   \code{\link{task_reset}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Stop project and cancel all jobs
#' project_stop("simulation_study")
#'
#' # Reset tasks that were in progress
#' task_reset("simulation_study", status = "working")
#' }
#' @export
project_stop <- function(project) {
    stopifnot(length(project) == 1)
    stopifnot(is.character(project))
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    sql <- sprintf("UPDATE project SET status=FALSE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)

    # Cancel running jobs
    pr <- project_resource_get(project, con = con)
    # Cancel slurm jobs
    pr_slurm <- pr[pr$type == "slurm", ]

    if (nrow(pr_slurm) > 0) {
        for (i in seq_len(nrow(pr_slurm))) {
            # skip if no jobs
            if (is.na(pr_slurm$jobs[i]) || nchar(pr_slurm$jobs[i]) == 0) {
                next
            }
            jobs <- strsplit(pr_slurm$jobs[i], ";")[[1]]
            r <- resource_get(pr_slurm$resource[i], con = con)
            cmds <- sprintf('scancel --jobname="%s"', jobs)
            for (j in seq(along = cmds)) {
                Sys.sleep(1)
                .run_slurm_cmd(cmds[j], r$host, r$username)
            }
            project_resource_add_jobs(project, pr_slurm$resource[i], reset = TRUE)
        }
    }

    return(invisible())
}

#' Reset a Project
#'
#' Resets all tasks in a project to idle status, stops the project, and
#' optionally cleans log files. Useful for restarting a project from scratch.
#'
#' @param project Character string specifying the project name.
#' @param log_clean Logical indicating whether to delete log files. Default is TRUE.
#'
#' @return Invisibly returns NULL. Called for side effects (resetting tasks and logs).
#'
#' @details
#' This function performs three operations:
#' \enumerate{
#'   \item Resets all tasks to idle status (NULL) using \code{\link{task_reset}}
#'   \item Stops the project using \code{\link{project_stop}}
#'   \item Optionally deletes all log files from resource log folders
#' }
#'
#' Use this when you want to:
#' \itemize{
#'   \item Restart failed tasks
#'   \item Re-run all tasks after fixing code
#'   \item Clean up before redeploying workers
#' }
#'
#' \strong{Warning:} Setting \code{log_clean = TRUE} permanently deletes all
#' log files, which may contain useful debugging information.
#'
#' @seealso \code{\link{task_reset}}, \code{\link{project_stop}},
#'   \code{\link{project_start}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Reset project and clean logs
#' project_reset("simulation_study")
#'
#' # Reset but keep logs for debugging
#' project_reset("simulation_study", log_clean = FALSE)
#'
#' # Restart after reset
#' project_start("simulation_study")
#' worker_slurm("simulation_study", "hpc", fun = my_function)
#' }
#' @export
project_reset <- function(project, log_clean = TRUE) {
    stopifnot(length(project) == 1)
    stopifnot(is.character(project))
    stopifnot(length(log_clean) == 1)
    stopifnot(is.logical(log_clean))
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    # Reset all tasks
    message("Reset all tasks")
    task_reset(project, status = "all", con = con)
    # Stop project
    message("Stop project")
    project_stop(project)

    if (log_clean) {
        # Clear log files
        message("Clear log files")
        pr_info <- project_resource_get(project, con = con)
        # Delete slurm types
        pr_info_slurm <- pr_info[pr_info$type == "slurm", ]
        for (i in seq_len(nrow(pr_info_slurm))) {
            project_resource_log_delete(project, pr_info_slurm$resource[i], con = con)
        }
    }
    return(invisible())
}
#' Get Project Information
#'
#' Retrieves detailed information about a specific project from the database.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return A single-row data frame containing project information with columns:
#'   \item{id}{Unique project identifier}
#'   \item{name}{Project name}
#'   \item{table}{Name of the task table for this project}
#'   \item{status}{Logical indicating if project is running (TRUE) or stopped (FALSE)}
#'   \item{memory}{Memory requirement in GB for tasks}
#'
#'   Stops with an error if the project is not found.
#'
#' @seealso \code{\link{project_add}}, \code{\link{project_list}},
#'   \code{\link{project_resource_get}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Get project details
#' info <- project_get("simulation_study")
#' print(info$status)  # Check if running
#' print(info$memory)  # Memory requirement
#' }
#' @export
project_get <- function(project, con = NULL) {
    sql <- sprintf("SELECT * from project where name='%s'", project)
    p <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(p) != 1) {
        stop("Cannot find project: ", project)
    }
    p
}


#' Get resources of a project
#'
#' @param project project name
#' @param resource resource name
#' @param con connection to database
#'
#' @return a table of resources used in the project
#' @export
project_resource_get <- function(project, resource = NULL, con = NULL) {
    project_info <- project_get(project, con)
    sql <- sprintf("SELECT project_resource.*, resource.name AS resource, resource.type
                        from project_resource
                        LEFT JOIN resource ON project_resource.resource_id = resource.id
                   where project_id='%s'",
                   project_info$id)
    if (!is.null(resource)) {
        stopifnot(length(resource) == 1)
        stopifnot(is.character(resource))
        sql <- paste0(sql, " AND resource.name='", resource, "'")
    }

    p_r <- db_sql(sql, DBI::dbGetQuery, con)
    p_r
}

#' List All Projects
#'
#' Retrieves information about all projects in the database.
#'
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return A data frame with one row per project, or NULL if no projects exist.
#'   Columns include: id, name, table, status, and memory.
#'
#' @details
#' Returns NULL if the project table doesn't exist (i.e., \code{\link{db_init}}
#' has not been called).
#'
#' @seealso \code{\link{project_add}}, \code{\link{project_get}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # List all projects
#' projects <- project_list()
#' print(projects)
#'
#' # Find running projects
#' running <- projects[projects$status == TRUE, ]
#' }
#' @export
project_list <- function(con = NULL) {
    if (!table_exist("project", con)) {
        return(NULL)
    }
    sql <- "SELECT * FROM public.project"
    projects <- db_sql(sql, DBI::dbGetQuery, con = con)
    projects
}

#' Delete a Project
#'
#' Permanently removes a project and all associated data from the database.
#' This includes the project configuration, task table, and resource assignments.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (deleting project).
#'
#' @details
#' This function removes:
#' \itemize{
#'   \item The project's task table (\code{task_<project>}) and all tasks
#'   \item All project-resource associations
#'   \item The project entry from the project table
#' }
#'
#' \strong{Warning:} This is a destructive operation that cannot be undone.
#' All task data and history for this project will be permanently lost.
#'
#' Log files on resources are NOT automatically deleted. Remove them manually
#' if needed.
#'
#' @seealso \code{\link{project_add}}, \code{\link{project_reset}},
#'   \code{\link{db_clean}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Delete a completed project
#' project_delete("old_simulation")
#'
#' # Verify deletion
#' project_list()
#' }
#' @export
project_delete <- function(project, con = NULL) {
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)
    project_info <- project_get(project, con)
    if (nrow(project_info) != 1) {
        stop("Cannot find project ", project)
    }

    # Drop task table
    sql <- sprintf("DROP TABLE task_%s", project)
    db_sql(sql, DBI::dbExecute, con)

    # Drop resource
    sql <- sprintf("DELETE FROM project_resource where project_id='%s'",
                   project_info$id)
    db_sql(sql, DBI::dbExecute, con)

    # Delete project
    sql <- sprintf("DELETE FROM project where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}



#' Display Project Status
#'
#' Prints a summary of project status including whether it's running and
#' the current status of all tasks.
#'
#' @param project Character string specifying the project name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (printing status).
#'
#' @details
#' Displays:
#' \itemize{
#'   \item Whether the project is running or stopped
#'   \item Task status summary from \code{\link{task_status}}
#' }
#'
#' Use this function to monitor progress and identify failed tasks.
#'
#' @seealso \code{\link{task_status}}, \code{\link{project_get}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Check project status
#' project_status("simulation_study")
#' }
#' @export
project_status <- function(project, con = NULL) {
    project_info <- project_get(project, con = con)

    if (project_info$status) {
        message("Project is running...")
    } else {
        message("Project is stopped.")
    }
    message("Task status: ")
    tasks <- task_status(project, con = con)
    print(tasks)
    return(invisible())
}


