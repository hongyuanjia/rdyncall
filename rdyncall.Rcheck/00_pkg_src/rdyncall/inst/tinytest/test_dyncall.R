f <- function(x, y) x + y
expect_true(is.externalptr(cb <- ccallback("ii)i", f)))
expect_equal(dyncall(cb, "ii)i", 20L, 3L), 23L)
