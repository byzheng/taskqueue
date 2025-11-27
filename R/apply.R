
#' Apply a Function with Task Queue (Simplified Workflow)
#'
#' A high-level interface for running embarrassingly parallel tasks on HPC
#' clusters. Combines project creation, task addition, and worker scheduling
#' into a single function call, similar to \code{lapply}.
#'
#' @param n Integer specifying the number of tasks to run. Your function will
#'   be called with arguments 1, 2, ..., n.
#' @param fun Function to execute for each task. Must accept the task ID as its
#'   first argument. Should save results to disk.
#' @param project Character string for project name. Will be created if it
#'   doesn't exist, updated if it does.
#' @param resource Character string for resource name. Must already exist
#'   (created via \code{\link{resource_add}}).
#' @param memory Memory requirement in GB for each task. Default is 10 GB.
#' @param hour Maximum runtime in hours for worker jobs. Default is 24 hours.
#' @param account Optional character string for SLURM account/allocation.
#'   Default is NULL.
#' @param working_dir Working directory on the cluster where tasks execute.
#'   Default is current directory (\code{getwd()}).
#' @param ... Additional arguments passed to \code{fun} for every task.
#'
#' @return Invisibly returns NULL. Called for side effects (scheduling workers).
#'
#' @details
#' This function automates the standard taskqueue workflow:
#' \enumerate{
#'   \item Creates or updates the project with specified memory
#'   \item Assigns the resource to the project
#'   \item Adds \code{n} tasks (cleaning any existing tasks)
#'   \item Resets all tasks to idle status
#'   \item Schedules workers on the SLURM cluster
#' }
#'
#' Equivalent to manually calling:
#' \preformatted{
#' project_add(project, memory = memory)
#' project_resource_add(project, resource, working_dir, account, hour, n)
#' task_add(project, n, clean = TRUE)
#' project_reset(project)
#' worker_slurm(project, resource, fun = fun, ...)
#' }
#'
#' \strong{Before using tq_apply:}
#' \itemize{
#'   \item Initialize database: \code{db_init()}
#'   \item Create resource: \code{resource_add(...)}
#'   \item Configure \code{.Renviron} with database credentials
#' }
#'
#' Your worker function should:
#' \itemize{
#'   \item Take task ID as first argument
#'   \item Save results to files (not return values)
#'   \item Be idempotent (check if output exists)
#' }
#'
#' @seealso \code{\link{worker}}, \code{\link{worker_slurm}},
#'   \code{\link{project_add}}, \code{\link{task_add}},
#'   \code{\link{resource_add}}
#'
#' @examples
#' \dontrun{
#' # Not run:
#' # Simple example
#' my_simulation <- function(i, param) {
#'   out_file <- sprintf("results/sim_%04d.Rds", i)
#'   if (file.exists(out_file)) return()
#'   result <- run_simulation(i, param)
#'   saveRDS(result, out_file)
#' }
#'
#' # Run 100 simulations on HPC
#' tq_apply(
#'   n = 100,
#'   fun = my_simulation,
#'   project = "my_study",
#'   resource = "hpc",
#'   memory = 16,
#'   hour = 6,
#'   param = 5
#' )
#'
#' # Monitor progress
#' project_status("my_study")
#' task_status("my_study")
#' }
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

