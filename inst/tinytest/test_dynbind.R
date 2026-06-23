env <- new.env()
expect_equal(
    class(bind <- dynbind(
        c("msvcrt", "c", "c.so.6"), "qsort(piip)v;",
        pattern = "qsort", replace = "c_qsort", envir = env
    )),
    "dynbind.report"
)
expect_true(exists("c_qsort", env, inherits = FALSE))

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

env <- new.env()
bind <- dynbind(fixture, "rdyncall_dynbind_sum_variadic(i)i;", envir = env, variadic = TRUE)
expect_equal(class(bind), "dynbind.report")
expect_equal(env$rdyncall_dynbind_sum_variadic(1L, 2L, 3L, .varargs = "ii"), 6L)
expect_error(
    dynbind(fixture, "rdyncall_dynbind_sum_variadic(i)i;", funcptr = TRUE, variadic = TRUE),
    "cannot both be TRUE"
)

local({
    oldwd <- setwd(dirname(fixture))
    on.exit(setwd(oldwd), add = TRUE)
    expect_dynbind_add(file.path(".", basename(fixture)))
})

local({
    if (!is.null(dynfind("R"))) {
        tmp <- tempfile("rdyncall-dynbind-short-name-")
        dir.create(file.path(tmp, "R"), recursive = TRUE)
        oldwd <- setwd(tmp)
        on.exit(setwd(oldwd), add = TRUE)

        env <- new.env()
        bind <- dynbind("R", "R_IsNA(d)i;", envir = env)
        expect_equal(class(bind), "dynbind.report")
        expect_equal(env$R_IsNA(NA_real_), 1L)
    }
})

attr(handle, "dynbind-test") <- "input-handle"
bind <- expect_dynbind_add(handle)
expect_equal(attr(bind$libhandle, "dynbind-test"), "input-handle")

expect_error(
    dynbind(as.externalptr(1), "rdyncall_dynbind_add(ii)i;"),
    "external pointer must be returned by dynload"
)
