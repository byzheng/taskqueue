# Stop a Project

Deactivates a project and cancels all running SLURM jobs associated with
it. Workers will terminate after completing their current task.

## Usage

``` r
project_stop(project)
```

## Arguments

- project:

  Character string specifying the project name.

## Value

Invisibly returns NULL. Called for side effects (stopping project and
jobs).

## Details

This function:

- Sets the project status to FALSE, preventing workers from taking new
  tasks

- Cancels all SLURM jobs associated with this project using `scancel`

- Resets the job list for all project resources

Active workers will complete their current task before shutting down.
Tasks in `working` status when the project stops should be reset to
`idle` using
[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md)
or [`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md).

## See also

[`project_start`](https://taskqueue.bangyou.me/reference/project_start.md),
[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md),
[`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Stop project and cancel all jobs
project_stop("simulation_study")

# Reset tasks that were in progress
task_reset("simulation_study", status = "working")
} # }
```
