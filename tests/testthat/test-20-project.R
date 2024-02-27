test_that("project", {
    skip_if(!is_test_db())

    expect_error(project_add(c("p1", "p2")))
    expect_error(project_add(1))

    expect_no_error(project_add(test_project))

    prjs <- project_list()
    expect_equal(nrow(prjs), 1)
    prj <- project_get(test_project)
    expect_equal(nrow(prj), 1)
    expect_no_error(project_delete(test_project))

    expect_no_error(project_add(test_project))
    prj <- project_get(test_project)
    expect_equal(nrow(prj), 1)

    expect_no_error(project_start(test_project))
    prj <- project_get(test_project)
    expect_equal(prj$status, TRUE)

    expect_no_error(project_stop(test_project))
    prj <- project_get(test_project)
    expect_equal(prj$status, FALSE)

    expect_no_error(project_reset(test_project))
    prj <- project_get(test_project)
    expect_equal(prj$status, FALSE)

})
