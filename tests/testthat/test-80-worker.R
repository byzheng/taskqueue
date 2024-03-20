test_that("worker", {
    skip_if(!is_test_db())


    fun_test <- function(i, prefix = "b") {
        paste(i, prefix)
        Sys.sleep(runif(1) * 2)
    }

    expect_no_error(task_reset(test_project, status = "all"))
    expect_no_error(project_start(test_project))
    # test workers
    expect_no_error(worker(test_project, fun_test, prefix = "a"))

    # Test arguments of slurm workers
    expect_error(worker_slurm(c("test", "test"), "petrichor"))
    expect_error(worker_slurm(TRUE, "petrichor"))
    expect_error(worker_slurm("test", c("test", "test2")))
    expect_error(worker_slurm("test", 1))
    expect_error(worker_slurm("test", "petrichor"))
    expect_error(worker_slurm("test", "petrichor"))
    expect_error(worker_slurm("test", "petrichor", module_r = 1))
    expect_error(worker_slurm("test", "petrichor", module_pg = 1))
    expect_error(worker_slurm("test", "petrichor", fun = "te"))
    expect_error(worker_slurm(test_project, test_resource, fun = fun_test))
    expect_error(worker_slurm(test_project, test_resource, fun = fun_test, module_r = c(1, 2)))
    expect_error(worker_slurm(test_project, test_resource, fun = fun_test, module_r = 1))
    expect_error(worker_slurm(test_project, test_resource, fun = fun_test, module_pg = 1))


    # test slurm workers on slurm cluster
    skip_if(!is_slurm())

    expect_no_error(task_reset(test_project, status = "all"))
    expect_error(worker_slurm(test_project, test_slurm_resource, rfile = "no-exist.R"))

    prj <- project_get(test_project)
    expect_no_error(
        worker_slurm(project = test_project,
                     resource= test_slurm_resource,
                     fun = fun_test)
    )
    expect_no_error(
        project_stop(test_project)
    )


})
