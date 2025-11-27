# Get Information for a Specific Resource

Retrieves detailed information about a single computing resource by
name.

## Usage

``` r
resource_get(resource, con = NULL)
```

## Arguments

- resource:

  Character string specifying the resource name.

- con:

  An optional database connection. If NULL, a new connection is created
  and closed automatically.

## Value

A single-row data frame containing resource information. Stops with an
error if the resource is not found.

## Details

The returned data frame contains all resource configuration details
needed for worker deployment, including connection information and
resource limits.

## See also

[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md),
[`resource_list`](https://taskqueue.bangyou.me/reference/resource_list.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Get specific resource
hpc_info <- resource_get("hpc")
print(hpc_info$workers)  # Maximum workers
print(hpc_info$log_folder)  # Log directory
} # }
```
