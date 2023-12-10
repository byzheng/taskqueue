test_that("test database", {
    # Test db connection
    skip_if(!db_is_connect())
    expect_no_error({
        con <- db_connect()
        db_disconnect(con)
    })
    # Only test initiative with localhost database
    # Only test in developing computer
    options <- taskqueue_options()
    skip_if(!(options$host == "localhost" &&
                  options$is_test == "DB"))
    expect_no_error({
        db_clean()
        db_init()
    })
})
