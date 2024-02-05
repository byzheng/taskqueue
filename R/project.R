
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
    .table_project(con)

    sql <- sprintf("INSERT INTO project
                           (name, \"table\", status, memory)
                    VALUES ('%s', '%s', FALSE, '%s')
                    ON CONFLICT ON CONSTRAINT project_unique_name
                    DO UPDATE SET memory='%s'",
                    project, table, memory, memory)
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
#' @param status status to reset (e.g. working, failed, or all), all tasks if status = all
#' @param con connection to database
#'
#' @return no return
#' @export
project_reset <- function(project, status = c("working", "failed"), con = NULL) {
    if ("all" %in% status) {
        status <- c("working", "failed", "finished")
    }
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
    sql <- sprintf("SELECT project_resource.*, resource.name AS resource, resource.type
                        from project_resource
                        LEFT JOIN resource ON project_resource.resource_id = resource.id
                   where project_id='%s'",
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



#' Get project status
#'
#' @param project project name
#' @param con a connection to database
#'
#' @return no return
#' @export
project_status <- function(project, con = NULL) {
    project_info <- project_get(project, con = con)

    if (project_info$status) {
        message("Project is running...")
    } else {
        message("Project is stopped.")
    }
    message("Task status: ")
    tasks <- task_status(project, con = con)
    print(tasks)
    return(invisible())
}


