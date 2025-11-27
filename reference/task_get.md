# Get Detailed Task Information

Retrieves detailed information about tasks with specified statuses,
including execution times and error messages.

## Usage

``` r
task_get(project, status = c("failed"), limit = 10, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- status:

  Character vector of statuses to retrieve. Can include "working",
  "failed", "finished", or "all". Default is "failed".

- limit:

  Maximum number of tasks to return (integer). Default is 10.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

A data frame with detailed task information:

- id:

  Task ID

- status:

  Current status

- start:

  Start timestamp

- finish:

  Finish timestamp

- message:

  Error message (for failed tasks) or NULL

- runtime:

  Calculated runtime in seconds

## Details

Useful for:

- Debugging failed tasks (examine error messages)

- Analyzing runtime patterns

- Identifying slow tasks

The `runtime` column is calculated as the difference between finish and
start times in seconds.

Specifying `status = "all"` returns tasks of any status.

## See also

[`task_status`](https://taskqueue.bangyou.me/reference/task_status.md),
[`task_reset`](https://taskqueue.bangyou.me/reference/task_reset.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Get first 10 failed tasks
failed <- task_get("simulation_study", status = "failed")
print(failed$message)  # View error messages

# Get all finished tasks
finished <- task_get("simulation_study", status = "finished", limit = 1000)
hist(finished$runtime, main = "Task Runtime Distribution")

# Get tasks of any status
all_tasks <- task_get("simulation_study", status = "all", limit = 50)
} # }
```
