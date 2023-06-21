expect_false(is.nullptr(NULL))
expect_equal(class(as.externalptr(1)), "externalptr")
expect_true(is.externalptr(offset_ptr(1, 1L)))

expect_equal(class(as.floatraw(1)), "floatraw")
expect_equal(floatraw2numeric(as.floatraw(1:2)), 1:2)
