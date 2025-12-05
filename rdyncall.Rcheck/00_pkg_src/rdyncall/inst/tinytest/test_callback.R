f <- function(x, y) x + y
expect_true(is.externalptr(cb <- ccallback("ii)i", function(x, y) x + y)))
expect_equal(dyncall(cb, "ii)i", 20, 3), 23)
