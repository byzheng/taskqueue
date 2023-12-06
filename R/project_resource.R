# Resource for project


.table_project_resource <- function(con) {
    DBI::dbExecute(con, "
       -- Table: public.project_resource

-- DROP TABLE IF EXISTS public.project_resource;

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

TABLESPACE pg_default;

ALTER TABLE IF EXISTS public.project_resource
    OWNER to postgres;

COMMENT ON COLUMN public.project_resource.times
    IS 'worker running time in hours';
-- Index: fki_fk_project_resource_project

-- DROP INDEX IF EXISTS public.fki_fk_project_resource_project;

CREATE INDEX IF NOT EXISTS fki_fk_project_resource_project
    ON public.project_resource USING btree
    (project_id ASC NULLS LAST)
    TABLESPACE pg_default;
-- Index: fki_fk_project_resource_resource

-- DROP INDEX IF EXISTS public.fki_fk_project_resource_resource;

CREATE INDEX IF NOT EXISTS fki_fk_project_resource_resource
    ON public.project_resource USING btree
    (resource_id ASC NULLS LAST)
    TABLESPACE pg_default;
    ")
}

#' Assign a resource to a project
#'
#' @param project project name
#' @param resource resource name
#' @param working_dir working directory for this resource
#' @param account optional for account to use this resource
#' @param times worker wall times for this resource
#' @param workers maximum workers for this project.
#'
#' @return
#' @export
project_resource_add <- function(project,
                                 resource,
                                 working_dir,
                                 account = NULL,
                                 times = 1,
                                 workers = NULL) {
    # Checking arguments
    stopifnot(is.character(project))
    stopifnot(is.character(resource))
    stopifnot(is.character(working_dir))
    stopifnot(is.numeric(times))
    if (length(working_dir) != 1) {
        stop("working_dir should be single value")
    }
    if (length(times) != 1) {
        stop("times should be single value")
    }

    # insert/update database

    con <- db_connect()

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

    if (!is.null(times)) {
        stopifnot(is.numeric(times))
        if (length(times) != 1) {
            stop("times should be single value")
        }
        settings$times <- times
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
