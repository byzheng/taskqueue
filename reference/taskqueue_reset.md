# Reset taskqueue Options to Defaults

Resets all taskqueue options to their default values from environment
variables.

## Usage

``` r
taskqueue_reset()
```

## Value

Invisibly returns NULL. Called for side effects (resetting options).

## Details

This function restores options to the values specified in environment
variables (PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE). Any
programmatic changes made via
[`taskqueue_options`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)
are discarded.

Useful after temporarily modifying connection parameters.

## See also

[`taskqueue_options`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)

## Examples

``` r
# Override options temporarily
taskqueue_options(host = "test.server.com")

# Reset to environment variable values
taskqueue_reset()
```
