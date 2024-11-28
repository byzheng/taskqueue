
#' Apply a function with task queue
#'
#' @param n Number of task
#' @param fun A function
#' @param project Project name
#' @param resource Resource name
#' @param memory Memory in GB
#' @param hour Maximum runtime in cluster
#' @param account Optional. Account for cluster
#' @param working_dir Working directory in cluster
#' @param ... Other arguments for fun
#'
#' @return No return values
#' @export
tq_apply <- function(n, fun, project, resource,
                     memory = 10,
                     hour = 24,
                     account = NULL,
                     working_dir = getwd(), ...) {
    # Check arguments
    stopifnot(is.numeric(n))
    stopifnot(length(n) == 1)
    stopifnot(is.function(fun))
    stopifnot(length(project) == 1)
    stopifnot(is.character(project))
    stopifnot(length(resource) == 1)
    stopifnot(is.character(resource))

    # Check project
    con <- db_connect()
    on.exit(db_disconnect(con), add = TRUE)
    message("------------------------------------------------------")
    message("Check project and resource.")
    message("Create project and resource if not existed.")
    message("Update project and resource if existed.")
    # Stop if resource is not existed
    resource_info <- resource_get(resource, con = con)
    # Create/update project if not existed
    project_add(project, memory = memory)


    # prjs <- project_list()
    # if (!(project %in% prjs$name)) {
    #
    # } else {
    #
    # }
    project_info <- project_get(project, con = con)
    db_disconnect(con)

    # Create resource for project if not existed
    # Update resource for project if existed
    project_resource_add(project, resource,
                         working_dir = working_dir,
                         workers = n,
                         hours = hour,
                         account = account)
    message("Add tasks to project.")
    task_add(project, num = n, clean = TRUE)
    # Reset project
    message("Reset project status.")
    project_reset(project)
    # Schedule workers
    message("\n")
    message("------------------------------------------------------")
    worker_slurm(project, resource, fun = fun, ...)

    message("\n")
    message("------------------------------------------------------")
    message("Call function project_status to check status.")
}

