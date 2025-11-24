# Remove All Tasks from a Project

Deletes all tasks from a project's task table. This is a destructive
operation that removes all task data and history.

## Usage

``` r
task_clean(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (truncating task table).

## Details

Uses SQL TRUNCATE to efficiently remove all rows from the task table.
This is faster than DELETE but cannot be rolled back.

**Warning:** All task history, including completion status and runtime
information, will be permanently lost.

This function is automatically called by
[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md) when
`clean = TRUE`.

## See also

[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md),
[`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Remove all tasks
task_clean("simulation_study")

# Add new tasks
task_add("simulation_study", num = 200)
} # }
```
