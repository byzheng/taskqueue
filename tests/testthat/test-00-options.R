test_that("test options", {
    skip_if(!is_test_db())
    expect_no_error({
        taskqueue_options()
    })
})
