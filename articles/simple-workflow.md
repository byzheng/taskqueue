# Simple Workflow with tq_apply

## Overview

[`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md)
provides a simplified workflow for running parallel tasks on HPC
clusters. It combines multiple steps (project creation, resource
assignment, task addition, and worker scheduling) into a single function
call, similar to base R’s
[`lapply()`](https://rdrr.io/r/base/lapply.html) or
[`sapply()`](https://rdrr.io/r/base/lapply.html).

This is the easiest way to get started with `taskqueue` if you:

- Have a simple function to run multiple times
- Don’t need complex project management
- Want to quickly parallelize work on an HPC cluster

Before using `taskqueue`, ensure you have:

1.  PostgreSQL installed and configured (see [PostgreSQL
    Setup](https://taskqueue.bangyou.me/articles/postgresql-setup.md)
    vignette)

2.  SSH access configured for remote resources (see [SSH
    Setup](https://taskqueue.bangyou.me/articles/ssh-setup.md) vignette)

3.  Database initialized:

    ``` r
    library(taskqueue)
    db_init()
    ```

4.  A resource already defined:

    ``` r
    resource_add(
      name = "hpc",
      type = "slurm",
      host = "hpc.example.com",
      nodename = "hpc",
      workers = 500,
      log_folder = "/home/user/log_folder/"
    )
    ```

## Basic Usage

The simplest use of
[`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md)
requires just a few arguments:

``` r
library(taskqueue)

# Define your function
my_simulation <- function(i) {
  # Your computation here
  result <- i^2
  Sys.sleep(1)  # Simulate some work
  return(result)
}

# Run 100 tasks in parallel
tq_apply(
  n = 100,
  fun = my_simulation,
  project = "my_project",
  resource = "hpc"
)
```

This will:

1.  Create or update the project “my_project”
2.  Add the resource “hpc” to the project
3.  Create 100 tasks
4.  Schedule workers on the SLURM cluster
5.  Execute `my_simulation(1)`, `my_simulation(2)`, …,
    `my_simulation(100)` in parallel

## Function Arguments

### Required Arguments

- **`n`**: Number of tasks to run (integer)
- **`fun`**: The function to execute for each task
- **`project`**: Project name (string)
- **`resource`**: Resource name (string, must already exist)

### Optional Arguments

- **`memory`**: Memory per task in GB (default: 10)
- **`hour`**: Maximum runtime in hours (default: 24)
- **`account`**: Account name for cluster billing (optional)
- **`working_dir`**: Working directory on cluster (default:
  [`getwd()`](https://rdrr.io/r/base/getwd.html))
- **`...`**: Additional arguments passed to your function

## Passing Arguments to Your Function

You can pass additional arguments to your function using `...`:

``` r
my_function <- function(i, multiplier, offset = 0) {
  result <- i * multiplier + offset
  return(result)
}

tq_apply(
  n = 50,
  fun = my_function,
  project = "test_args",
  resource = "hpc",
  multiplier = 10,    # Passed to my_function
  offset = 5          # Passed to my_function
)
```

Each task will call: - Task 1:
`my_function(1, multiplier = 10, offset = 5)` - Task 2:
`my_function(2, multiplier = 10, offset = 5)` - And so on…

## Complete Example

Here’s a practical example running a Monte Carlo simulation:

``` r
library(taskqueue)

# Define simulation function
run_monte_carlo <- function(task_id, n_samples = 10000, seed_base = 12345) {
  # Set unique seed for each task
  set.seed(seed_base + task_id)
  
  # Run simulation
  samples <- rnorm(n_samples)
  result <- list(
    task_id = task_id,
    mean = mean(samples),
    sd = sd(samples),
    quantiles = quantile(samples, probs = c(0.025, 0.5, 0.975))
  )
  
  # Save results
  out_file <- sprintf("results/simulation_%04d.Rds", task_id)
  dir.create("results", showWarnings = FALSE)
  saveRDS(result, out_file)
  
  return(invisible(NULL))
}

# Run 1000 simulations in parallel
tq_apply(
  n = 1000,
  fun = run_monte_carlo,
  project = "monte_carlo_study",
  resource = "hpc",
  memory = 8,           # 8 GB per task
  hour = 2,             # 2 hour time limit
  working_dir = "/home/user/monte_carlo",
  n_samples = 50000,    # Argument for run_monte_carlo
  seed_base = 99999     # Argument for run_monte_carlo
)
```

## Monitoring Progress

After calling
[`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md),
monitor your tasks:

``` r
# Check task status
task_status("monte_carlo_study")

# Check overall project status
project_status("monte_carlo_study")
```

## Collecting Results

After all tasks complete, collect your results:

``` r
# Read all result files
result_files <- list.files("results", pattern = "simulation_.*\\.Rds$", 
                          full.names = TRUE)

# Combine results
all_results <- lapply(result_files, readRDS)

# Analyze
means <- sapply(all_results, function(x) x$mean)
hist(means, main = "Distribution of Means")
```

## Best Practices

### 1. Save Results to Files

Your function should save results to the file system:

``` r
my_task <- function(i) {
  out_file <- sprintf("output/result_%04d.Rds", i)
  
  # Skip if already done
  if (file.exists(out_file)) {
    return(invisible(NULL))
  }
  
  # Do computation
  result <- expensive_computation(i)
  
  # Save result
  saveRDS(result, out_file)
}
```

### 2. Make Functions Idempotent

Check if output already exists to avoid re-running completed tasks:

``` r
my_task <- function(i) {
  out_file <- sprintf("output/task_%d.Rds", i)
  if (file.exists(out_file)) return(invisible(NULL))
  
  # ... computation and save
}
```

### 3. Specify Working Directory

Ensure your working directory on the cluster is correct:

``` r
tq_apply(
  n = 100,
  fun = my_function,
  project = "my_project",
  resource = "hpc",
  working_dir = "/home/user/project_folder"
)
```

### 4. Set Appropriate Resources

Configure memory and time limits based on your task requirements:

``` r
tq_apply(
  n = 100,
  fun = memory_intensive_task,
  project = "big_analysis",
  resource = "hpc",
  memory = 64,    # 64 GB for large tasks
  hour = 48       # 48 hour time limit
)
```

## Comparison with Manual Workflow

[`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md)
simplifies the workflow by combining these steps:

**Manual approach:**

``` r
# Multiple steps
project_add("test", memory = 10)
project_resource_add("test", "hpc", working_dir = "/path", hours = 24)
task_add("test", num = 100, clean = TRUE)
project_reset("test")
worker_slurm("test", "hpc", fun = my_function)
```

**With tq_apply():**

``` r
# Single step
tq_apply(n = 100, fun = my_function, project = "test", resource = "hpc",
         working_dir = "/path", hour = 24)
```

## Troubleshooting

**Tasks fail immediately:** - Check the log folder specified in your
resource configuration - Verify your function works locally first -
Ensure the working directory exists on the cluster

**Tasks remain in “idle” status:** - Check that the project is started:
`project_start("my_project")` - Verify the resource is correctly
configured - Check SLURM queue: `squeue -u $USER`

**“Resource not found” error:** - The resource must be created before
using
[`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md) - Use
[`resource_list()`](https://taskqueue.bangyou.me/reference/resource_list.md)
to see available resources - Create resource with
[`resource_add()`](https://taskqueue.bangyou.me/reference/resource_add.md)

## When to Use tq_apply()

**Use [`tq_apply()`](https://taskqueue.bangyou.me/reference/tq_apply.md)
when:** - You have a simple parallel task - You want to quickly run many
iterations of a function - You don’t need fine-grained control over
project settings

**Use the manual workflow when:** - You need to manage multiple projects
simultaneously - You want to reuse a project for different task sets -
You need more control over resource scheduling - You’re running
different types of tasks in the same project
