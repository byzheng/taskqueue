test_that("resource", {
    skip_if(!is_test_db())


    ## Add resource
    resource <- "this-computer"
    expect_error({
        resource_add(name = c("this-computer", "again"),
                     type = "slurm",
                     host = "this-computer.com",
                     workers = 2,
                     log_folder = "c:/log_folder")
    })
    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm", "again"),
                     host = "this-computer.com",
                     workers = 2,
                     log_folder = "c:/log_folder")
    })

    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm"),
                     host = c("this-computer.com", "again"),
                     workers = 2,
                     log_folder = "c:/log_folder")
    })
    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm"),
                     host = c("this-computer.com"),
                     workers = "ad",
                     log_folder = "c:/log_folder")
    })
    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm"),
                     host = c("this-computer.com"),
                     workers = c("A", 2),
                     log_folder = "c:/log_folder")
    })
    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm"),
                     host = c("this-computer.com"),
                     workers = -10,
                     log_folder = "c:/log_folder")
    })

    expect_error({
        resource_add(name = c("this-computer"),
                     type = c("slurm"),
                     host = c("this-computer.com"),
                     workers = 10,
                     log_folder = "log_folder")
    })
    expect_no_error({
        resource_add(name = "localhost",
                     type = "computer",
                     host = "localhost",
                     workers = 2,
                     log_folder = tempdir())
    })

    skip_if(!is_slurm())

    expect_no_error(resource_add(name = test_slurm_resource,
                 host = Sys.getenv("PGTESTSLURMHOST"),
                 username = Sys.getenv("PGTESTSLURMUSERNAME"),
                 type = "slurm",
                 workers = 5,
                 log_folder = Sys.getenv("PGTESTSLURMLOG")))
})
