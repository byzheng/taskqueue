# PostgreSQL Setup for taskqueue

## Overview

The `taskqueue` package uses PostgreSQL to manage tasks, projects, and
workers. This vignette shows how to install and configure PostgreSQL on
Ubuntu for HPC environments.

PostgreSQL should be installed on a server that all worker nodes can
access.

## Why PostgreSQL?

PostgreSQL is chosen for `taskqueue` because:

- **Concurrent Access**: Handles large numbers of concurrent requests
  from multiple workers
- **ACID Compliance**: Ensures data integrity for task status updates
- **Reliability**: Proven track record for production workloads
- **Performance**: Efficient handling of read/write operations
- **Open Source**: Free and widely supported

## Installation on Ubuntu

``` bash
# Update and install PostgreSQL
sudo apt update
sudo apt install postgresql postgresql-contrib

# Start PostgreSQL
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

## Create Database and User

``` bash
# Switch to postgres user and create database
sudo -u postgres psql

# Run these commands in the PostgreSQL prompt:
CREATE USER taskqueue_user WITH PASSWORD 'your_password';
CREATE DATABASE taskqueue_db OWNER taskqueue_user;
GRANT ALL PRIVILEGES ON DATABASE taskqueue_db TO taskqueue_user;
\q
```

## Configure Remote Access

Allow worker nodes to connect to PostgreSQL.

### 1. Edit postgresql.conf

``` bash
# Edit configuration file (adjust version number if needed)
sudo nano /etc/postgresql/14/main/postgresql.conf

# Find and change:
listen_addresses = '*'
```

### 2. Edit pg_hba.conf

``` bash
# Edit authentication file
sudo nano /etc/postgresql/14/main/pg_hba.conf

# Add this line:
# For specific HPC network (recommended):
host    taskqueue_db    taskqueue_user    10.0.0.0/8        md5
# Or for all IPs (less secure):
host    taskqueue_db    taskqueue_user    0.0.0.0/0         md5
```

### 3. Restart PostgreSQL

``` bash
sudo systemctl restart postgresql
```

### 4. Open Firewall if Needed

``` bash
# Allow PostgreSQL port from HPC network
sudo ufw allow from 10.0.0.0/8 to any port 5432
# Or allow from all IPs (less secure):
sudo ufw allow 5432/tcp
```

## R Configuration

On all machines (daily working machines, login nodes and compute nodes),
add these environment variables to `~/.Renviron`:

    PGHOST=your.database.server.com
    PGPORT=5432
    PGUSER=taskqueue_user
    PGPASSWORD=your_password
    PGDATABASE=taskqueue_db

**Edit .Renviron:**

``` bash
nano ~/.Renviron
# Add the variables above, then save and exit
```

Restart R after editing `.Renviron`.

## Install R Packages

``` r
# install from CRAN
install.packages("taskqueue")
```

``` r
# or install the latest development version from GitHub
remotes::install_github("byzheng/taskqueue")
```

## Test Connection

``` r
library(taskqueue)
db_connect()
```

## Initialize taskqueue

``` r
library(taskqueue)

# Create required tables
db_init()
```

## Security Notes

- Use strong passwords
- Restrict IP ranges in `pg_hba.conf` to your HPC network only
- Protect `.Renviron`: `chmod 600 ~/.Renviron`

## Clean Database

If needed, remove all taskqueue data:

``` r
library(taskqueue)
db_clean()  # Removes all tables
```

The package will recreate tables automatically when needed.
