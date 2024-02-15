test_that("test options", {
    taskqueue_options(host = Sys.getenv("PGTESTHOST"),
                      port = Sys.getenv("PGTESTPORT"),
                      user = Sys.getenv("PGTESTUSER"),
                      password = Sys.getenv("PGTESTPASSWORD"),
                      database = Sys.getenv("PGTESTDATABASE"))
    skip_if(!is_test_db())
    expect_no_error({
        taskqueue_options()
    })
    expect_error({
        taskqueue_options(host = "unknown-host")
    })
})
