# List All Computing Resources

Retrieves all computing resources registered in the database.

## Usage

``` r
resource_list()
```

## Value

A data frame containing information about all resources, with columns:

- id:

  Unique resource identifier

- name:

  Resource name

- type:

  Resource type (e.g., "slurm", "computer")

- host:

  Hostname or IP address

- username:

  Username for SSH connection

- nodename:

  Node name as reported by Sys.info()

- workers:

  Maximum number of concurrent workers

- log_folder:

  Absolute path to log file directory

## See also

[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md),
[`resource_get`](https://taskqueue.bangyou.me/reference/resource_get.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# List all resources
resources <- resource_list()
print(resources)

# Find SLURM resources
slurm_resources <- resources[resources$type == "slurm", ]
} # }
```
