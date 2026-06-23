expect_true(is.externalptr(dynfind(c("msvcrt", "m", "m.so.6"))))

build_dynfind_fixture <- function() {
    src <- system.file("tinytest", "dynbind.c", package = "rdyncall", mustWork = TRUE)
    outdir <- tempfile("rdyncall-dynfind-fixture-")
    dir.create(outdir)
    target <- file.path(outdir, "rdyncall_dynfind_fixture.c")
    file.copy(src, target)

    oldwd <- setwd(outdir)
    on.exit(setwd(oldwd), add = TRUE)
    out <- system2(
        file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", basename(target)),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
        stop(paste(c("failed to build dynfind test fixture", out), collapse = "\n"), call. = FALSE)
    }

    lib <- file.path(outdir, paste0("rdyncall_dynfind_fixture", .Platform$dynlib.ext))
    if (!file.exists(lib)) {
        stop("failed to build dynfind test fixture", call. = FALSE)
    }
    lib
}

with_dynfind_env <- function(name, value, expr) {
    old <- Sys.getenv(name, unset = NA_character_)
    on.exit({
        if (is.na(old)) {
            Sys.unsetenv(name)
        } else {
            do.call(Sys.setenv, as.list(stats::setNames(old, name)))
        }
    }, add = TRUE)
    do.call(Sys.setenv, as.list(stats::setNames(value, name)))
    force(expr)
}

fixture <- build_dynfind_fixture()
libname <- "rdyncallfixture"
prefix <- tempfile("rdyncall-dynfind-prefix-")

if (.Platform$OS.type == "windows") {
    libdir <- file.path(prefix, "apps", libname, "current", "bin")
    dir.create(libdir, recursive = TRUE)
    file.copy(fixture, file.path(libdir, paste0(libname, ".dll")))

    with_dynfind_env("SCOOP", prefix, {
        expect_true(is.externalptr(dynfind(libname)))
    })
} else {
    libdir <- file.path(prefix, "lib")
    dir.create(libdir, recursive = TRUE)
    suffix <- if (Sys.info()[["sysname"]] == "Darwin") ".dylib" else ".so"
    file.copy(fixture, file.path(libdir, paste0("lib", libname, suffix)))

    with_dynfind_env("HOMEBREW_PREFIX", prefix, {
        expect_true(is.externalptr(dynfind(libname)))
    })
}
