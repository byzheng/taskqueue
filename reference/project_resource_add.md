# Assign a Resource to a Project

Associates a computing resource with a project and configures
resource-specific settings like working directory, runtime limits, and
worker count.

## Usage

``` r
project_resource_add(
  project,
  resource,
  working_dir,
  account = NULL,
  hours = 1,
  workers = NULL
)
```

## Arguments

- project:

  Character string specifying the project name.

- resource:

  Character string specifying the resource name.

- working_dir:

  Absolute path to the working directory on the resource where workers
  will execute.

- account:

  Optional character string for the account/allocation to use on the
  resource (relevant for SLURM clusters with accounting). Default is
  NULL.

- hours:

  Maximum runtime in hours for each worker job. Default is 1 hour.

- workers:

  Maximum number of concurrent workers for this project on this
  resource. If NULL, uses the resource's maximum worker count.

## Value

Invisibly returns NULL. Called for side effects (adding/updating
project-resource association).

## Details

This function creates or updates the association between a project and
resource. Each project can be associated with multiple resources, and
settings are resource-specific.

If the project-resource association already exists, only the specified
parameters are updated.

The `working_dir` should exist on the resource and contain any necessary
input files or scripts.

The `hours` parameter sets the SLURM walltime for worker jobs. Workers
will automatically terminate before this limit to avoid being killed
mid-task.

## See also

[`project_add`](https://taskqueue.bangyou.me/reference/project_add.md),
[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md),
[`worker_slurm`](https://taskqueue.bangyou.me/reference/worker_slurm.md),
[`project_resource_get`](https://taskqueue.bangyou.me/reference/project_resource_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Assign resource to project with basic settings
project_resource_add(
  project = "simulation_study",
  resource = "hpc",
  working_dir = "/home/user/simulations"
)

# Assign with specific account and time limit
project_resource_add(
  project = "big_analysis",
  resource = "hpc",
  working_dir = "/scratch/project/data",
  account = "research_group",
  hours = 48,
  workers = 100
)
} # }
```
