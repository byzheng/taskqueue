# Delete Log Files for a Project Resource

Removes all log files from the resource's log folder for a specific
project. Log files include SLURM output/error files and worker scripts.

## Usage

``` r
project_resource_log_delete(project, resource, con = NULL)
```

## Arguments

- project:

  Character string specifying the project name.

- resource:

  Character string specifying the resource name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (deleting log files).

## Details

Deletes all files matching the pattern `<project>-<resource>*` from the
log folder specified in the resource configuration.

Currently only supports SLURM resources.

This function is automatically called by
[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md)
when `log_clean = TRUE`.

## See also

[`project_reset`](https://taskqueue.bangyou.me/reference/project_reset.md),
[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Delete logs for specific project-resource
project_resource_log_delete("simulation_study", "hpc")
} # }
```
