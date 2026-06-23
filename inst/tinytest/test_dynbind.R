env <- new.env()
expect_equal(
    class(bind <- dynbind(
        c("msvcrt", "c", "c.so.6"), "qsort(piip)v;",
        pattern = "qsort", replace = "c_qsort", envir = env
    )),
    "dynbind.report"
)
expect_true(exists("c_qsort", env, inherits = FALSE))
bind_print <- capture.output(expect_identical(print(bind), bind))
expect_true(any(grepl("dynbind report", bind_print, fixed = TRUE)))
expect_true(any(grepl("unresolved symbols: 0", bind_print, fixed = TRUE)))

missing_bind <- dynbind(
    c("msvcrt", "c", "c.so.6"),
    "rdyncall_missing_symbol_for_print_probe(i)i;",
    envir = new.env()
)
missing_bind_print <- capture.output(expect_identical(print(missing_bind), missing_bind))
expect_true(any(grepl("unresolved symbols: 1", missing_bind_print, fixed = TRUE)))
expect_true(any(grepl("rdyncall_missing_symbol_for_print_probe", missing_bind_print, fixed = TRUE)))

build_dynbind_fixture <- function() {
    src <- system.file("tinytest", "dynbind.c", package = "rdyncall", mustWork = TRUE)
    src <- normalizePath(src, winslash = "/", mustWork = TRUE)
    outdir <- tempfile("rdyncall-dynbind-fixture-")
    dir.create(outdir)
    outdir <- normalizePath(outdir, winslash = "/", mustWork = TRUE)
    lib <- file.path(outdir, paste0("dynbind", .Platform$dynlib.ext))
    out <- system2(file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", lib, src),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status"))) {
        stop(paste(c("failed to build dynbind test fixture", out), collapse = "\n"), call. = FALSE)
    }
    lib
}

expect_dynbind_add <- function(libnames) {
    env <- new.env()
    bind <- dynbind(
        libnames,
        "rdyncall_dynbind_add(ii)i;",
        pattern = "^rdyncall_dynbind_", replace = "", envir = env
    )
    expect_equal(class(bind), "dynbind.report")
    expect_true(exists("add", env, inherits = FALSE))
    expect_equal(env$add(2L, 3L), 5L)
    bind
}

fixture <- build_dynbind_fixture()

expect_dynbind_add(fixture)

handle <- dynload(fixture)
sum_variadic <- dynsym(handle, "rdyncall_dynbind_sum_variadic")
expect_equal(dyncall_variadic(sum_variadic, "i)i", "ii", 1L, 2L, 3L), 6L)

sum_variadic_double <- dynsym(handle, "rdyncall_dynbind_sum_variadic_double")
expect_equal(dyncall_variadic(sum_variadic_double, "d)d", "d", 1.5, 2.25), 3.75)
expect_error(
    dyncall_variadic(sum_variadic, "i)i", "i)i", 1L, 2L),
    "argument type signatures"
)

local({
    oldwd <- setwd(dirname(fixture))
    on.exit(setwd(oldwd), add = TRUE)
    expect_dynbind_add(file.path(".", basename(fixture)))
})

local({
    rlib <- dynfind("R")
    if (!is.null(rlib)) {
        temp_wd <- tempfile("rdyncall-dynbind-short-name-")
        dir.create(temp_wd)
        oldwd <- setwd(temp_wd)
        on.exit(setwd(oldwd), add = TRUE)
        dir.create("R")
        env <- new.env()
        bind <- dynbind("R", "R_ShowMessage(Z)v;", envir = env)
        expect_equal(class(bind), "dynbind.report")
        expect_equal(bind$unresolved.symbols, character(0))
        expect_true(exists("R_ShowMessage", env, inherits = FALSE))
    }
})

attr(handle, "dynbind-test") <- "input-handle"
bind <- expect_dynbind_add(handle)
expect_equal(attr(bind$libhandle, "dynbind-test"), "input-handle")

expect_error(
    dynbind(as.externalptr(1), "rdyncall_dynbind_add(ii)i;"),
    "external pointer must be returned by dynload"
)
