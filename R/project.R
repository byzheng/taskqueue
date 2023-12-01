
# Projects

# Create task table if not exist
.table_taskconfig <- function(con) {
    DBI::dbExecute(con, "
        CREATE TABLE IF NOT EXISTS \"project\" (
        	\"id\" SERIAL NOT NULL,
        	\"name\" VARCHAR NOT NULL,
        	\"table\" VARCHAR NOT NULL,
        	\"status\" BOOLEAN NULL DEFAULT NULL,
        	PRIMARY KEY (\"id\")
        )
        ;
    ")
}


#' Create project to database
#'
#' @param project project name
#' @param table A table name for this project.
#' @param ... Other arguments for project setting
#' @export
project_add <- function(project,
                       table = paste('task', project, sep = '_'), ...)
{
    if (length(project) != 1) {
        stop("Please use a single name")
    }
    conserved_name <- c("config")
    if (project %in% conserved_name) {
        stop("Cannot use ", project)
    }
    con <- db_connect()
    settings <- list(...)
    settings$table <- table
    settings$name <- project
    settings$status <- FALSE
    setting_db <- as.character(lapply(settings,
                                      function(x)
                                      {
                                          x <- paste(x, collapse = ';')
                                          x <- gsub('\\\\', '\\\\\\\\', x)
                                          return(x)
                                      }))
    names(setting_db) <- names(settings)
    .table_taskconfig(con)

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
        	"status" BOOLEAN NULL DEFAULT NULL,
        	PRIMARY KEY ("id")
        )
        ;', table)
    res <- DBI::dbExecute(con, sql)
    db_disconnect(con)
}



#' Start a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return
#' @export
project_start <- function(project, con = NULL) {
    sql <- sprintf("UPDATE project SET status=TRUE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
}


#' Stop a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return
#' @export
project_stop <- function(project, con = NULL) {
    sql <- sprintf("UPDATE project SET status=FALSE where name='%s'", project)
    db_sql(sql, DBI::dbExecute, con)
}

#' Reset status of all tasks in a project to NULL
#'
#' @param project project name
#' @param con connection to database
#'
#' @return
#' @export
project_reset <- function(project, con = NULL) {
    sql <- sprintf("UPDATE task_%s SET status=NULL WHERE TRUE", project)
    a <- db_sql(sql, DBI::dbExecute, con)
}
#' Get a project
#'
#' @param project project name
#' @param con connection to database
#'
#' @return
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
#' @return
#' @export
project_resource_get <- function(project, con = NULL) {
    project_info <- project_get(project, con)
    sql <- sprintf("SELECT * from project_resource where project_id='%s'",
                   project_info$id)
    p_r <- db_sql(sql, DBI::dbGetQuery, con)
    p_r
}

project_list <- function() {

}

project_delete <- function(project, con = NULL) {

}
