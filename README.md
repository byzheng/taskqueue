# taskqueue

Task Queue is implemented in R for asynchronous tasks based on [PostgreSQL](https://www.postgresql.org/) database. This package is only suitable for parallel computing without any communication among parallel tasks (i.e. [Embarrassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel)).

## Challenge of parallel computing in R

Several R packages have been using for parallel computing (e.g. [High-Performance and Parallel Computing with R](https://cran.r-project.org/web/views/HighPerformanceComputing.html) which are not suitable for asynchronous tasks.


* Uneven load among cores/workers. Some workers run faster than others and then wait for others to stop. 


## Installation 

Install the developing version from [Github](https://github.com/byzheng/taskqueue).

```r
devtools::install_github('byzheng/taskqueue')
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


```r
resource_add(name = "hpc", 
            type = "slurm", 
            host = "hpc.example.com", 
            nodename = "hpc",
            workers = 500,
            log_folder = "/home/user/log_folder/")
```

### slurm 


## Project

`taskqueue` manages tasks by project which has its own resources, working directory and runtime requirements.

A project can be created by `project_add` function and assign common common requirements (e.g. memory).

```r
project_add("test_project", memory = 20)
```

Assign a `resource` to `project` which can be used to schedule workers.

```r
project_resource_add(project = "test_project", 
                     resource = "hpc")
