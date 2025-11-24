# Resource for project


.table_project_resource <- function(con = NULL) {
    sql <- c("

    CREATE TABLE IF NOT EXISTS public.project_resource
    (
        project_id integer NOT NULL,
        resource_id integer NOT NULL,
        working_dir character varying COLLATE pg_catalog.\"default\",
        account character varying COLLATE pg_catalog.\"default\",
        workers integer,
        times integer,
        jobs character varying COLLATE pg_catalog.\"default\",
        CONSTRAINT pr_unique_project_resource UNIQUE (project_id, resource_id),
        CONSTRAINT fk_project_resource_project FOREIGN KEY (project_id)
            REFERENCES public.project (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
            NOT VALID,
        CONSTRAINT fk_project_resource_resource FOREIGN KEY (resource_id)
            REFERENCES public.resource (id) MATCH SIMPLE
            ON UPDATE NO ACTION
            ON DELETE NO ACTION
            NOT VALID
    )
    TABLESPACE pg_default;",
    "COMMENT ON COLUMN public.project_resource.times
    IS 'worker running time in hours';",
    "CREATE INDEX IF NOT EXISTS fki_fk_project_resource_project
        ON public.project_resource USING btree
        (project_id ASC NULLS LAST)
        TABLESPACE pg_default;",
    "CREATE INDEX IF NOT EXISTS fki_fk_project_resource_resource
        ON public.project_resource USING btree
        (resource_id ASC NULLS LAST)
        TABLESPACE pg_default;
    ")
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}

#' Assign a Resource to a Project
#'
#' Associates a computing resource with a project and configures resource-specific
#' settings like working directory, runtime limits, and worker count.
#'
#' @param project Character string specifying the project name.
#' @param resource Character string specifying the resource name.
#' @param working_dir Absolute path to the working directory on the resource
#'   where workers will execute.
#' @param account Optional character string for the account/allocation to use
#'   on the resource (relevant for SLURM clusters with accounting). Default is NULL.
#' @param hours Maximum runtime in hours for each worker job. Default is 1 hour.
#' @param workers Maximum number of concurrent workers for this project on this
#'   resource. If NULL, uses the resource's maximum worker count.
#'
#' @return Invisibly returns NULL. Called for side effects (adding/updating
#'   project-resource association).
#'
#' @details
#' This function creates or updates the association between a project and resource.
#' Each project can be associated with multiple resources, and settings are
#' resource-specific.
#'
#' If the project-resource association already exists, only the specified
#' parameters are updated.
#'
#' The \code{working_dir} should exist on the resource and contain any necessary
#' input files or scripts.
#'
#' The \code{hours} parameter sets the SLURM walltime for worker jobs. Workers
#' will automatically terminate before this limit to avoid being killed mid-task.
#'
#' @seealso \code{\link{project_add}}, \code{\link{resource_add}},
#'   \code{\link{worker_slurm}}, \code{\link{project_resource_get}}
#'
#' @examples
#' \dontrun{
#' # Assign resource to project with basic settings
#' project_resource_add(
#'   project = "simulation_study",
#'   resource = "hpc",
#'   working_dir = "/home/user/simulations"
#' )
#'
#' # Assign with specific account and time limit
#' project_resource_add(
#'   project = "big_analysis",
#'   resource = "hpc",
#'   working_dir = "/scratch/project/data",
#'   account = "research_group",
#'   hours = 48,
#'   workers = 100
#' )
#' }
#' @export
project_resource_add <- function(project,
                                 resource,
                                 working_dir,
                                 account = NULL,
                                 hours = 1,
                                 workers = NULL) {
    # Checking arguments
    stopifnot(is.character(project))
    stopifnot(is.character(resource))
    stopifnot(is.character(working_dir))
    stopifnot(is.numeric(hours))
    if (length(working_dir) != 1) {
        stop("working_dir should be single value")
    }
    if (length(hours) != 1) {
        stop("hours should be single value")
    }

    # insert/update database

    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    # Create project is not existed
    .table_project_resource(con)
    project_info <- project_get(project, con)
    resource_info <- resource_get(resource, con)


    settings <- list()
    settings$project_id <- project_info$id
    settings$resource_id <- resource_info$id
    settings$working_dir <- working_dir
    if (!is.null(account)) {
        stopifnot(is.character(account))
        if (length(account) != 1) {
            stop("account should be single value")
        }
        settings$account <- account
    }
    if (!is.null(workers)) {
        stopifnot(is.numeric(workers))
        if (length(workers) != 1) {
            stop("workers should be single value")
        }
        settings$workers <- workers
    }

    if (!is.null(hours)) {
        stopifnot(is.numeric(hours))
        if (length(hours) != 1) {
            stop("hours should be single value")
        }
        settings$times <- hours
    }

    settings_values <- settings[!grepl("_id", names(settings))]
    settings_values <- paste(paste0(names(settings_values), "='", settings_values, "'"), collapse = ",")
    sql <- sprintf('
                   INSERT INTO project_resource (%s)
                   VALUES (%s)
                   ON CONFLICT ON CONSTRAINT pr_unique_project_resource
                       DO UPDATE SET %s;',
                   paste(sprintf('"%s"', names(settings)), collapse = ','),
                   paste(sprintf('\'%s\'', settings), collapse = ','),
                   settings_values)
    res <- DBI::dbExecute(con, sql)
    db_disconnect(con)
}


#' Delete Log Files for a Project Resource
#'
#' Removes all log files from the resource's log folder for a specific project.
#' Log files include SLURM output/error files and worker scripts.
#'
#' @param project Character string specifying the project name.
#' @param resource Character string specifying the resource name.
#' @param con An optional database connection. If NULL, a new connection is
#'   created and closed automatically.
#'
#' @return Invisibly returns NULL. Called for side effects (deleting log files).
#'
#' @details
#' Deletes all files matching the pattern \code{<project>-<resource>*} from
#' the log folder specified in the resource configuration.
#'
#' Currently only supports SLURM resources.
#'
#' This function is automatically called by \code{\link{project_reset}} when
#' \code{log_clean = TRUE}.
#'
#' @seealso \code{\link{project_reset}}, \code{\link{resource_add}}
#'
#' @examples
#' \dontrun{
#' # Delete logs for specific project-resource
#' project_resource_log_delete("simulation_study", "hpc")
#' }
#' @export
project_resource_log_delete <- function(project,
                                 resource, con = NULL) {

    if (length(project) != 1 || length(resource) != 1) {
        stop("Require a single project or resource")
    }
    pr_info <- project_resource_get(project, con = con)
    r_info <- resource_get(resource, con = con)
    if (r_info$type != "slurm") {
        stop("Only support slurm now")
    }

    if (!(r_info$id %in% pr_info$resource_id)) {
        stop("Resource ", resource, " is not for project ", project)
    }
    log_folder <- file.path(r_info$log_folder, project)
    if (!dir.exists(log_folder)) {
        warning("Cannot find log folder")
        return(invisible())
    }

    files <- list.files(log_folder, sprintf("^%s-%s.*$", project, resource), full.names = TRUE)
    a <- lapply(files, file.remove)
    return(invisible())
}


#' Manage SLURM Job List for Project Resource
#'
#' Adds a SLURM job name to the list of active jobs for a project-resource
#' association, or resets the job list.
#'
#' @param project Character string specifying the project name.
#' @param resource Character string specifying the resource name.
#' @param job Character string with the SLURM job name to add. If missing,
#'   the job list is reset to empty.
#' @param reset Logical indicating whether to clear the job list before adding.
#'   Default is FALSE. If TRUE, replaces all jobs with \code{job}.
#'
#' @return Invisibly returns NULL. Called for side effects (updating job list).
#'
#' @details
#' The job list is a semicolon-separated string of SLURM job names stored in
#' the database. This list is used by \code{\link{project_stop}} to cancel
#' all jobs when stopping a project.
#'
#' Job names are automatically added by \code{\link{worker_slurm}} when
#' submitting workers.
#'
#' Currently only supports SLURM resources.
#'
#' @seealso \code{\link{worker_slurm}}, \code{\link{project_stop}}
#'
#' @examples
#' \dontrun{
#' # Add a job (typically done automatically by worker_slurm)
#' project_resource_add_jobs("simulation_study", "hpc", "job_12345")
#'
#' # Reset job list
#' project_resource_add_jobs("simulation_study", "hpc", reset = TRUE)
#' }
#' @export
project_resource_add_jobs <- function(project, resource, job, reset = FALSE) {
    if (length(project) != 1 || length(resource) != 1) {
        stop("Require a single project or resource")
    }
    if (missing(job)) {
        job <- ""
        reset <- TRUE
    }
    stopifnot(length(reset) == 1)
    stopifnot(is.logical(reset))
    stopifnot(length(job) == 1)
    stopifnot(is.character(job))
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    pr_info <- project_resource_get(project, resource, con = con)

    if (pr_info$type != "slurm") {
        stop("Only support slurm resource")
    }

    if (reset) {
        all_jobs <- ""
    } else {
        if (is.na(pr_info$jobs)) {
            all_jobs <- job
        } else {
            all_jobs <- paste0(pr_info$jobs, ";", job)
        }
    }
    sql <- sprintf("UPDATE project_resource
                SET jobs='%s'
                   WHERE project_id=%s AND resource_id=%s;",
                   all_jobs,
                   pr_info$project_id, pr_info$resource_id)

    res <- DBI::dbExecute(con, sql)
}
