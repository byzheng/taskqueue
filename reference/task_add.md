# Add Tasks to a Project

Creates a specified number of tasks in a project's task table. Each task
is assigned a unique ID and initially has idle (NULL) status.

## Usage

``` r
task_add(project, num, clean = TRUE, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- num:

  Integer specifying the number of tasks to create.

- clean:

  Logical indicating whether to delete existing tasks before adding new
  ones. Default is TRUE.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (adding tasks to
database).

## Details

Tasks are created with sequential IDs from 1 to `num`. Each task
initially has NULL status (idle) and will be assigned to workers after
the project is started.

If `clean = TRUE`, all existing tasks are removed using
[`task_clean`](https://taskqueue.bangyou.me/reference/task_clean.md)
before adding new tasks. If FALSE, new tasks are added but existing
tasks remain (duplicates are ignored due to primary key constraints).

Your worker function will receive the task ID as its first argument.

## See also

[`task_clean`](https://taskqueue.bangyou.me/reference/task_clean.md),
[`task_status`](https://taskqueue.bangyou.me/reference/task_status.md),
[`worker`](https://taskqueue.bangyou.me/reference/worker.md),
[`project_start`](https://taskqueue.bangyou.me/reference/project_start.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Add 100 tasks to a project
task_add("simulation_study", num = 100)

# Add tasks without cleaning existing ones
task_add("simulation_study", num = 50, clean = FALSE)

# Check task status
task_status("simulation_study")
} # }
```
