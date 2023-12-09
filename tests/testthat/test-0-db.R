test_that("test database", {
    # Test db connection
    skip_if(!db_test())
    expect_no_error({
        con <- db_connect()
        db_disconnect(con)
    })
    # Only test initiative with localhost database
    # Only test in my developing computer
    options <- taskqueue_options()
    skip_if(!(options$host == "localhost" &&
            Sys.info()["nodename"] == "TRAVEL-6JVWR73"))
    expect_no_error({
        db_clean()
        db_init()
    })
})
