# Clean All Tables and Definitions from Database

Removes all taskqueue-related tables, types, and data from the
PostgreSQL database. This is a destructive operation that cannot be
undone.

## Usage

``` r
db_clean()
```

## Value

Invisibly returns NULL. Called for side effects (dropping database
objects).

## Details

This function drops:

- All project task tables

- The `project_resource` table

- The `project` table

- The `resource` table

- All custom types (e.g., `task_status`)

**Warning:** This permanently deletes all projects, tasks, and
configurations. Use with extreme caution, typically only for testing or
complete resets.

After cleaning, you must call
[`db_init`](https://taskqueue.bangyou.me/reference/db_init.md) to
recreate the schema before using taskqueue again.

## See also

[`db_init`](https://taskqueue.bangyou.me/reference/db_init.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Clean entire database (destructive!)
db_clean()

# Reinitialize after cleaning
db_init()
} # }
```
