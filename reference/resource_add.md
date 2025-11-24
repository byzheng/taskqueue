# Add a new resource

Add a new resource

## Usage

``` r
resource_add(
  name,
  type = c("slurm", "computer"),
  host,
  workers,
  log_folder,
  username = NULL,
  nodename = strsplit(host, "\\.")[[1]][1],
  con = NULL
)
```

## Arguments

- name:

  resource name

- type:

  resource type (e.g. slurm or computer)

- host:

  host name

- workers:

  worker number

- log_folder:

  log folder which has to be absolute path.

- username:

  username to login the host. If null, the user from Sys.info is used.

- nodename:

  nodename obtained by Sys.info()

- con:

  a db connection

## Value

no return
