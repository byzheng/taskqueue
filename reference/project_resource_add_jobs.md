# Manage SLURM Job List for Project Resource

Adds a SLURM job name to the list of active jobs for a project-resource
association, or resets the job list.

## Usage

``` r
project_resource_add_jobs(project, resource, job, reset = FALSE)
```

## Arguments

- project:

  Character string specifying the project name.

- resource:

  Character string specifying the resource name.

- job:

  Character string with the SLURM job name to add. If missing, the job
  list is reset to empty.

- reset:

  Logical indicating whether to clear the job list before adding.
  Default is FALSE. If TRUE, replaces all jobs with `job`.

## Value

Invisibly returns NULL. Called for side effects (updating job list).

## Details

The job list is a semicolon-separated string of SLURM job names stored
in the database. This list is used by
[`project_stop`](https://taskqueue.bangyou.me/reference/project_stop.md)
to cancel all jobs when stopping a project.

Job names are automatically added by
[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md)
when submitting workers.

Currently only supports SLURM resources.

## See also

[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md),
[`project_stop`](https://taskqueue.bangyou.me/reference/project_stop.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Add a job (typically done automatically by worker_slurm)
project_resource_add_jobs("simulation_study", "hpc", "job_12345")

# Reset job list
project_resource_add_jobs("simulation_study", "hpc", reset = TRUE)
} # }
```
