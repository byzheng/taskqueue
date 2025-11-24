# Get tasks by status

Get tasks by status

## Usage

``` r
task_get(project, status = c("failed"), limit = 10, con = NULL)
```

## Arguments

- project:

  project name

- status:

  status to reset (e.g. working, failed, or all), all tasks if status =
  all

- limit:

  number of rows to return

- con:

  connection to database

## Value

A data frame of tasks
