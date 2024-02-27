test_that("worker", {
    skip_if(!is_test_db())


    fun_test <- function(i, prefix) {
        Sys.sleep(runif(1) * 2)
    }
    # Test slurm workers
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


    # test slurm workers
    skip_if(!is_slurm())

    expect_error(worker_slurm(test_project, test_slurm_resource, rfile = "no-exist.R"))


    expect_no_error(project_start(test_project))
    prj <- project_get(test_project)
    expect_equal(prj$status, TRUE)
    expect_no_error(
        worker_slurm(project = test_project,
                     resource= test_slurm_resource,
                     fun = fun_test)
    )
    # expect_no_error(
    #     project_stop(test_project)
    # )


})