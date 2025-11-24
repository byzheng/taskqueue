# Execute Tasks as a Worker

Runs as a worker process that continuously fetches and executes tasks
from a project until no tasks remain or the project is stopped.

## Usage

``` r
worker(project, fun, ...)
```

## Arguments

- project:

  Character string specifying the project name.

- fun:

  Function to execute for each task. Must accept the task ID as its
  first argument. The function should save its results to disk and is
  not expected to return a value.

- ...:

  Additional arguments passed to `fun` for every task.

## Value

Does not return normally. Stops when: no more tasks are available, the
project is stopped, or runtime limit is reached (SLURM only).

## Details

This function implements the worker loop:

1.  Request a task from the database (atomically)

2.  Update task status to "working"

3.  Execute `fun(task_id, ...)`

4.  Update task status to "finished" (or "failed" if error)

5.  Repeat until no more tasks or stopping condition

Workers automatically:

- Add random delays to reduce database contention

- Track runtime to respect SLURM walltime limits

- Reconnect to database on connection failures

- Log progress and errors to console

Your worker function should:

- Check if output already exists (idempotent)

- Save results to disk (not return them)

- Handle errors gracefully or let them propagate

For SLURM resources, set the `TASKQUEUE_RESOURCE` environment variable
to enable automatic walltime management.

## See also

[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md),
[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md),
[`project_start`](https://taskqueue.bangyou.me/reference/project_start.md),
[`tq_apply`](https://taskqueue.bangyou.me/reference/tq_apply.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Define worker function
my_task <- function(task_id, param1, param2) {
  out_file <- sprintf("results/task_%04d.Rds", task_id)
  if (file.exists(out_file)) return()  # Skip if done
 
  result <- expensive_computation(task_id, param1, param2)
  saveRDS(result, out_file)
}

# Run worker locally (for testing)
worker("test_project", my_task, param1 = 10, param2 = "value")
} # }
```
