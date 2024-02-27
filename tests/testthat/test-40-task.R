test_that("task", {
    skip_if(!is_test_db())

    expect_no_error(task_add(test_project, num = 10))

    expect_no_error(task_clean(test_project))

    expect_no_error(task_add(test_project, num = 10))
    tasks <- task_get(test_project)
    expect_equal(nrow(tasks), 0)
    tasks <- task_get(test_project, status = "all")
    expect_equal(nrow(tasks), 10)

})
