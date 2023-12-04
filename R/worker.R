# Function for worker


#' Execute a job on cluster
#'
#' A worker will listen task channel to get a new job, run this job and mark job
#' is finished until get a shutdown message to stop this function.
#' @param project project name
#' @param fun function to run actual works
#'
#' @return No return is expected from this function
#' @examples
#' \dontrun{
#' worker("test_project", mean)
#' }
#' @export
worker <- function(project, fun) {

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
    # Wait for a random time to reduce the probability of all workers to reach
    # database at the same time
    Sys.sleep(runif(1) * 10)
    task_table <- sprintf("task_%s", project)
    message("Start on this worker.")
    # Working on tasks
    while (TRUE) {

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
                                      SET status='working'
                                      WHERE id=%s;",
                                      task_table,
                                      id)
                DBI::dbExecute(db_worker, sql_update)
            })
            db_disconnect(db_worker)
        })
        if (inherits(x, "try-error")) {
            message(paste("Failed to get a new task as error: ", x))
            message("Disconnect database. Try it again later")
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)
            next
        }

        message("Working on task: ", id)

        # Conduct actual work
        x <- try({
            fun(id)
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
                                      SET status='failed'
                                      WHERE id=%s;",
                                      task_table,
                                      id)
                DBI::dbExecute(db_worker, sql_update)
            })
            db_disconnect(db_worker)
            Sys.sleep(runif(1) * 10)

            next
        }

        message("Finsih to process task: ", id)
        # Reconnect database and update table
        # Might run this codes for couple times to updates
        x <- try({
            db_worker <- db_connect()
            DBI::dbWithTransaction(db_worker, {
                sql <- sprintf("LOCK TABLE %s IN ROW EXCLUSIVE MODE;", task_table)
                DBI::dbExecute(db_worker, sql)
                sql_update <- sprintf("UPDATE %s SET status='finished' WHERE id=%s;",
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
    }
    message("Finish to run on this worker. Now clean the environment")

}

#' Create a worker on slurm cluster
#'
#' @param project Project name
#' @param resource Resource name
#' @param rcode rscript file path
#' @param modules extra modules to load in slurm
#'
#' @return
#' @export
worker_slurm <- function(project, resource, rcode, modules = NULL) {

    # Get relative information
    con <- db_connect()
    project_info <- project_get(project, con)
    resource_info <- resource_get(resource, con)
    pr_info <- project_resource_get(project, con)
    db_disconnect(con)
    pr_info <- pr_info[pr_info$resource_id == resource_info$id,]

    if (nrow(pr_info) != 1) {
        stop("Cannot find resource (", resource, ") for project (", project, ")")
    }
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
    template <- gsub("\\$rcode", rcode, template)
    template <- gsub("\\$working_dir", pr_info$working_dir, template)
    template <- gsub("\\$times", pr_info$times, template)

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

    template <- gsub("\\$workers", workers, template)

    # Job name
    job_name <- paste0(project,"-", resource)
    template <- gsub("\\$job", job_name, template)

    # create submit file for slurm
    sub_file <- file.path(sub_folder, job_name)
    template <- gsub("\\$rout", sub_file, template)
    writeLines(template, sub_file)

    # Submit a job to cluster
    cmd <- sprintf("ssh %s 'cd %s;sbatch %s'",
                   resource_info$host, sub_folder, sub_file)
    Sys.sleep(1)
    system(cmd)

    # sub_files <- c()
    # i <- 1
    # for (i in seq_len(workers)) {
    #     template_i <- template
    #     file_str <- stringi::stri_rand_strings(1, 16, "[a-zA-Z]")
    #     # Job name
    #     job_name <- paste0(project,"-", resource, "-", file_str)
    #     template_i <- gsub("\\$job", job_name, template_i)
    #
    #     # create submit file for slurm
    #     sub_file <- file.path(sub_folder, job_name)
    #     template_i <- gsub("\\$rout", sub_file, template_i)
    #     writeLines(template_i, sub_file)
    #     sub_files <- c(sub_files, sub_file)
    # }
    #
    # # Submit a job to cluster
    #
    # cmds <- sprintf("ssh %s 'cd %s;sbatch %s'",
    #                resource_info$host, sub_folder, sub_files)
    # Sys.sleep(1)
    # for (i in seq_along(cmds)) {
    #     system(cmds[i])
    # }

}
