.validate_slurm_cmd <- function(cmd) {
    allowed_cmds <- c("sbatch", "squeue", "scancel", "cd")

    # Split compound commands by separators ; && ||
    parts <- unlist(strsplit(cmd, "\\s*;\\s*|\\s*&&\\s*|\\s*\\|\\|\\s*"))

    for (p in parts) {
        # Trim whitespace
        p_trim <- trimws(p)

        # Extract the first token (the command name)
        first_word <- sub("\\s.*$", "", p_trim)

        # Check against allowed commands
        if (!first_word %in% allowed_cmds) {
            stop(sprintf(
                "Command '%s' is not allowed. Only Slurm commands (%s) are permitted.",
                first_word,
                paste(allowed_cmds, collapse = ", ")
            ))
        }
    }

    TRUE
}

.run_slurm_cmd <- function(cmd, host, username = NULL) {
    stopifnot(length(cmd) == 1 && is.character(cmd))
    stopifnot(length(host) == 1 && is.character(host))
    if (!requireNamespace("ssh", quietly = TRUE)) {
        stop("Package 'ssh' is required. Install with install.packages('ssh').")
    }

    message("Executing command: ", cmd)
    .validate_slurm_cmd(cmd)

    if (is.null(username)) {
        username <- Sys.info()[["user"]]
    } else {
        username <- stringr::str_trim(username)
    }
    host <- stringr::str_trim(host)

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
