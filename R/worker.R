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
    message(.sys_now(), ": ", "Start on this worker.")

    sys_info <- Sys.info()

    message("nodename: ", sys_info["nodename"])
    message("sysname: ", sys_info["sysname"])
    message("release: ", sys_info["release"])
    message("user: ", sys_info["user"])

    walltime <- -1
    # Get maximum runtime for slurm resource
    project_resource <- project_resource_get(project)
    resource_name <- Sys.getenv("TASKQUEUE_RESOURCE")

    if (nchar(resource_name) > 0) {
        pos <- project_resource$resource == resource_name & project_resource$type == "slurm"
        project_resource  <- project_resource[pos,]
        if (nrow(project_resource) == 0) {
            stop(.sys_now(), ": ", "Cannot find the resource: ", resource_name, " in the database.")
        }
        walltime <- project_resource$times[1] * 3600
        message(.sys_now(), ": ", "The maximum runtime for this worker is ", walltime, "s")
    }

    tasks_runtime <- c()
    # Working on tasks
    while (TRUE) {
        message("")
        message("-------------------------------------------------")
        message(.sys_now(), ": ", "Request a new task")
        task_start_time <- as.numeric(Sys.time())
        # Try to connect database
        x <- try({
            db_worker <- db_connect()
        }, silent = TRUE)
        if (inherits(x, "try-error")) {
            message(.sys_now(), ": ", "Cannot connect database. Reconnect it later.")
            Sys.sleep(runif(1) * 10)
            next
        }

        # Check the status of project
        x <- try({
            sql <- sprintf("SELECT * FROM project WHERE name='%s';", project)
            p_info <- DBI::dbGetQuery(db_worker, sql)
        })
        if (inherits(x, "try-error")) {
            message(.sys_now(), ": ", "Cannot query on database. Try it later")
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)
            next
        }

        if (nrow(p_info) != 1) {
            stop(.sys_now(), ": ", "Cannot find the project: ", project)
        }
        if (!p_info$status) {
            stop(.sys_now(), ": ", "Project is not started: ", project)
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
                    message(.sys_now(), ": ", "No more task to process")
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
            message(.sys_now(), ": ", paste("Failed to get a new task as error: ", x))
            message(.sys_now(), ": ", "Try it again later.")
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)
            next
        }

        message(.sys_now(), ": ", "Working on task: ", id)

        # Conduct actual work
        x <- try({
            fun(id, ...)
        }, silent = TRUE)
        if (inherits(x, "try-error")) {
            message(.sys_now(), ": ", paste("Failed to work on ", id, " as error: ", x))
            message(.sys_now(), ": ", "Try it again later")


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

        message(.sys_now(), ": ", "Finish to process task: ", id)
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
            message(.sys_now(), ": ", paste("Failed to mark task (", id, ") is finished as error: ", x))
            message(.sys_now(), ": ", "Try it again later")
            Sys.sleep(runif(1) * 10)
            next
        }
        # Check run time
        task_runtime <- as.numeric(Sys.time()) - task_start_time
        tasks_runtime <- c(tasks_runtime, task_runtime)
        message(.sys_now(), ": ", "The runtime for this task is ", round(task_runtime), "s")
        message(.sys_now(), ": ", "The average runtime for all tasks until now is ", round(mean(tasks_runtime)), "s")
        if (walltime > 0) {

            # Stop this worker if total runtime is almost longer than walltime

            gap_time <- stats::quantile(tasks_runtime, 0.9)
            if (sum(tasks_runtime) + gap_time > walltime) {
                message(.sys_now(), ": ", "No more tasks as no enough runtime now.")
                break
            }
        }
    }
    message(.sys_now(), ": ", "Finish to run on this worker.")

}

#' Create a worker on slurm cluster
#'
#' @param project Project name.
#' @param resource Resource name.
#' @param fun Function running on workers. See details.
#' @param rfile R script file path. See details.
#' @param module_r Module name for R.
#' @param module_pg Module name for postgresql. See details.
#' @param modules extra modules to load in slurm. See details.
#' @param pkgs A character vector containing the names of packages that must
#'   be loaded on worker including all packages in default when \code{worker_slurm}
#'   is called.
#' @param submit Whether to submit to slurm cluster (TRUE in default). See details.
#' @param ... Extra arguments for fun.
#'
#' @details
#'  There are two ways to pass R scripts into workers (i.e. \code{fun} or \code{file}).
#' * \code{fun} is used for general and simple case which takes the task id as the first argument. A new r script is created in the log
#'  folder and running in the workers. The required packages are passed using \code{pkgs}.
#'  Extra arguments are specified through \code{...}. \code{taskqueue_options()} is passed
#'  into workers.
#'  * \code{rfile} is used more complicated case. Function \code{worker} has to be
#'  called at the end of file. No \code{taskqueue_options()} is passed into workers.
#'  * \code{fun} is higher priority with \code{file}.
#' A submit file is created in the log folder for each project/resource with random file name.
#' Then system command \code{ssh} is used to connect remote slurm host if \code{submit = TRUE}.
#' @return no return
#' @export
#' @examples
#' \dontrun{
#' fun_test <- function(i, prefix) {
#'     Sys.sleep(runif(1) * 2)
#' }
#' worker_slurm("test_project", "slurm", fun = fun_test)
#' worker_slurm("test_project", "slurm", fun = fun_test, prefix = "a")
#' worker_slurm("test_project", "slurm", rfile = "rfile.R")
#' worker_slurm("test_project", "slurm", fun = fun_test, submit = FALSE)
#' }
#'
worker_slurm <- function(project, resource, fun, rfile,
                         module_r = "R/4.3.1",
                         module_pg = "postgresql/16.0",
                         modules = NULL,
                         pkgs = rev(.packages()), submit = TRUE, ...) {

    # Check arguments
    stopifnot(length(project) == 1)
    stopifnot(is.character(project))
    stopifnot(length(resource) == 1)
    stopifnot(is.character(resource))
    stopifnot(length(module_r) == 1)
    stopifnot(is.character(module_r))
    stopifnot(length(module_pg) == 1)
    stopifnot(is.character(module_pg))

    if (missing(fun) && missing(rfile)) {
        stop("One of fun and rfile should be specified.")
    }


    message("Schedule workers...")
    message("Project: ", project)

    # Get relative information
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    project_info <- project_get(project, con)
    resource_info <- resource_get(resource, con)
    pr_info <- project_resource_get(project, con)
    t_status <- task_status(project, con)
    db_disconnect(con)

    if (resource_info$type != "slurm") {
        stop("only used for slurm cluster.")
    }
    pr_info <- pr_info[pr_info$resource_id == resource_info$id,]

    if (nrow(pr_info) != 1) {
        stop("Cannot find resource (", resource, ") for project (", project, ")")
    }
    project_start(project)

    message("Resource name: ", resource_info$name)
    message("Resource host: ", resource_info$host)
    message("Resource type: ", resource_info$type)
    message("Resource log folder: ", resource_info$log_folder)


    .check_linux_absolute_path(resource_info$log_folder)
    sub_folder <- file.path(resource_info$log_folder, project)
    if (!dir.exists(sub_folder)) {
        dir.create(sub_folder, recursive = TRUE)
    }


    # Job name
    job_suffix <- stringi::stri_rand_strings(1, 6, '[a-z]')
    job_name <- paste0(project,"-", resource, "-", job_suffix)


    # Replace rcodes file path and working dir
    .check_linux_absolute_path(pr_info$working_dir)

    # Create a new R file if fun is not missing.
    if (!missing(fun)) {
        # use function if it is specified
        message("fun will run on workers")
        stopifnot(is.function(fun))
        template_r <- system.file("slurm_R.txt", package = "taskqueue")
        if (!file.exists(template_r)) {
            stop("Cannnot find template file for slurm: ", template_r)
        }
        template_r <- readLines(template_r)

        pkgs <- unique(c(pkgs, "taskqueue"))
        arguments <- list(...)
        .check_arg_name(arguments)
        arguments$project <- project
        arguments$fun <- fun
        arguments$options <- taskqueue_options()
        datafile <- file.path(sub_folder, sprintf("%s-data.Rds", job_name))
        saveRDS(arguments, datafile)
        # arguments_str <- paste(paste(names(arguments), names(arguments), sep = " = "), collapse = ", ")
        script_r <- whisker::whisker.render(template_r,
                                            list(pkgs = pkgs,
                                                 #arguments = arguments_str,
                                                 rds_file = datafile))

        rfile <- file.path(sub_folder, sprintf("%s-rcode.R", job_name))
        writeLines(script_r, rfile)
    }


    # Check r script file
    if (!is.character(rfile)) {
        stop("rcode should be a character")
    }
    if (length(rfile) != 1) {
        stop("Only support a single file")
    }

    if (!file.exists(rfile)) {
        stop("Cannot find rcode file: ", rfile)
    }
    message("RScript: ", rfile)
    message("Working directory: ", pr_info$working_dir)
    message("Walltime: ", pr_info$times, "h")
    message("Memory: ", project_info$memory, "GB")

    # Check submit options
    submit_options <- list()
    # Include all modules
    if (!is.null(modules)) {
        stopifnot(is.character(modules))
    }
    submit_options$modules <- c(module_r, module_pg, modules)
    submit_options$resource <- resource
    # rfile, times and memory
    submit_options$rfile <- rfile
    submit_options$working_dir <- pr_info$working_dir
    submit_options$times <- pr_info$times
    submit_options$memory <- project_info$memory

    # Replace account
    if (!(is.null(pr_info$account) | is.na(pr_info$account))) {
        submit_options$account <- pr_info$account
    } else {
        submit_options$account <- ""
    }


    # Submit jobs
    # workers number can be specified in table resource for all projects or
    # table project_resource for this project. The minimum of two values
    # is used
    workers <- resource_info$workers
    if (is.null(workers)) {
        stop("workers number has to be spcefied for resource: ", resource)
    }
    if (!is.null(pr_info$workers) && !is.na(pr_info$workers)) {
        workers <- min(resource_info$workers, pr_info$workers)
    }

    # Consider current idle tasks.
    idle_task <- as.integer(t_status$count[t_status$status == "idle"])
    if (length(idle_task) == 0) {
        warning("No idle task for project: ", project)
        return(invisible())
    }
    workers <- min(workers, idle_task)
    if (is.na(workers)) {
        stop("Workers should not be NA")
    }
    message("Workers: ", workers)
    submit_options$workers <- workers


    message("Job name on ", resource_info$host, ": ", job_name)
    submit_options$job <- job_name

    # create submit file for slurm
    sub_file <- file.path(sub_folder, job_name)
    submit_options$rout <- sub_file

    message("Submit file: ", sub_file)



    # Create new submit file
    template_sub <- system.file("slurm_submit.txt", package = "taskqueue")
    if (!file.exists(template_sub)) {
        stop("Cannnot find template file for slurm: ", template_sub)
    }
    template_sub <- readLines(template_sub)
    script_sub <- whisker::whisker.render(template_sub, submit_options)
    writeLines(script_sub, sub_file)

    message("Submit file is created on: ", sub_file)


    if (submit) {
        # Submit a job to cluster
        message("Run sbatch on ", resource_info$host)
        if (.is_bin_on_path("ssh")) {
            if (.is_local(resource_info$host)) {
                cmd <- sprintf("cd %s;sbatch %s",
                               sub_folder, sub_file)
            } else {
                cmd <- sprintf("ssh %s 'cd %s;sbatch %s'",
                           resource_info$host, sub_folder, sub_file)
            }
            Sys.sleep(1)
            system(cmd)

            # Add jobs to project_resource table
            project_resource_add_jobs(project, resource, job_name)

        } else {
            stop("Cannot find ssh command")
        }
    } else {
        message("Call command below in ", resource_info$host)
        message("sbatch ", sub_file)
    }
    message("Finish to schedule workers")
    return(invisible())
}
