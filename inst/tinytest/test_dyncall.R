f <- function(x, y) x + y
expect_true(is.externalptr(cb <- ccallback("ii)i", f)))
expect_equal(dyncall(cb, "ii)i", 20L, 3L), 23L)

run_rdyncall_subprocess <- function(expr) {
    lib <- dirname(system.file(package = "rdyncall"))
    code <- paste(sprintf(".libPaths(c(%s, .libPaths()))", shQuote(lib)), expr, sep = "\n")
    system2(file.path(R.home("bin"), "Rscript"),
        c("--vanilla", "-e", shQuote(code)),
        stdout = TRUE, stderr = TRUE
    )
}

large_call <- paste(
    "options(rdyncall.callvm.size = 16384L)",
    "library(rdyncall)",
    "n <- 1200L",
    "sig <- paste0(strrep('i', n), ')i')",
    "cb <- ccallback(sig, function(...) as.integer(sum(...)))",
    "ans <- do.call(dyncall, c(list(cb, sig), as.list(rep(1L, n))))",
    "stopifnot(identical(ans, n))",
    sep = "\n"
)
expect_null(attr(run_rdyncall_subprocess(large_call), "status"))

invalid_size <- paste(
    "options(rdyncall.callvm.size = 0L)",
    "library(rdyncall)",
    sep = "\n"
)
out <- suppressWarnings(run_rdyncall_subprocess(invalid_size))
expect_true(!is.null(attr(out, "status")))
expect_true(any(grepl("rdyncall.callvm.size", out, fixed = TRUE)))
