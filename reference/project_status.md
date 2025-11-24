# Display Project Status

Prints a summary of project status including whether it's running and
the current status of all tasks.

## Usage

``` r
project_status(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (printing status).

## Details

Displays:

- Whether the project is running or stopped

- Task status summary from
  [`task_status`](https://taskqueue.bangyou.me/reference/task_status.md)

Use this function to monitor progress and identify failed tasks.

## See also

[`task_status`](https://taskqueue.bangyou.me/reference/task_status.md),
[`project_get`](https://taskqueue.bangyou.me/reference/project_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Check project status
project_status("simulation_study")
} # }
```
