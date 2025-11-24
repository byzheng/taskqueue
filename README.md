# taskqueue

[![](https://www.r-pkg.org/badges/version/taskqueue?color=green)](https://cran.r-project.org/package=taskqueue)
![R-CMD-check](https://github.com/byzheng/taskqueue/workflows/R-CMD-check/badge.svg) 

[![](http://cranlogs.r-pkg.org/badges/grand-total/taskqueue?color=green)](https://cran.r-project.org/package=taskqueue)
[![](http://cranlogs.r-pkg.org/badges/last-month/taskqueue?color=green)](https://cran.r-project.org/package=taskqueue)
[![](http://cranlogs.r-pkg.org/badges/last-week/taskqueue?color=green)](https://cran.r-project.org/package=taskqueue)

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

## Getting Started

Please refer to

* [Getting Started](https://taskqueue.bangyou.me/vignettes/getting-started.html) vignette for more details.
* [Simple workflow example](https://taskqueue.bangyou.me/articles/simple-workflow-example.html) article for a complete simplified workflow.