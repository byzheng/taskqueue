test_that("resource", {
    skip_if(!db_is_connect())

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
    skip_if(Sys.info()["sysname"] != "windows")
    expect_no_error({
        resource_add(name = "this-computer",
                     type = "slurm",
                     host = "this-computer.com",
                     workers = 2,
                     log_folder = "c:/log_folder")
    })
})
