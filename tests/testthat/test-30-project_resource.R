test_that("project resource", {
    skip_if(!is_test_db())

    expect_no_error(project_resource_add(test_project, test_resource, working_dir = tempdir()))

    # test slurm project
    skip_if(!is_slurm())

    expect_no_error(project_resource_add(
        project = test_project,
        resource = test_slurm_resource,
        working_dir = Sys.getenv("PGTESTSLURMWORKING"),
        account = Sys.getenv("PGTESTSLURMACCOUNT"),
        hours = 1, workers = 5))
    pr <- project_resource_get(test_project)
    expect_equal(nrow(pr), 2)
    expect_no_error(project_resource_log_delete(test_project, test_slurm_resource))
})
