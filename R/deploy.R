# deploy

#' Deploy taskqueue into slurm resources
#'
#' @return no return
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
