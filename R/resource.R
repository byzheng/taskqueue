
# Projects

# Create resource table if not exist
.table_resource <- function(con = NULL) {
    sql <- c("
        CREATE TABLE IF NOT EXISTS public.resource
        (
            id SERIAL NOT NULL,
            name character varying COLLATE pg_catalog.\"default\" NOT NULL,
            type character varying COLLATE pg_catalog.\"default\" NOT NULL,
            host character varying COLLATE pg_catalog.\"default\" NOT NULL,
            nodename character varying COLLATE pg_catalog.\"default\" NOT NULL,
            workers integer NOT NULL,
            log_folder character varying COLLATE pg_catalog.\"default\",
            CONSTRAINT resource_pkey PRIMARY KEY (id),
            CONSTRAINT resource_unique_name UNIQUE (name),
            CONSTRAINT resource_unique_host UNIQUE (host),
            CONSTRAINT resource_unique_namename UNIQUE (nodename)
        );")
    db_sql(sql, DBI::dbExecute, con)
    return(invisible())
}

resource_list <- function() {
    sql <- "SELECT * FROM resource where TRUE"
    con <- db_connect()
    resources <- DBI::dbGetQuery(con, sql)
    db_disconnect(con)
    resources
}

resource_get <- function(resource, con = NULL) {
    sql <- sprintf("SELECT * from resource where name='%s'", resource)
    r <- db_sql(sql, DBI::dbGetQuery, con)
    if (nrow(r) == 0) {
        stop("Cannot find resource: ", resource)
    }
    r
}


resource_add <- function(name,
                       table = paste('task', name, sep = '_'), ...)
{
    # if (length(name) != 1) {
    #     stop("Please use a single name")
    # }
    # conserved_name <- c("config")
    # if (name %in% conserved_name) {
    #     stop("Cannot use ", name)
    # }
    # con <- db_connect()
    # settings <- list(...)
    # settings$table <- table
    # settings$name <- name
    # setting_db <- as.character(lapply(settings,
    #                                   function(x)
    #                                   {
    #                                       x <- paste(x, collapse = ';')
    #                                       x <- gsub('\\\\', '\\\\\\\\', x)
    #                                       return(x)
    #                                   }))
    # names(setting_db) <- names(settings)
    # .table_taskconfig(con)
    #
    # tc_col <- DBI::dbGetQuery(con, 'select * from task_config where false;')
    # pos <- match(names(tc_col), names(setting_db))
    # setting_db <- setting_db[pos]
    # sql <- sprintf('INSERT INTO task_config (%s) VALUES (%s)  ON CONFLICT DO NOTHING',
    #                paste(sprintf('"%s"', names(setting_db)), collapse = ','),
    #                paste(sprintf('\'%s\'', setting_db), collapse = ','))
    # res <- DBI::dbExecute(con, sql)
    #
    # # create a new table
    # sql <- sprintf('CREATE TABLE IF NOT EXISTS %s (
    #      	"id" INTEGER NULL DEFAULT NULL,
    #     	"status" BOOLEAN NULL DEFAULT NULL,
    #     	PRIMARY KEY ("id")
    #     )
    #     ;', table)
    # res <- DBI::dbExecute(con, sql)
    # db_disconnect(con)
}

