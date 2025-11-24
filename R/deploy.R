# deploy

#' Deploy taskqueue Package to SLURM Resources
#'
#' Installs or updates the taskqueue package on all registered SLURM resources
#' by connecting via SSH and installing from GitHub.
#'
#' @return Invisibly returns NULL. Called for side effects (installing package
#'   on remote resources).
#'
#' @details
#' For each SLURM resource in the database, this function:
#' \enumerate{
#'   \item Connects via SSH to the resource host
#'   \item Loads the R module (currently hardcoded as R/4.3.1)
#'   \item Installs taskqueue from GitHub using devtools
#' }
#'
#' \strong{Requirements:}
#' \itemize{
#'   \item SSH access to all SLURM resources
#'   \item R and devtools installed on each resource
#'   \item Internet access from resources to reach GitHub
#' }
#'
#' \strong{Note:} The R module name is currently hardcoded. Modify the function
#' if your resources use different module names.
#'
#' @seealso \code{\link{resource_add}}, \code{\link{resource_list}}
#'
#' @examples
#' \dontrun{
#' # Deploy to all SLURM resources
#' slurm_deploy()
#' }
#' @export
slurm_deploy <- function() {
    resources <- resource_list()
    hosts <- resources$host[resources$type == "slurm"]

    for (i in seq(along = hosts)) {
        cmd <- sprintf("ssh %s 'module load R/4.3.1; R -e \"devtools::install_github(\\\"byzheng/taskqueue\\\")\"'",
                       hosts[i])
        system(cmd)
    }
}