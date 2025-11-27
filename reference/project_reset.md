# Reset a Project

Resets all tasks in a project to idle status, stops the project, and
optionally cleans log files. Useful for restarting a project from
scratch.

## Usage

``` r
project_reset(project, log_clean = TRUE)
```

## Arguments

- project:

  Character string specifying the project name.

- log_clean:

  Logical indicating whether to delete log files. Default is TRUE.

## Value

Invisibly returns NULL. Called for side effects (resetting tasks and
logs).

## Details

This function performs three operations:

1.  Resets all tasks to idle status (NULL) using
    [`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md)

2.  Stops the project using
    [`project_stop`](https://taskqueue.bangyou.me/reference/project_stop.md)

3.  Optionally deletes all log files from resource log folders

Use this when you want to:

- Restart failed tasks

- Re-run all tasks after fixing code

- Clean up before redeploying workers

**Warning:** Setting `log_clean = TRUE` permanently deletes all log
files, which may contain useful debugging information.

## See also

[`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md),
[`project_stop`](https://taskqueue.bangyou.me/reference/project_stop.md),
[`project_start`](https://taskqueue.bangyou.me/reference/project_start.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Reset project and clean logs
project_reset("simulation_study")

# Reset but keep logs for debugging
project_reset("simulation_study", log_clean = FALSE)

# Restart after reset
project_start("simulation_study")
worker_slurm("simulation_study", "hpc", fun = my_function)
} # }
```
