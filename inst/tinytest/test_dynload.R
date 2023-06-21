expect_true(is.externalptr(libc <- dynload(c("msvcrt", "c", "c.so.6"))))
expect_true(is.externalptr(c_sqrt <- dynsym(libc, "sqrt")))
expect_equal(dyncall(c_sqrt, "d)d", 144), 12)
expect_null(dynunload(libc))
