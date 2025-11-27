# Get Task Status Summary

Returns a summary table showing the number and proportion of tasks in
each status for a project.

## Usage

``` r
task_status(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

A data frame with one row per status, containing:

- status:

  Task status: "idle", "working", "finished", or "failed"

- count:

  Number of tasks with this status (integer)

- ratio:

  Proportion of tasks with this status (numeric)

## Details

Task statuses:

- **idle** (NULL in database): Task not yet started

- **working**: Task currently being processed by a worker

- **finished**: Task completed successfully

- **failed**: Task encountered an error

Use this function to monitor progress and identify problems.

## See also

[`task_get`](https://taskqueue.bangyou.me/reference/task_get.md),
[`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md),
[`project_status`](https://taskqueue.bangyou.me/reference/project_status.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Check task status
status <- task_status("simulation_study")
print(status)

# Calculate completion percentage
finished <- status$count[status$status == "finished"]
total <- sum(status$count)
pct_complete <- 100 * finished / total
} # }
```
