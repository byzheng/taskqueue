test_that("test database", {

    skip_if(!is_test_db())
    # test db connection
    expect_no_error({
        con <- db_connect()
        db_disconnect(con)
    })
    # Test db clean and initiation
    expect_no_error({
        db_clean()
        db_init()
    })
})
