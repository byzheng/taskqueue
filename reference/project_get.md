# Get Project Information

Retrieves detailed information about a specific project from the
database.

## Usage

``` r
project_get(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

A single-row data frame containing project information with columns:

- id:

  Unique project identifier

- name:

  Project name

- table:

  Name of the task table for this project

- status:

  Logical indicating if project is running (TRUE) or stopped (FALSE)

- memory:

  Memory requirement in GB for tasks

Stops with an error if the project is not found.

## See also

[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`project_list`](https://taskqueue.bangyou.me/reference/project_list.md),
[`project_resource_get`](https://taskqueue.bangyou.me/reference/project_resource_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Get project details
info <- project_get("simulation_study")
print(info$status)  # Check if running
print(info$memory)  # Memory requirement
} # }
```
