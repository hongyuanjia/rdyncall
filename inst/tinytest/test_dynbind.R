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
    src_copy <- file.path(outdir, basename(src))
    # CRAN check libraries are read-only, so compile a temporary source copy
    # instead of letting R CMD SHLIB create object files beside the installed C file.
    if (!file.copy(src, src_copy, overwrite = TRUE)) {
        stop("failed to copy dynbind test fixture source", call. = FALSE)
    }
    lib <- file.path(outdir, paste0("dynbind", .Platform$dynlib.ext))
    out <- system2(file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", lib, src_copy),
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

set_errno_return <- dynsym(handle, "rdyncall_dynbind_set_errno_return")
return_errno <- dynsym(handle, "rdyncall_dynbind_return_errno")
dyncall_set_errno(0L)
expect_equal(dyncall_get_errno(), 0L)
expect_equal(dyncall(set_errno_return, "ii)i", 34L, 7L), 7L)
expect_equal(dyncall_get_errno(), 0L)
expect_equal(dyncall(set_errno_return, "ii)i", 34L, 7L, use_errno = TRUE), 7L)
expect_equal(dyncall_get_errno(), 34L)
dyncall_set_errno(12L)
expect_equal(dyncall(return_errno, ")i", use_errno = TRUE), 12L)

# Verify that direct dyncall errcheck receives the converted result and call metadata.
errno_checker <- function(result, info) {
    expect_equal(result, 4L)
    expect_equal(info$signature, "ii)i")
    expect_equal(info$args, list(9L, 4L))
    expect_null(info[["function"]])
    result + info$errno
}
expect_equal(
    dyncall(set_errno_return, "ii)i", 9L, 4L, use_errno = TRUE,
        errcheck = errno_checker),
    13L
)

# Exercise the error-propagation path of an errcheck callback.
failing_errno_checker <- function(result, info) {
    stop("checked failure", call. = FALSE)
}
expect_error(
    dyncall(set_errno_return, "ii)i", 1L, 1L, use_errno = TRUE,
        errcheck = failing_errno_checker),
    "checked failure"
)

env <- new.env()

# Check dynbind-provided metadata, including the installed R wrapper name.
dynbind_errno_checker <- function(result, info) {
    expect_equal(result, -1L)
    expect_equal(info[["function"]], "set_errno_return")
    info$errno
}
dynbind(
    fixture,
    "rdyncall_dynbind_set_errno_return(ii)i;",
    pattern = "^rdyncall_dynbind_", replace = "", envir = env,
    use_errno = TRUE, errcheck = dynbind_errno_checker
)
expect_equal(env$set_errno_return(21L, -1L), 21L)

if (.Platform$OS.type == "windows") {
    set_last_error_return <- dynsym(handle, "rdyncall_dynbind_set_last_error_return")
    dyncall_set_last_error(0)
    expect_equal(
        dyncall(set_last_error_return, "ii)i", 123L, 5L, use_last_error = TRUE),
        5L
    )
    expect_equal(dyncall_get_last_error(), 123)
} else {
    expect_error(dyncall_get_last_error(), "Windows")
    expect_error(dyncall_set_last_error(1), "Windows")
    expect_error(
        dyncall(set_errno_return, "ii)i", 1L, 1L, use_last_error = TRUE),
        "Windows"
    )
}

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
