#' Execute a Slurm command locally or remotely
#'
#' Only allows Slurm commands: sbatch, squeue, scancel
.run_slurm_cmd <- function(cmd, host, username = NULL) {
    if (!requireNamespace("ssh", quietly = TRUE)) {
        stop("Package 'ssh' is required. Install with install.packages('ssh').")
    }

    # Whitelist Slurm commands
    allowed_cmds <- c("sbatch", "squeue", "scancel")
    if (!any(startsWith(cmd, allowed_cmds))) {
        stop("Only Slurm commands (sbatch, squeue, scancel) are allowed.")
    }

    if (is.null(username)) {
        username <- Sys.info()[["user"]]
    }

    host <- paste0(username, "@", host)

    if (.is_local(host)) {
        # Local execution
        return(system(cmd, intern = TRUE))
    } else {
        # Remote execution using ssh
        session <- ssh::ssh_connect(host)
        on.exit(ssh::ssh_disconnect(session), add = TRUE)

        result <- ssh::ssh_exec_internal(session, cmd)
        stdout <- rawToChar(result$stdout)
        stderr <- rawToChar(result$stderr)

        if (result$status != 0) {
            stop(sprintf("Remote command failed: %s", stderr))
        }

        return(stdout)
    }
}
