test_that("worker", {
    skip_if(!is_test_db())


    fun_test <- function(i, prefix = "b") {
        paste(i, prefix)
        Sys.sleep(runif(1) * 2)
    }


    # test slurm workers on slurm cluster
    skip_if(!is_slurm())

    expect_no_error(
        tq_apply(n = 10,
                 fun = fun_test,
                 project = test_project,
                 resource= test_slurm_resource,
                 working_dir = Sys.getenv("PGTESTSLURMWORKING"),
                 account = Sys.getenv("PGTESTSLURMACCOUNT"),
                 hours = 1)
    )
})
