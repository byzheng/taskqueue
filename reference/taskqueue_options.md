# Set or Get taskqueue Options

Configure or retrieve database connection parameters for taskqueue.
Options are typically set via environment variables in `.Renviron`, but
can be overridden programmatically.

## Usage

``` r
taskqueue_options(...)
```

## Arguments

- ...:

  Option names to retrieve values (as strings), or key=value pairs to
  set options. All option names must be specified.

## Value

If no arguments: list of all option values. If argument names only: list
of specified option values. If setting values: invisibly returns updated
options.

## Details

By default, options are read from environment variables set in
`~/.Renviron`. Use this function to override defaults temporarily or
check current settings.

Changes are session-specific and don't modify environment variables.

## Supported options

- host:

  PostgreSQL server hostname or IP address (from PGHOST)

- port:

  PostgreSQL server port, typically 5432 (from PGPORT)

- user:

  Database username (from PGUSER)

- password:

  Database password (from PGPASSWORD)

- database:

  Database name (from PGDATABASE)

## See also

[`taskqueue_reset`](https://taskqueue.bangyou.me/reference/taskqueue_reset.md),
[`db_connect`](https://taskqueue.bangyou.me/reference/db_connect.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# View all current options
taskqueue_options()

# Get specific option
taskqueue_options("host")

# Set options (temporary override)
taskqueue_options(host = "localhost", port = 5432)

# Reset to environment variable values
taskqueue_reset()
} # }
```
