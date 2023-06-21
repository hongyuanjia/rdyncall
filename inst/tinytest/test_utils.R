expect_false(is.nullptr(NULL))
expect_equal(class(as.externalptr(1)), "externalptr")
expect_true(is.externalptr(offset_ptr(1, 1L)))
