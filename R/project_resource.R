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

#' Assign a resource to a project
#'
#' @param project project name
#' @param resource resource name
#' @param working_dir working directory for this resource
#' @param account optional for account to use this resource
#' @param hours worker wall times in hours for this resource
#' @param workers maximum workers for this project.
#'
#' @return no return
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


#' Delete all logs for a project resource
#'
#' @param project project name
#' @param resource resource name
#' @param con connection to database
#'
#' @return no return
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
