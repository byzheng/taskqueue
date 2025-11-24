# Disconnect from PostgreSQL Database

Safely closes a database connection. Checks if the connection is valid
before attempting to disconnect.

## Usage

``` r
db_disconnect(con)
```

## Arguments

- con:

  A connection object as produced by
  [`db_connect`](https://taskqueue.bangyou.me/reference/db_connect.md)
  or [`DBI::dbConnect`](https://dbi.r-dbi.org/reference/dbConnect.html).

## Value

Invisibly returns NULL. Called for side effects.

## Details

This function wraps `RPostgres::dbDisconnect()` with a validity check to
avoid errors when disconnecting an already-closed connection.

## See also

[`db_connect`](https://taskqueue.bangyou.me/reference/db_connect.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Connect and disconnect
con <- db_connect()
# ... perform database operations ...
db_disconnect(con)

# Safe to call on.exit to ensure cleanup
con <- db_connect()
on.exit(db_disconnect(con), add = TRUE)
} # }
```
