expect_true(is.externalptr(dynfind(c("msvcrt", "m", "m.so.6"))))

diag_no_load <- dynfind_explain(c("msvcrt", "m", "m.so.6"), try.load = FALSE)
expect_true(inherits(diag_no_load, "dynfind.explain"))
expect_true(all(c("libname", "source", "candidate", "exists", "loaded", "resolved_path") %in% names(diag_no_load)))
expect_true(nrow(diag_no_load) > 0L)
expect_true(all(is.na(diag_no_load$loaded)))
expect_true(any(diag_no_load$source == "loader"))

diag_load <- dynfind_explain(c("msvcrt", "m", "m.so.6"))
expect_true(any(diag_load$loaded %in% TRUE))
expect_true(any(!is.na(diag_load$resolved_path)))
expect_true(length(capture.output(print(diag_load))) > 0L)

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

build_windows_transitive_fixture <- function() {
    outdir <- tempfile("rdyncall-dynfind-transitive-")
    dir.create(outdir)
    dep_src <- file.path(outdir, "rdyncall_dynfind_dep.c")
    main_src <- file.path(outdir, "rdyncall_dynfind_transitive.c")
    dep <- file.path(outdir, "rdyncallhelper.dll")
    main <- file.path(outdir, "rdyncalltransitive.dll")

    writeLines(c(
        "#if defined(_WIN32)",
        "#define RDYNCALL_TEST_EXPORT __declspec(dllexport)",
        "#else",
        "#define RDYNCALL_TEST_EXPORT __attribute__((visibility(\"default\")))",
        "#endif",
        "RDYNCALL_TEST_EXPORT int rdyncall_dynfind_dependency(void)",
        "{",
        "    return 42;",
        "}"
    ), dep_src)

    writeLines(c(
        "#if defined(_WIN32)",
        "#define RDYNCALL_TEST_EXPORT __declspec(dllexport)",
        "__declspec(dllimport) int rdyncall_dynfind_dependency(void);",
        "#else",
        "#define RDYNCALL_TEST_EXPORT __attribute__((visibility(\"default\")))",
        "int rdyncall_dynfind_dependency(void);",
        "#endif",
        "RDYNCALL_TEST_EXPORT int rdyncall_dynfind_transitive(void)",
        "{",
        "    return rdyncall_dynfind_dependency();",
        "}"
    ), main_src)

    oldwd <- setwd(outdir)
    on.exit(setwd(oldwd), add = TRUE)

    out <- system2(
        file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", basename(dep), basename(dep_src)),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
        stop(paste(c("failed to build dynfind dependency fixture", out), collapse = "\n"), call. = FALSE)
    }

    out <- system2(
        file.path(R.home("bin"), "R"),
        c("CMD", "SHLIB", "-o", basename(main), basename(main_src), basename(dep)),
        stdout = TRUE, stderr = TRUE
    )
    if (!is.null(attr(out, "status")) && attr(out, "status") != 0) {
        stop(paste(c("failed to build dynfind transitive fixture", out), collapse = "\n"), call. = FALSE)
    }
    if (!file.exists(dep) || !file.exists(main)) {
        stop("failed to build dynfind transitive fixture", call. = FALSE)
    }

    list(name = "rdyncalltransitive", main = main, dependency = dep)
}

with_dynfind_envs <- function(values, expr) {
    env_names <- names(values)
    old <- Sys.getenv(env_names, unset = NA_character_)
    on.exit({
        for (i in seq_along(env_names)) {
            name <- env_names[[i]]
            if (is.na(old[[i]])) {
                Sys.unsetenv(name)
            } else {
                do.call(Sys.setenv, as.list(stats::setNames(old[[i]], name)))
            }
        }
    }, add = TRUE)
    do.call(Sys.setenv, as.list(values))
    force(expr)
}

copy_fixture <- function(fixture, dir, name) {
    dir.create(dir, recursive = TRUE, showWarnings = FALSE)
    ok <- file.copy(fixture, file.path(dir, paste0(name, .Platform$dynlib.ext)), overwrite = TRUE)
    expect_true(ok)
}

expect_dynfind_source <- function(libname, source) {
    report <- dynfind_explain(libname)
    source_rows <- report$source == source
    detail <- paste(capture.output(print(report)), collapse = "\n")
    expect_true(any(source_rows), info = detail)
    expect_true(any(source_rows & report$exists), info = detail)
    expect_true(any(source_rows & report$loaded %in% TRUE), info = detail)
}

fixture <- build_dynfind_fixture()
libname <- "rdyncallfixture"
prefix <- tempfile("rdyncall-dynfind-prefix-")

if (.Platform$OS.type == "windows") {
    windows_cases <- list(
        scoop = list(
            source = "scoop",
            env = c(SCOOP = prefix),
            dir = file.path(prefix, "apps", libname, "current", "bin")
        ),
        msys2_mingw = list(
            source = "msys2",
            env = c(MINGW_PREFIX = prefix),
            dir = file.path(prefix, "bin")
        ),
        msys2_msystem = list(
            source = "msys2",
            env = c(MSYSTEM_PREFIX = prefix),
            dir = file.path(prefix, "bin")
        ),
        vcpkg = list(
            source = "vcpkg",
            env = c(VCPKG_ROOT = prefix, VCPKG_DEFAULT_TRIPLET = "x64-windows"),
            dir = file.path(prefix, "installed", "x64-windows", "bin")
        ),
        conda = list(
            source = "conda",
            env = c(CONDA_PREFIX = prefix),
            dir = file.path(prefix, "Library", "bin")
        )
    )

    for (name in names(windows_cases)) {
        case <- windows_cases[[name]]
        case_prefix <- tempfile(paste0("rdyncall-dynfind-", name, "-"))
        case$env[names(case$env) != "VCPKG_DEFAULT_TRIPLET"] <- case_prefix
        case$dir <- switch(name,
            scoop = file.path(case_prefix, "apps", libname, "current", "bin"),
            msys2_mingw = file.path(case_prefix, "bin"),
            msys2_msystem = file.path(case_prefix, "bin"),
            vcpkg = file.path(case_prefix, "installed", "x64-windows", "bin"),
            conda = file.path(case_prefix, "Library", "bin")
        )
        copy_fixture(fixture, case$dir, libname)
        with_dynfind_envs(case$env, {
            expect_dynfind_source(libname, case$source)
        })
    }

    transitive <- build_windows_transitive_fixture()

    missing_prefix <- tempfile("rdyncall-dynfind-missing-")
    missing_dir <- file.path(missing_prefix, "Library", "bin")
    copy_fixture(transitive$main, missing_dir, transitive$name)
    with_dynfind_envs(c(CONDA_PREFIX = missing_prefix), {
        report <- dynfind_explain(transitive$name)
        conda_row <- report$source == "conda" & report$exists
        expect_true(any(conda_row))
        expect_false(any(report$loaded %in% TRUE))
        expect_null(dynfind(transitive$name))
    })

    success_prefix <- tempfile("rdyncall-dynfind-transitive-success-")
    success_dir <- file.path(success_prefix, "installed", "x64-windows", "bin")
    copy_fixture(transitive$main, success_dir, transitive$name)
    ok <- file.copy(transitive$dependency, file.path(success_dir, basename(transitive$dependency)), overwrite = TRUE)
    expect_true(ok)
    with_dynfind_envs(c(VCPKG_ROOT = success_prefix, VCPKG_DEFAULT_TRIPLET = "x64-windows"), {
        expect_dynfind_source(transitive$name, "vcpkg")
    })
} else {
    libdir <- file.path(prefix, "lib")
    dir.create(libdir, recursive = TRUE)
    suffix <- if (Sys.info()[["sysname"]] == "Darwin") ".dylib" else ".so"
    ok <- file.copy(fixture, file.path(libdir, paste0("lib", libname, suffix)))
    expect_true(ok)

    with_dynfind_envs(c(HOMEBREW_PREFIX = prefix), {
        expect_dynfind_source(libname, "homebrew")
    })
}
