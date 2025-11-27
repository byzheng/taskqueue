# Connect to PostgreSQL Database

Establishes a connection to the PostgreSQL database using credentials
from environment variables or
[`taskqueue_options()`](https://taskqueue.bangyou.me/reference/taskqueue_options.md).
If a valid connection is provided, it returns that connection instead of
creating a new one.

## Usage

``` r
db_connect(con = NULL)
```

## Arguments

- con:

  An existing database connection object. If provided and valid, this
  connection is returned. If NULL (default), a new connection is
  created.

## Value

A PqConnection object from the RPostgres package that can be used for
database operations.

## Details

Connection parameters are read from environment variables set in
`.Renviron`:

- `PGHOST`: Database server hostname

- `PGPORT`: Database server port (typically 5432)

- `PGUSER`: Database username

- `PGPASSWORD`: Database password

- `PGDATABASE`: Database name

The function automatically sets `client_min_messages` to WARNING to
reduce console output noise.

## See also

[`db_disconnect`](https://taskqueue.bangyou.me/reference/db_disconnect.md),
[`taskqueue_options`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Not run:
# Create a new connection
con <- db_connect()

# Reuse existing connection
con2 <- db_connect(con)

# Always disconnect when done
db_disconnect(con)
} # }
```
