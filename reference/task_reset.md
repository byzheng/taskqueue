# Reset status of all tasks in a project to NULL

Reset status of all tasks in a project to NULL

## Usage

``` r
task_reset(project, status = c("working", "failed"), con = NULL)
```

## Arguments

- project:

  project name

- status:

  status to reset (e.g. working, failed, or all), all tasks if status =
  all

- con:

  connection to database

## Value

no return
