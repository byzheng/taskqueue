
# Projects
# Create types
.types <- function(con = NULL) {

    sql <- "SELECT * FROM pg_type WHERE typname = 'task_status'"
    status_types <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(status_types) == 0) {
        sql <- "CREATE TYPE task_status AS ENUM ('working', 'finished', 'failed');"
        db_sql(sql, DBI::dbExecute, con)
    }
}
# Create project table if not exist
.table_project <- function(con = NULL) {
    sql <- c("
        CREATE TABLE IF NOT EXISTS public.project
        (
            id SERIAL NOT NULL,
            name character varying COLLATE pg_catalog.\"default\" NOT NULL,
            \"table\" character varying COLLATE pg_catalog.\"default\" NOT NULL,
            status boolean,
            memory integer NOT NULL DEFAULT 10,
            CONSTRAINT project_pkey PRIMARY KEY (id),
            CONSTRAINT project_unique_name UNIQUE (name)
        );",
        "COMMENT ON COLUMN public.project.memory
            IS 'Memory requirement in GB';
    ")
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}


#' Create project to database
#'
#' @param project project name
#' @param memory memory usage in GB
#' @return no returns
#' @export
project_add <- function(project, memory = 10)
{
    if (length(project) != 1) {
        stop("Please use a single name")
    }
    conserved_name <- c("config")
    if (project %in% conserved_name) {
        stop("Cannot use ", project)
    }
    stopifnot(is.numeric(memory))
    if (length(memory) != 1) {
        stop("Please use a single value for memory")
    }

    table <- paste('task', project, sep = '_')
    con <- db_connect()
    # Add types
    sql <- "SELECT * FROM pg_type WHERE typname = 'task_status'"
    status_types <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(status_types) == 0) {
        sql <- "CREATE TYPE task_status AS ENUM ('working', 'finished', 'failed');"
        db_sql(sql, DBI::dbExecute, con)
    }
    # Add settings
    settings <- list()
    settings$table <- table
    settings$name <- project
    settings$memory <- memory
    settings$status <- FALSE
    setting_db <- as.character(lapply(settings,
                                      function(x)
                                      {
                                          x <- paste(x, collapse = ';')
                                          x <- gsub('\\\\', '\\\\\\\\', x)
                                          return(x)
                                      }))
    names(setting_db) <- names(settings)
    .table_project(con)

    tc_col <- DBI::dbGetQuery(con, 'select * from project where false;')
    tc_col <- names(tc_col)
    tc_col <- tc_col[!(tc_col %in% "id")]
    pos <- match(tc_col, names(setting_db))
    setting_db <- setting_db[pos]
    sql <- sprintf('INSERT INTO project (%s) VALUES (%s)  ON CONFLICT DO NOTHING',
                   paste(sprintf('"%s"', names(setting_db)), collapse = ','),
                   paste(sprintf('\'%s\'', setting_db), collapse = ','))
    res <- DBI::dbExecute(con, sql)

    # create a new table
    sql <- sprintf('CREATE TABLE IF NOT EXISTS %s (
         	"id" INTEGER NULL DEFAULT NULL,
        	"status" task_status NULL DEFAULT NULL,
        	PRIMARY KEY ("id")
        )
        ;', table)
    res <- DBI::dbExecute(con, sql)
    db_disconnect(con)
    return(invisible())
}



#' Start a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return no return
#' @export
project_start <- function(project, con = NULL) {
    sql <- sprintf("UPDATE project SET status=TRUE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}


#' Stop a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return no return
#' @export
project_stop <- function(project, con = NULL) {
    sql <- sprintf("UPDATE project SET status=FALSE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}

#' Reset status of all tasks in a project to NULL
#'
#' @param project project name
#' @param status status to reset
#' @param con connection to database
#'
#' @return no return
#' @export
project_reset <- function(project, status = c("working", "failed"), con = NULL) {
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)

    sql <- "SELECT unnest(enum_range(NULL::task_status));"
    define_status <- db_sql(sql, DBI::dbGetQuery, con)
    pos <- !(status %in% define_status$unnest )
    if (sum(pos) > 0) {
        stop("Cannot find status: ", paste(status[pos], sep = ", "))
    }
    status_sql <- paste(paste0("'", status, "'"), collapse = ", ")
    sql <- sprintf("UPDATE task_%s SET status=NULL WHERE status  in (%s);",
                   project, status_sql)
    a <- db_sql(sql, DBI::dbExecute, con)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}
#' Get a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return a table of project information
#' @export
project_get <- function(project, con = NULL) {
    sql <- sprintf("SELECT * from project where name='%s'", project)
    p <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(p) != 1) {
        stop("Cannot find project: ", project)
    }
    p
}


#' Get resources of a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return a table of resources used in the project
#' @export
project_resource_get <- function(project, con = NULL) {
    project_info <- project_get(project, con)
    sql <- sprintf("SELECT * from project_resource where project_id='%s'",
                   project_info$id)
    p_r <- db_sql(sql, DBI::dbGetQuery, con)
    p_r
}

#' List all projects
#'
#' @param con a db connection
#'
#' @return a table for all projects
#' @export
project_list <- function(con = NULL) {
    sql <- "SELECT * FROM public.project"
    projects <- db_sql(sql, DBI::dbGetQuery, con = con)
    projects
}

#' Delete a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return no return
#' @export
project_delete <- function(project, con = NULL) {
    new_connection <- ifelse(is.null(con), TRUE, FALSE)
    con <- db_connect(con)
    project_info <- project_get(project, con)
    if (nrow(project_info) != 1) {
        stop("Cannot find project ", project)
    }

    # Drop task table
    sql <- sprintf("DROP TABLE task_%s", project)
    db_sql(sql, DBI::dbExecute, con)

    # Drop resource
    sql <- sprintf("DELETE FROM project_resource where project_id='%s'",
                   project_info$id)
    db_sql(sql, DBI::dbExecute, con)

    # Delete project
    sql <- sprintf("DELETE FROM project where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
    if (new_connection) {
        db_disconnect(con)
    }
    return(invisible())
}
