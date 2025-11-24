# Apply a function with task queue

Apply a function with task queue

## Usage

``` r
tq_apply(
  n,
  fun,
  project,
  resource,
  memory = 10,
  hour = 24,
  account = NULL,
  working_dir = getwd(),
  ...
)
```

## Arguments

- n:

  Number of task

- fun:

  A function

- project:

  Project name

- resource:

  Resource name

- memory:

  Memory in GB

- hour:

  Maximum runtime in cluster

- account:

  Optional. Account for cluster

- working_dir:

  Working directory in cluster

- ...:

  Other arguments for fun

## Value

No return values
