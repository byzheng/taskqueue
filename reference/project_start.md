# Start a Project

Activates a project to allow workers to begin consuming tasks. Workers
will only process tasks from started projects.

## Usage

``` r
project_start(project, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (updating project
status).

## Details

Starting a project sets its `status` field to TRUE in the database.
Workers check this status before requesting new tasks. If a project is
stopped (status = FALSE), workers will terminate instead of processing
tasks.

You must start a project before deploying workers with
[`worker`](https://taskqueue.bangyou.me/reference/worker.md) or
[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md).

## See also

[`project_stop`](https://taskqueue.bangyou.me/reference/project_stop.md),
[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`worker`](https://taskqueue.bangyou.me/reference/worker.md),
[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Start project to enable workers
project_start("simulation_study")

# Deploy workers after starting
worker_slurm("simulation_study", "hpc", fun = my_function)
} # }
```
