# taskqueue

Task Queue is implemented in R based on [PostgreSQL](https://www.postgresql.org/) database. This package is only suitable for parallel computing without any communication among parallel tasks (i.e. [Embarrassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel)).

## Challenge of parallel computing in R

Several R packages have been using for parallel computing (e.g. [High-Performance and Parallel Computing with R](https://cran.r-project.org/web/views/HighPerformanceComputing.html).
