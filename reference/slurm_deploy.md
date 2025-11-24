# Deploy taskqueue Package to SLURM Resources

Installs or updates the taskqueue package on all registered SLURM
resources by connecting via SSH and installing from GitHub.

## Usage

``` r
slurm_deploy()
```

## Value

Invisibly returns NULL. Called for side effects (installing package on
remote resources).

## Details

For each SLURM resource in the database, this function:

1.  Connects via SSH to the resource host

2.  Loads the R module (currently hardcoded as R/4.3.1)

3.  Installs taskqueue from GitHub using devtools

**Requirements:**

- SSH access to all SLURM resources

- R and devtools installed on each resource

- Internet access from resources to reach GitHub

**Note:** The R module name is currently hardcoded. Modify the function
if your resources use different module names.

## See also

[`resource_add`](https://taskqueue.bangyou.me/reference/resource_add.md),
[`resource_list`](https://taskqueue.bangyou.me/reference/resource_list.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Deploy to all SLURM resources
slurm_deploy()
} # }
```
