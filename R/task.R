# function related with tasks

task_add <- function(name, num) {
    values <- paste(paste("(", seq_len(num), ")", sep = ""), collapse = ", ")
    sql <- sprintf("
        INSERT INTO task_%s
        (id) VALUES %s
        ON CONFLICT DO NOTHING
    ;", name, values)
    con <- db_connect()
    DBI::dbExecute(con, sql)
    db_disconnect(con)
}

task_count <- function(name) {

}

task_clean <- function(name) {
    sql <- sprintf("TRUNCATE TABLE task_%s;", name)
    con <- db_connect()
    DBI::dbExecute(con, sql)
    db_disconnect(con)
}
