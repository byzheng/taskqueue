# Initialize PostgreSQL Database for taskqueue

Creates the necessary database schema for taskqueue, including all
required tables, types, and constraints. This function must be run once
before using taskqueue for the first time.

## Usage

``` r
db_init()
```

## Value

Invisibly returns NULL. Called for side effects (creating database
schema).

## Details

This function creates:

- Custom PostgreSQL types (e.g., `task_status` enum)

- `project` table for managing projects

- `resource` table for computing resources

- `project_resource` table for project-resource associations

It is safe to call this function multiple times; existing tables and
types will not be modified or deleted.

## See also

[`db_clean`](https://taskqueue.bangyou.me/reference/db_clean.md),
[`db_connect`](https://taskqueue.bangyou.me/reference/db_connect.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Initialize database (run once)
db_init()

# Verify initialization
con <- db_connect()
DBI::dbListTables(con)
db_disconnect(con)
} # }
```
