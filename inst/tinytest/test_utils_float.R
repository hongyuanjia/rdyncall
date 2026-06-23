expect_equal(class(as.floatraw(1)), "floatraw")
expect_equal(floatraw2numeric(as.floatraw(1:2)), 1:2)

empty <- floatraw(0)
empty_floatraw_print <- capture.output(empty_floatraw_return <- print(empty))
expect_equal(empty_floatraw_print, "floatraw[0]")
expect_identical(empty_floatraw_return, empty)

floats <- as.floatraw(c(1, 2.5))
floats_print <- capture.output(floats_return <- print(floats))
expect_true(any(grepl("floatraw[2]:", floats_print, fixed = TRUE)))
expect_true(any(grepl("1.0", floats_print, fixed = TRUE)))
expect_true(any(grepl("2.5", floats_print, fixed = TRUE)))
expect_identical(floats_return, floats)

odd <- raw(3)
class(odd) <- "floatraw"
odd_print <- capture.output(odd_return <- print(odd))
expect_equal(odd_print, "floatraw bytes[3]: 00 00 00")
expect_identical(odd_return, odd)
