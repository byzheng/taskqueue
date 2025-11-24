# Add a New Computing Resource

Registers a new computing resource (HPC cluster or computer) in the
database for use with taskqueue projects.

## Usage

``` r
resource_add(
  name,
  type = c("slurm", "computer"),
  host,
  workers,
  log_folder,
  username = NULL,
  nodename = strsplit(host, "\\.")[[1]][1],
  con = NULL
)
```

## Arguments

- name:

  Character string for the resource name. Must be unique.

- type:

  Type of resource. Currently supported: `"slurm"` for SLURM clusters or
  `"computer"` for standalone machines.

- host:

  Hostname or IP address of the resource. For SLURM clusters, this
  should be the login/head node.

- workers:

  Maximum number of concurrent workers/cores available on this resource
  (integer).

- log_folder:

  Absolute path to the directory where log files will be stored. Must be
  an absolute path (Linux or Windows format). Directory will contain
  subdirectories for each project.

- username:

  Username for SSH connection to the resource. If NULL (default), uses
  the current user from `Sys.info()["user"]`.

- nodename:

  Node name as obtained by `Sys.info()["nodename"]` on the resource.
  Default extracts the hostname from `host`.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

Invisibly returns NULL. Called for side effects (adding resource to
database).

## Details

The `log_folder` is critical for troubleshooting. It stores:

- SLURM job output and error files

- Task execution logs

- R worker scripts

Choose a high-speed storage location if possible due to frequent I/O
operations.

If a resource with the same `name` already exists, this function will
fail due to uniqueness constraints.

## See also

[`resource_get`](https://taskqueue.bangyou.me/reference/resource_get.md),
[`resource_list`](https://taskqueue.bangyou.me/reference/resource_list.md),
[`project_resource_add`](https://taskqueue.bangyou.me/reference/project_resource_add.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Add a SLURM cluster resource
resource_add(
  name = "hpc",
  type = "slurm",
  host = "hpc.university.edu",
  workers = 500,
  log_folder = "/home/user/taskqueue_logs/"
)

# Add with explicit username
resource_add(
  name = "hpc2",
  type = "slurm",
  host = "cluster.lab.org",
  workers = 200,
  log_folder = "/scratch/taskqueue/logs/",
  username = "johndoe"
)

# Verify resource was added
resource_list()
} # }
```
