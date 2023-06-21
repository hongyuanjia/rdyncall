env <- new.env()
expect_equal(
    class(bind <- dynbind(
        c("msvcrt", "c", "c.so.6"), "qsort(piip)v;",
        pattern = "qsort", replace = "c_qsort", envir = env
    )),
    "dynbind.report"
)
expect_true(exists("c_qsort", env, inherits = FALSE))
