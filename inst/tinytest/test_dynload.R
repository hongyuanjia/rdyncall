expect_true(is.externalptr(libm <- dynfind(c("msvcrt", "m", "m.so.6"))))
expect_true(is.externalptr(c_sqrt <- dynsym(libm, "sqrt")))
expect_equal(dyncall(c_sqrt, "d)d", 144), 12)
expect_null(dynunload(libm))
