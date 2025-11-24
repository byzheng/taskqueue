# Create a worker on slurm cluster

Create a worker on slurm cluster

## Usage

``` r
worker_slurm(
  project,
  resource,
  fun,
  rfile,
  module_r = "R/4.3.1",
  module_pg = "postgresql/16.0",
  modules = NULL,
  pkgs = rev(.packages()),
  submit = TRUE,
  ...
)
```

## Arguments

- project:

  Project name.

- resource:

  Resource name.

- fun:

  Function running on workers. See details.

- rfile:

  R script file path. See details.

- module_r:

  Module name for R.

- module_pg:

  Module name for postgresql. See details.

- modules:

  extra modules to load in slurm. See details.

- pkgs:

  A character vector containing the names of packages that must be
  loaded on worker including all packages in default when `worker_slurm`
  is called.

- submit:

  Whether to submit to slurm cluster (TRUE in default). See details.

- ...:

  Extra arguments for fun.

## Value

no return

## Details

There are two ways to pass R scripts into workers (i.e. `fun` or
`file`). \* `fun` is used for general and simple case which takes the
task id as the first argument. A new r script is created in the log
folder and running in the workers. The required packages are passed
using `pkgs`. Extra arguments are specified through `...`.
[`taskqueue_options()`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)
is passed into workers. \* `rfile` is used more complicated case.
Function `worker` has to be called at the end of file. No
[`taskqueue_options()`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)
is passed into workers. \* `fun` is higher priority with `file`. A
submit file is created in the log folder for each project/resource with
random file name. Then system command `ssh` is used to connect remote
slurm host if `submit = TRUE`.

## Examples

``` r
if (FALSE) { # \dontrun{
fun_test <- function(i, prefix) {
    Sys.sleep(runif(1) * 2)
}
worker_slurm("test_project", "slurm", fun = fun_test)
worker_slurm("test_project", "slurm", fun = fun_test, prefix = "a")
worker_slurm("test_project", "slurm", rfile = "rfile.R")
worker_slurm("test_project", "slurm", fun = fun_test, submit = FALSE)
} # }
```
