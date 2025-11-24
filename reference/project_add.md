# Create a New Project

Creates a new project in the database for managing a set of related
tasks. Each project has its own task table and configuration.

## Usage

``` r
project_add(project, memory = 10)
```

## Arguments

- project:

  Character string for the project name. Must be unique and cannot be a
  reserved name (e.g., "config").

- memory:

  Memory requirement in gigabytes (GB) for each task in this project.
  Default is 10 GB.

## Value

Invisibly returns NULL. Called for side effects (creating project in
database).

## Details

This function:

- Creates a new entry in the `project` table

- Creates a dedicated task table named `task_<project>`

- Sets default memory requirements for all tasks

If a project with the same name already exists, the memory requirement
is updated but the task table remains unchanged.

After creating a project, you must:

1.  Assign resources with
    [`project_resource_add`](https://taskqueue.bangyou.me/reference/project_resource_add.md)

2.  Add tasks with
    [`task_add`](https://taskqueue.bangyou.me/reference/task_add.md)

3.  Start the project with
    [`project_start`](https://taskqueue.bangyou.me/reference/project_start.md)

## See also

[`project_start`](https://taskqueue.bangyou.me/reference/project_start.md),
[`project_resource_add`](https://taskqueue.bangyou.me/reference/project_resource_add.md),
[`task_add`](https://taskqueue.bangyou.me/reference/task_add.md),
[`project_delete`](https://taskqueue.bangyou.me/reference/project_delete.md)

## Examples

``` r
if (FALSE) { # \dontrun{
# Create a project with default memory
project_add("simulation_study")

# Create with higher memory requirement
project_add("big_data_analysis", memory = 64)

# Verify project was created
project_list()
} # }
```
