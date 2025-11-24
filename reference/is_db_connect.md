# Test Database Connection

Checks whether a connection to the PostgreSQL database can be
established with the current configuration.

## Usage

``` r
is_db_connect()
```

## Value

Logical. `TRUE` if the database can be connected successfully, `FALSE`
otherwise.

## Details

This function attempts to create a database connection using the
credentials in environment variables or
[`taskqueue_options()`](https://taskqueue.bangyou.me/reference/taskqueue_options.md).
It returns FALSE if the connection fails for any reason (wrong
credentials, network issues, PostgreSQL not running, etc.).

Useful for testing database configuration before running workers or
adding tasks.

## See also

[`db_connect`](https://taskqueue.bangyou.me/reference/db_connect.md),
[`taskqueue_options`](https://taskqueue.bangyou.me/reference/taskqueue_options.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Test connection
if (is_db_connect()) {
  message("Database is accessible")
  db_init()
} else {
  stop("Cannot connect to database. Check .Renviron settings.")
}
} # }
```
