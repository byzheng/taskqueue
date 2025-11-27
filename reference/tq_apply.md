# Apply a Function with Task Queue (Simplified Workflow)

A high-level interface for running embarrassingly parallel tasks on HPC
clusters. Combines project creation, task addition, and worker
scheduling into a single function call, similar to `lapply`.

## Usage

``` r
tq_apply(
  n,
  fun,
  project,
  resource,
  memory = 10,
  hour = 24,
  account = NULL,
  working_dir = getwd(),
  ...
)
```

## Arguments

- n:

  Integer specifying the number of tasks to run. Your function will be
  called with arguments 1, 2, ..., n.

- fun:

  Function to execute for each task. Must accept the task ID as its
  first argument. Should save results to disk.

- project:

  Character string for project name. Will be created if it doesn't
  exist, updated if it does.

- resource:

  Character string for resource name. Must already exist (created via
  [`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md)).

- memory:

  Memory requirement in GB for each task. Default is 10 GB.

- hour:

  Maximum runtime in hours for worker jobs. Default is 24 hours.

- account:

  Optional character string for SLURM account/allocation. Default is
  NULL.

- working_dir:

  Working directory on the cluster where tasks execute. Default is
  current directory ([`getwd()`](https://rdrr.io/r/base/getwd.html)).

- ...:

  Additional arguments passed to `fun` for every task.

## Value

Invisibly returns NULL. Called for side effects (scheduling workers).

## Details

This function automates the standard taskqueue workflow:

1.  Creates or updates the project with specified memory

2.  Assigns the resource to the project

3.  Adds `n` tasks (cleaning any existing tasks)

4.  Resets all tasks to idle status

5.  Schedules workers on the SLURM cluster

Equivalent to manually calling:

    project_add(project, memory = memory)
    project_resource_add(project, resource, working_dir, account, hour, n)
    task_add(project, n, clean = TRUE)
    project_reset(project)
    worker_slurm(project, resource, fun = fun, ...)

**Before using tq_apply:**

- Initialize database:
  [`db_init()`](https://taskqueue.bangyou.me/reference/db_init.md)

- Create resource: `resource_add(...)`

- Configure `.Renviron` with database credentials

Your worker function should:

- Take task ID as first argument

- Save results to files (not return values)

- Be idempotent (check if output exists)

## See also

[`worker`](https://taskqueue.bangyou.me/reference/worker.md),
[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md),
[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md),
[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Simple example
my_simulation <- function(i, param) {
  out_file <- sprintf("results/sim_%04d.Rds", i)
  if (file.exists(out_file)) return()
  result <- run_simulation(i, param)
  saveRDS(result, out_file)
}

# Run 100 simulations on HPC
tq_apply(
  n = 100,
  fun = my_simulation,
  project = "my_study",
  resource = "hpc",
  memory = 16,
  hour = 6,
  param = 5
)

# Monitor progress
project_status("my_study")
task_status("my_study")
} # }
```
