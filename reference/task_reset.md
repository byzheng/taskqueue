# Reset Task Status to Idle

Resets tasks with specified statuses back to idle (NULL) state, clearing
their execution history. This allows them to be picked up by workers
again.

## Usage

``` r
task_reset(project, status = c("working", "failed"), con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- status:

  Character vector of statuses to reset. Can include "working",
  "failed", "finished", or "all". Default is c("working", "failed").

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (resetting task status).

## Details

Resetting tasks clears:

- Status (set to NULL/idle)

- Start time

- Finish time

- Error messages

Common use cases:

- Reset failed tasks after fixing code: `status = "failed"`

- Reset interrupted tasks: `status = "working"`

- Re-run everything: `status = "all"`

Specifying `status = "all"` resets all tasks regardless of current
status.

## See also

[`task_status`](https://taskqueue.bangyou.me/reference/task_status.md),
[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md),
[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Reset only failed tasks
task_reset("simulation_study", status = "failed")

# Reset working tasks (e.g., after project_stop)
task_reset("simulation_study", status = "working")

# Reset all tasks to start over
task_reset("simulation_study", status = "all")

# Check status after reset
task_status("simulation_study")
} # }
```
