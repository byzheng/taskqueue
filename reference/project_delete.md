# Delete a Project

Permanently removes a project and all associated data from the database.
This includes the project configuration, task table, and resource
assignments.

## Usage

``` r
project_delete(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (deleting project).

## Details

This function removes:

- The project's task table (`task_<project>`) and all tasks

- All project-resource associations

- The project entry from the project table

**Warning:** This is a destructive operation that cannot be undone. All
task data and history for this project will be permanently lost.

Log files on resources are NOT automatically deleted. Remove them
manually if needed.

## See also

[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md),
[`db_clean`](https://taskqueue.bangyou.me/reference/db_clean.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Delete a completed project
project_delete("old_simulation")

# Verify deletion
project_list()
} # }
```
