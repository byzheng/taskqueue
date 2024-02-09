# Function for worker


#' Execute a job on cluster
#'
#' A worker will listen task channel to get a new job, run this job and mark job
#' is finished until get a shutdown message to stop this function.
#' @param project project name
#' @param fun function to run actual works which will take task id as the first argument
#' @param ... other arguments passed to fun
#'
#' @return No return is expected from this function
#' @examples
#' \dontrun{
#' worker("test_project", mean)
#' }
#' @export
worker <- function(project, fun, ...) {

    # Test fun
    if (!is.function(fun)) {
        stop("Require a function")
    }
    if (length(project) != 1) {
        stop("Only a project is supported")
    }
    if (!is.character(project)) {
        stop("Project is not a character")
    }
    start_time <- as.numeric(Sys.time())
    # Wait for a random time to reduce the probability of all workers to reach
    # database at the same time
    Sys.sleep(runif(1) * 10)
    task_table <- sprintf("task_%s", project)
    message("Start on this worker.")

    walltime <- -1
    # Get maximum runtime for slurm resource
    project_resource <- project_resource_get(project)
    resource_name <- Sys.getenv("TASKQUEUE_RESOURCE")

    if (nchar(resource_name) > 0) {
        pos <- project_resource$resource == resource_name & project_resource$type == "slurm"
        project_resource  <- project_resource[pos,]
        if (nrow(project_resource) == 0) {
            stop("Cannot find the resource: ", resource_name, " in the database.")
        }
        walltime <- project_resource$times[1] * 3600
        message("The maximum runtime for this worker is ", walltime, "s")
    }

    tasks_runtime <- c()
    # Working on tasks
    while (TRUE) {
        message("Request a new task")
        task_start_time <- as.numeric(Sys.time())
        # Try to connect database
        x <- try({
            db_worker <- db_connect()
        }, silent = TRUE)
        if (inherits(x, "try-error")) {
            message("Cannot connect database. Reconnect it later.")
            Sys.sleep(runif(1) * 10)
            next
        }

        # Check the status of project
        x <- try({
            sql <- sprintf("SELECT * FROM project WHERE name='%s';", project)
            p_info <- DBI::dbGetQuery(db_worker, sql)
        })
        if (inherits(x, "try-error")) {
            message("Cannot query on database. Try it later")
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)
            next
        }

        if (nrow(p_info) != 1) {
            stop("Cannot find the project: ", project)
        }
        if (!p_info$status) {
            stop("Project is not started: ", project)
        }


        # Try to get a single task
        x <- try({

            DBI::dbWithTransaction(db_worker, {
                sql <- sprintf("LOCK TABLE %s IN ROW EXCLUSIVE MODE;", task_table)
                DBI::dbExecute(db_worker, sql)
                sql_task <- sprintf("SELECT id FROM %s WHERE status IS NULL LIMIT 1 FOR UPDATE SKIP LOCKED;",
                                    task_table)
                id <- DBI::dbGetQuery(db_worker, sql_task)
                if (nrow(id) == 0) {
                    message("No more task to process")
                    break
                }
                id <- id$id
                sql_update <- sprintf("UPDATE %s
                                      SET status='working',
                                          start=current_timestamp
                                      WHERE id=%s;",
                                      task_table,
                                      id)
                DBI::dbExecute(db_worker, sql_update)
            })
            db_disconnect(db_worker)
        })
        if (inherits(x, "try-error")) {
            message(paste("Failed to get a new task as error: ", x))
            message("Try it again later.")
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)
            next
        }

        message("Working on task: ", id)

        # Conduct actual work
        x <- try({
            fun(id, ...)
        }, silent = TRUE)
        if (inherits(x, "try-error")) {
            message(paste("Failed to work on ", id, " as error: ", x))
            message("Try it again later")


            # Mark as failed
            db_worker <- db_connect()
            DBI::dbWithTransaction(db_worker, {
                sql <- sprintf("LOCK TABLE %s IN ROW EXCLUSIVE MODE;", task_table)
                DBI::dbExecute(db_worker, sql)
                sql_update <- sprintf("UPDATE %s
                                      SET status='failed',
                                          finish=current_timestamp,
                                          message=%s
                                      WHERE id=%s;",
                                      task_table,
                                      RPostgres::dbQuoteString(db_worker, x),
                                      id)
                DBI::dbExecute(db_worker, sql_update)
            })
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)

            next
        }

        message("Finish to process task: ", id)
        # Reconnect database and update table
        # Might run this codes for couple times to updates
        x <- try({
            db_worker <- db_connect()
            DBI::dbWithTransaction(db_worker, {
                sql <- sprintf("LOCK TABLE %s IN ROW EXCLUSIVE MODE;", task_table)
                DBI::dbExecute(db_worker, sql)
                sql_update <- sprintf("UPDATE %s
                                      SET status='finished',
                                          finish=current_timestamp
                                      WHERE id=%s;",
                                      task_table, id)
                DBI::dbExecute(db_worker, sql_update)
            })
            db_disconnect(db_worker)
        }, silent = TRUE)
        if (inherits(x, "try-error")) {
            message(paste("Failed to mark task (", id, ") is finished as error: ", x))
            message("Try it again later")
            Sys.sleep(runif(1) * 10)
            next
        }
        # Check run time
        task_runtime <- as.numeric(Sys.time()) - task_start_time
        tasks_runtime <- c(tasks_runtime, task_runtime)
        message("The runtime for this task is ", round(task_runtime), "s")
        message("The average runtime for all tasks until now is ", round(mean(tasks_runtime)), "s")
        if (walltime > 0) {

            # Stop this worker if total runtime is almost longer than walltime

            gap_time <- stats::quantile(tasks_runtime, 0.9)
            if (sum(tasks_runtime) + gap_time > walltime) {
                message("No more tasks as no enough runtime now.")
                break
            }
        }
    }
    message("Finish to run on this worker.")

}

#' Create a worker on slurm cluster
#'
#' @param project Project name
#' @param resource Resource name
#' @param rcode rscript file path
#' @param modules extra modules to load in slurm
#'
#' @return no return
#' @export
worker_slurm <- function(project, resource, rcode, modules = NULL) {

    message("Schedule workers...")
    message("Project: ", project)
    # Get relative information
    con <- db_connect()
    project_info <- project_get(project, con)
    resource_info <- resource_get(resource, con)
    pr_info <- project_resource_get(project, con)
    t_status <- task_status(project, con)
    db_disconnect(con)

    pr_info <- pr_info[pr_info$resource_id == resource_info$id,]

    if (nrow(pr_info) != 1) {
        stop("Cannot find resource (", resource, ") for project (", project, ")")
    }

    message("Resource name: ", resource_info$name)
    message("Resource host: ", resource_info$host)
    message("Resource type: ", resource_info$type)
    message("Resource log folder: ", resource_info$log_folder)


    # Check template file for petrichor
    template <- system.file("petrichor", package = "taskqueue")
    if (!file.exists(template)) {
        stop("Cannnot find template file for petrichor: ", template)
    }
    template <- readLines(template)

    # Replace rcodes file path and working dir
    .check_linux_absolute_path(pr_info$working_dir)

    if (!is.character(rcode)) {
        stop("rcode should be a character")
    }
    if (length(rcode) != 1) {
        stop("Only support a single file")
    }

    rcode_path <- file.path(pr_info$working_dir, rcode)
    if (!file.exists(rcode_path)) {
        stop("Cannot find rcode file: ", rcode_path)
    }
    message("RScript: ", rcode_path)
    message("Working directory: ", pr_info$working_dir)
    message("Walltime: ", pr_info$times, "h")
    message("Memory: ", project_info$memory, "GB")
    template <- gsub("\\$rcode", rcode, template)
    template <- gsub("\\$working_dir", pr_info$working_dir, template)
    template <- gsub("\\$times", pr_info$times, template)
    template <- gsub("\\$memory", project_info$memory, template)
    # modules
    if (!is.null(modules)) {
        stopifnot(is.character(modules))
        pos <- grep("^ *module +load", template)
        if (length(pos) == 0) {
            stop("No module load in the template")
        }
        new_text <- paste("module load ", modules)
        template <- append(template, new_text, max(pos))
    }

    # Replace account
    if (is.null(pr_info$account)) {
        stop("An account is required for slurm system")
    }
    template <- gsub("\\$account", pr_info$account, template)


    .check_linux_absolute_path(resource_info$log_folder)
    sub_folder <- file.path(resource_info$log_folder, project)
    if (!dir.exists(sub_folder)) {
        dir.create(sub_folder, recursive = TRUE)
    }


    # Submit jobs
    # workers number can be specified in table resource for all projects or
    # table project_resource for this project. The minimum of two values
    # is used
    workers <- resource_info$workers
    if (is.null(workers)) {
        stop("workers number has to be spcefied for resource: ", resource)
    }
    if (!is.null(pr_info$workers)) {
        workers <- min(resource_info$workers, pr_info$workers)
    }

    # Consider current idle tasks.
    idle_task <- as.integer(t_status$count[t_status$status == "idle"])
    if (length(idle_task) > 0) {
        workers <- min(workers, idle_task)
    }
    message("Workers: ", workers)
    template <- gsub("\\$workers", workers, template)

    # Job name
    job_suffix <- stringi::stri_rand_strings(1, 6, '[a-z]')
    job_name <- paste0(project,"-", resource, "-", job_suffix)

    message("Job name on ", resource_info$host, ": ", job_name)
    template <- gsub("\\$job", job_name, template)

    # create submit file for slurm
    sub_file <- file.path(sub_folder, job_name)
    template <- gsub("\\$rout", sub_file, template)

    message("Submit file: ", sub_file)
    writeLines(template, sub_file)

    # Submit a job to cluster
    message("Run sbatch on ", resource_info$host)
    if (.is_bin_on_path("ssh")) {
        cmd <- sprintf("ssh %s 'cd %s;sbatch %s'",
                       resource_info$host, sub_folder, sub_file)
        Sys.sleep(1)
        system(cmd)
    } else {
        stop("Cannot find ssh command")
    }

    message("Finish to schedule workers")
    return(invisible())
}
