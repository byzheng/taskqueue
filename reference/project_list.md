# List All Projects

Retrieves information about all projects in the database.

## Usage

``` r
project_list(con = NULL)
```

## Arguments

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

A data frame with one row per project, or NULL if no projects exist.
Columns include: id, name, table, status, and memory.

## Details

Returns NULL if the project table doesn't exist (i.e.,
[`db_init`](https://taskqueue.bangyou.me/reference/db_init.md) has not
been called).

## See also

[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`project_get`](https://taskqueue.bangyou.me/reference/project_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# List all projects
projects <- project_list()
print(projects)

# Find running projects
running <- projects[projects$status == TRUE, ]
} # }
```
