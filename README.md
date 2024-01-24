# taskqueue

Task Queue is implemented in R for asynchronous tasks based on [PostgreSQL](https://www.postgresql.org/) database. This package is only suitable for parallel computing without any communication among parallel tasks (i.e. [Embarrassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel)).

## Challenge of parallel computing in R

Several R packages have been using for parallel computing (e.g. [High-Performance and Parallel Computing with R](https://cran.r-project.org/web/views/HighPerformanceComputing.html) which are not suitable for asynchronous tasks.


* Uneven load among cores/workers. Some workers run faster than others and then wait for others to stop. 
* Cannot utilise the new available workers after a parallel task is started. 

`taskqueue` is designed to utilise all available computing resources until all tasks are finished through dynamic allocating tasks to workers.  

## Installation 

Install the developing version from [Github](https://github.com/byzheng/taskqueue).

```r
devtools::install_github('byzheng/taskqueue')
```

## PostgreSQL installation and configuration

As large amount of concurrent requests might simultaneously reach the database, a specific server is preferred to install PostgreSQL database and can be connected by all workers. Following the [PostgreSQL website](https://www.postgresql.org/download/) to install and configure PostgreSQL. A database should be created for each user.

In all workers, five environmental variables should be added to `.Renviron` file to connect database, i.e.

```
PGHOST=
PGPORT=
PGUSER=
PGPASSWORD=
PGDATABASE=
```


## Resource

A computing resource is defined as a facility/computer which can run multiple jobs/workers.

A new resource can be added by `resource_add` with configurations.

* `name` as resource name
* `type` resource type. Only support `slurm` at this stage
* `host` network name to access resource
* `nodename` obtain by `Sys.info()` in the resource
* `workers` maximum number of available cores in resouirce
* `log_folder` folder to store log files in the resource


Currently only `slurm` is supported although I plan to implement other types of resource.

```r
resource_add(name = "hpc", 
            type = "slurm", 
            host = "hpc.example.com", 
            nodename = "hpc",
            workers = 500,
            log_folder = "/home/user/log_folder/")
```



## Project

`taskqueue` manages tasks by project which has its own resources, working directory, runtime requirements and other configurations.

A project with unique name can be created by `project_add` function and assign common requirements (e.g. memory).

```r
project_add("test_project", memory = 20)
```

Assign a `resource` to `project` which can be used to schedule workers with configurations (e.g. working directory, total runtimes, project specified workers).

```r
project_resource_add(project = "test_project", 
                     resource = "hpc")
```

Now tasks can be added into database through function `task_add`, e.g. 

```
task_add(project, num = 100, clean = TRUE)
```


Now we can develop a function to actually perform data processing, which 

* takes task `id` as the first argument, 
* expect no return values,
* save final output into file system and check whether this task is finished.

```r
library(taskqueue)
fun_test <- function(i) {
    # Check output file
    out_file <- sprintf("%s.Rds", i)
    if (file.exists(out_file)) {
        return()
    }
    # Perform the actual computing
    # ....
    
    # Save final output
    saveRDS(i, out_file)
}

worker("test1", fun_test)
```
