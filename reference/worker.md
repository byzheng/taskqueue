# Execute a job on cluster

A worker will listen task channel to get a new job, run this job and
mark job is finished until get a shutdown message to stop this function.

## Usage

``` r
worker(project, fun, ...)
```

## Arguments

- project:

  project name

- fun:

  function to run actual works which will take task id as the first
  argument

- ...:

  other arguments passed to fun

## Value

No return is expected from this function

## Examples

``` r
if (FALSE) { # \dontrun{
worker("test_project", mean)
} # }
```
