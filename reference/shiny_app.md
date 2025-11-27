# Launch Shiny App for Monitoring Projects

Starts an interactive Shiny application to monitor task progress and
runtime statistics for taskqueue projects.

## Usage

``` r
shiny_app()
```

## Value

Does not return while the app is running. Stops when the app is closed.

## Details

The Shiny app provides:

- Project selector dropdown

- Real-time task status table (updates every 5 seconds)

- Runtime distribution histogram for completed tasks

Useful for monitoring long-running projects and identifying performance
issues.

## See also

[`project_status`](https://taskqueue.bangyou.me/reference/project_status.md),
[`task_status`](https://taskqueue.bangyou.me/reference/task_status.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Launch monitoring app
shiny_app()
} # }
```
