expect_equal(class(as.floatraw(1)), "floatraw")
expect_equal(floatraw2numeric(as.floatraw(1:2)), 1:2)
