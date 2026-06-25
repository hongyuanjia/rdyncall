dynfind_values <- function(x) {
    unique(x[!is.na(x) & nzchar(x)])
}

dynfind_name_variants <- function(name) {
    dynfind_values(c(name, tolower(name), toupper(name)))
}

dynfind_empty_candidates <- function() {
    data.frame(source = character(), candidate = character(), stringsAsFactors = FALSE)
}

dynfind_candidate_rows <- function(source, candidates, existing.only = FALSE) {
    candidates <- dynfind_values(candidates)
    if (existing.only) {
        candidates <- candidates[file.exists(candidates)]
    }
    if (!length(candidates)) {
        return(dynfind_empty_candidates())
    }
    data.frame(source = source, candidate = candidates, stringsAsFactors = FALSE)
}

dynfind_source_dirs <- function(source, dirs) {
    dirs <- dynfind_values(dirs)
    if (!length(dirs)) {
        return(data.frame(source = character(), dir = character(), stringsAsFactors = FALSE))
    }
    data.frame(source = source, dir = dirs, stringsAsFactors = FALSE)
}

dynfind_rbind <- function(x) {
    x <- Filter(nrow, x)
    if (!length(x)) {
        return(dynfind_empty_candidates())
    }
    unique(do.call(rbind, x))
}

dynfind_files <- function(dirs, patterns) {
    dirs <- dynfind_values(dirs)
    dirs <- dirs[dir.exists(dirs)]
    if (!length(dirs)) {
        return(character())
    }
    unique(unlist(lapply(dirs, function(dir) {
        unlist(lapply(patterns, function(pattern) {
            Sys.glob(file.path(dir, pattern))
        }), use.names = FALSE)
    }), use.names = FALSE))
}

dynfind_files_by_source <- function(source_dirs, patterns) {
    if (!nrow(source_dirs)) {
        return(dynfind_empty_candidates())
    }
    source_dirs <- source_dirs[dir.exists(source_dirs$dir), , drop = FALSE]
    if (!nrow(source_dirs)) {
        return(dynfind_empty_candidates())
    }
    dynfind_rbind(lapply(seq_len(nrow(source_dirs)), function(i) {
        dynfind_candidate_rows(
            source_dirs$source[[i]],
            unlist(lapply(patterns, function(pattern) {
                Sys.glob(file.path(source_dirs$dir[[i]], pattern))
            }), use.names = FALSE)
        )
    }))
}

dynfind_library_patterns <- function(name) {
    names <- dynfind_name_variants(name)
    if (.Platform$OS.type == "windows") {
        c(paste0(names, ".dll"), paste0("lib", names, ".dll"), paste0(names, "*.dll"), paste0("lib", names, "*.dll"))
    } else if (Sys.info()[["sysname"]] == "Darwin") {
        c(paste0("lib", names, ".dylib"), paste0("lib", names, ".*.dylib"))
    } else {
        c(paste0("lib", names, ".so"), paste0("lib", names, ".so.*"))
    }
}

dynfind_runtime_dirs <- function() {
    if (.Platform$OS.type == "windows") {
        return(dynfind_values(c(
            R.home("bin"),
            file.path(R.home("bin"), R.version$arch),
            file.path(R.home("bin"), "x64"),
            file.path(R.home("bin"), "i386"),
            R.home("lib")
        )))
    }

    dynfind_values(c(R.home("lib"), R.home("bin")))
}

dynfind_runtime_source_dirs <- function() {
    dynfind_source_dirs("r-runtime", dynfind_runtime_dirs())
}

dynfind_runtime_files <- function(name) {
    dynfind_files(dynfind_runtime_dirs(), dynfind_library_patterns(name))
}

dynfind_runtime_candidates <- function(name) {
    dynfind_files_by_source(dynfind_runtime_source_dirs(), dynfind_library_patterns(name))
}

dynfind_windows_scoop_dirs <- function(name) {
    names <- dynfind_name_variants(name)
    userprofile <- Sys.getenv("USERPROFILE", "")
    programdata <- Sys.getenv("ProgramData", "")
    roots <- dynfind_values(c(
        Sys.getenv("SCOOP", ""),
        Sys.getenv("SCOOP_GLOBAL", ""),
        if (nzchar(userprofile)) file.path(userprofile, "scoop") else character(),
        if (nzchar(programdata)) file.path(programdata, "scoop") else character()
    ))
    unique(unlist(lapply(roots, function(root) {
        c(
            file.path(root, "apps", names, "current", "bin"),
            file.path(root, "apps", names, "current", "lib"),
            file.path(root, "apps", names, "current")
        )
    }), use.names = FALSE))
}

dynfind_windows_msys2_dirs <- function() {
    roots <- dynfind_values(c(
        Sys.getenv("MINGW_PREFIX", ""),
        Sys.getenv("MSYSTEM_PREFIX", "")
    ))
    msys2_roots <- dynfind_values(c(
        Sys.getenv("MSYS2_ROOT", ""),
        Sys.getenv("MSYS2_PREFIX", ""),
        "C:/msys64"
    ))
    unique(c(
        file.path(roots, "bin"),
        file.path(msys2_roots, "mingw64", "bin"),
        file.path(msys2_roots, "ucrt64", "bin"),
        file.path(msys2_roots, "clang64", "bin"),
        file.path(msys2_roots, "msys2", "bin"),
        file.path(msys2_roots, "usr", "bin")
    ))
}

dynfind_windows_vcpkg_dirs <- function() {
    root <- Sys.getenv("VCPKG_ROOT", "")
    if (!nzchar(root)) {
        return(character())
    }
    triplets <- dynfind_values(c(
        Sys.getenv("VCPKG_DEFAULT_TRIPLET", ""),
        Sys.getenv("VCPKG_TARGET_TRIPLET", ""),
        "x64-windows",
        "arm64-windows",
        "x86-windows"
    ))
    file.path(root, "installed", triplets, "bin")
}

dynfind_windows_conda_dirs <- function() {
    prefix <- Sys.getenv("CONDA_PREFIX", "")
    if (!nzchar(prefix)) {
        return(character())
    }
    c(file.path(prefix, "Library", "bin"), file.path(prefix, "bin"))
}

dynfind_package_manager_source_dirs <- function(name) {
    if (.Platform$OS.type == "windows") {
        return(do.call(rbind, list(
            dynfind_source_dirs("scoop", dynfind_windows_scoop_dirs(name)),
            dynfind_source_dirs("msys2", dynfind_windows_msys2_dirs()),
            dynfind_source_dirs("vcpkg", dynfind_windows_vcpkg_dirs()),
            dynfind_source_dirs("conda", dynfind_windows_conda_dirs())
        )))
    }

    if (Sys.info()[["sysname"]] == "Darwin") {
        names <- dynfind_name_variants(name)
        homebrew <- dynfind_values(c(Sys.getenv("HOMEBREW_PREFIX", ""), "/opt/homebrew", "/usr/local"))
        macports <- dynfind_values(c(Sys.getenv("MACPORTS_PREFIX", ""), "/opt/local"))
        return(do.call(rbind, list(
            dynfind_source_dirs("homebrew", c(
                file.path(homebrew, "lib"),
                unlist(lapply(homebrew, function(root) {
                    file.path(root, "opt", names, "lib")
                }), use.names = FALSE)
            )),
            dynfind_source_dirs("macports", file.path(macports, "lib"))
        )))
    }

    names <- dynfind_name_variants(name)
    homebrew <- dynfind_values(c(Sys.getenv("HOMEBREW_PREFIX", ""), "/home/linuxbrew/.linuxbrew"))
    dynfind_source_dirs("homebrew", c(
        file.path(homebrew, "lib"),
        unlist(lapply(homebrew, function(root) {
            file.path(root, "opt", names, "lib")
        }), use.names = FALSE)
    ))
}

dynfind_package_manager_dirs <- function(name) {
    unique(dynfind_package_manager_source_dirs(name)$dir)
}

dynfind_package_manager_files <- function(name) {
    dynfind_files(dynfind_package_manager_dirs(name), dynfind_library_patterns(name))
}

dynfind_package_manager_candidates <- function(name) {
    dynfind_files_by_source(dynfind_package_manager_source_dirs(name), dynfind_library_patterns(name))
}

dynfind_candidates <- function(name) {
    if (.Platform$OS.type == "windows") {
        return(dynfind_rbind(list(
            dynfind_candidate_rows("loader", c(paste("lib", name, sep = ""), name)),
            dynfind_runtime_candidates(name),
            dynfind_package_manager_candidates(name)
        )))
    }

    if (Sys.info()[["sysname"]] == "Darwin") {
        return(dynfind_rbind(list(
            dynfind_candidate_rows("loader", c(
                paste(name, ".framework/", name, sep = ""),
                paste("lib", name, ".dylib", sep = "")
            )),
            dynfind_runtime_candidates(name),
            dynfind_package_manager_candidates(name),
            dynfind_candidate_rows("system-cache", paste("/usr/lib/system/libsystem_", name, ".dylib", sep = "")),
            dynfind_candidate_rows("system", paste("/usr/lib/lib", name, ".dylib", sep = ""))
        )))
    }

    dynfind_rbind(list(
        dynfind_candidate_rows("loader", c(
            paste("lib", name, ".so", sep = ""),
            paste("lib", name, sep = "")
        )),
        dynfind_runtime_candidates(name),
        dynfind_package_manager_candidates(name),
        dynfind_candidate_rows("loader", name)
    ))
}

dynfind_try <- function(paths, ..., existing.only = FALSE) {
    paths <- dynfind_values(paths)
    if (existing.only) {
        paths <- paths[file.exists(paths)]
    }
    for (path in paths) {
        handle <- dynfind_load_candidate(path, ...)
        if (!is.null(handle)) {
            return(handle)
        }
    }
    NULL
}

dynfind_load_candidate <- function(path, ...) {
    dynfind_with_candidate_dir(path, {
        dynload(path, ...)
    })
}

dynfind_with_candidate_dir <- function(path, expr) {
    if (.Platform$OS.type != "windows" || is.na(path) || !grepl("[/\\\\]", path)) {
        return(force(expr))
    }

    dir <- dirname(path)
    if (!nzchar(dir) || identical(dir, ".")) {
        return(force(expr))
    }

    old <- Sys.getenv("PATH", unset = NA_character_)
    on.exit({
        if (is.na(old)) {
            Sys.unsetenv("PATH")
        } else {
            Sys.setenv(PATH = old)
        }
    }, add = TRUE)

    Sys.setenv(PATH = if (is.na(old) || !nzchar(old)) dir else paste(dir, old, sep = .Platform$path.sep))
    force(expr)
}

dynfind1 <- function(name, ...) {
    dynfind_try(dynfind_candidates(name)$candidate, ...)
}

dynfind_explain_rows <- function(libnames) {
    rows <- lapply(libnames, function(libname) {
        candidates <- dynfind_candidates(libname)
        if (!nrow(candidates)) {
            return(data.frame(
                libname = character(),
                source = character(),
                candidate = character(),
                exists = logical(),
                loaded = logical(),
                resolved_path = character(),
                stringsAsFactors = FALSE
            ))
        }
        data.frame(
            libname = libname,
            source = candidates$source,
            candidate = candidates$candidate,
            exists = file.exists(candidates$candidate),
            loaded = NA,
            resolved_path = NA_character_,
            stringsAsFactors = FALSE
        )
    })
    rows <- Filter(nrow, rows)
    if (!length(rows)) {
        return(data.frame(
            libname = character(),
            source = character(),
            candidate = character(),
            exists = logical(),
            loaded = logical(),
            resolved_path = character(),
            stringsAsFactors = FALSE
        ))
    }
    do.call(rbind, rows)
}

dynfind_try_explain <- function(rows) {
    if (!nrow(rows)) {
        return(rows)
    }
    for (i in seq_len(nrow(rows))) {
        handle <- dynfind_load_candidate(rows$candidate[[i]], auto.unload = FALSE)
        rows$loaded[[i]] <- !is.null(handle)
        if (!is.null(handle)) {
            rows$resolved_path[[i]] <- tryCatch(dynpath(handle), error = function(e) NA_character_)
            dynunload(handle)
            break
        }
    }
    rows
}

#' Portable searching and loading of shared libraries
#'
#' @description
#' Function to load shared libraries using a platform-portable interface.
#'
#' @details
#' `dynfind()` offers a platform-portable naming interface for loading a
#' specific shared library.
#'
#' `dynfind_explain()` returns the candidate paths that `dynfind()` would try,
#' optionally attempts them in the same order, and records the first loadable
#' candidate. It is intended for diagnosing platform-specific library discovery
#' failures without keeping a library handle open.
#'
#' The naming scheme and standard locations of shared libraries are OS-specific.
#' When loading a shared library dynamically at run-time across platforms via
#' standard interfaces such as [dynload()] or [dyn.load()],
#' a platform-test is usually needed to specify the OS-dependant library file
#' path.
#'
#' This _library name problem_ is encountered via breaking up the library file
#' path into several abstract components:
#'
#' ```
#' <location> <prefix> <libname> <suffix>
#' ```
#'
#' By permutation of values in each component and concatenation, a list of
#' possible file paths can be derived.
#' [dynfind()] goes through this list to try opening a library. On the first
#' success, the search is stopped and the function returns.
#'
#' Given that the three components `location`, `prefix` and `suffix` are set up
#' properly on a per OS basis,
#' the unique identification of a library is given by `libname` - the short
#' library name.
#'
#' For some libraries, multiple \sQuote{short library name} are needed to make
#' this mechanism work across all major platforms.
#' For example, to load the Standard C Library across major R platforms:
#'
#' ```r
#' lib <- dynfind(c("msvcrt", "c", "c.so.6"))
#' ```
#'
#' On Windows `MSVCRT.dll` would be loaded; `libc.dylib` on Mac OS X;
#' `libc.so.6` on Linux and `libc.so` on BSD.
#'
#' Here is a sample list of values for the three other components:
#'
#' \describe{
#' \item{`location`:}{`/usr/local/lib/`, `C:/Windows/System32/`}
#' \item{`prefix`:}{`lib` (common), empty - common on Windows}
#' \item{`suffix`:}{`.dll` (Windows), `.so` (ELF), `.dylib` (macOS) and empty -
#' useful for all platforms}
#' }
#'
#' The vector of `location`s is initialized by the dynamic linker search rules,
#' including environment variables such as `PATH` on Windows and
#' `LD_LIBRARY_PATH` on Unix-flavour systems. If the dynamic linker lookup
#' fails, `dynfind()` also checks library directories that belong to the
#' current R runtime, such as `R.home("lib")` and `R.home("bin")`, and common
#' package-manager library locations such as Homebrew (`HOMEBREW_PREFIX`,
#' `/opt/homebrew`, `/usr/local`), MacPorts (`MACPORTS_PREFIX`, `/opt/local`),
#' Linuxbrew (`/home/linuxbrew/.linuxbrew`), Scoop (`SCOOP`, `SCOOP_GLOBAL`,
#' `ProgramData/scoop`), MSYS2 (`MINGW_PREFIX`, `MSYSTEM_PREFIX`,
#' `C:/msys64`), vcpkg (`VCPKG_ROOT`) and conda (`CONDA_PREFIX`).
#' On Windows, when `dynfind()` tries a full DLL path from one of these
#' directories, it temporarily prepends that directory to `PATH` for the load
#' attempt so that sibling transitive DLL dependencies can be resolved.
#' (The set of hardcoded locations might expand and change within the next minor releases).
#'
#' The file extension depends on the OS: `.dll` (Windows), `.dylib` (macOS),
#' `.so` (all others).
#'
#' On Mac OS X, the search for a library includes the \sQuote{Frameworks}
#' folders as well.
#' This happens before the normal library search procedure and uses a slightly
#' different naming pattern in a separate search phase:
#'
#'```
#' <frameworksLocation> Frameworks/ <libname> .framework/ <libname>
#' ```
#'
#' The `frameworksLocation` is a vector of locations such as `/System/Library/`
#' and `/Library/`.
#'
#' `dynfind()` loads a library via [dynload()] passing over the parameter
#' `auto.unload`.
#'
#' @param libnames vector of character strings specifying several short library
#'        names.
#'
#' @param auto.unload logical: if `TRUE` then a finalizer is registered that
#'        closes the library on garbage collection. See [dynload()] for details.
#'
#' @param try.load logical: if `TRUE`, attempt candidates in `dynfind()` order
#'        until one loads. The loaded handle is immediately closed with
#'        [dynunload()].
#'
#' @return
#' [dynfind()] returns an external pointer (library handle), if search was
#' successful.
#' Otherwise, if no library is located, a `NULL` is returned.
#'
#' `dynfind_explain()` returns a data frame with columns `libname`, `source`,
#' `candidate`, `exists`, `loaded`, and `resolved_path`. `loaded` is `NA` for
#' candidates that were not attempted because an earlier candidate loaded, or
#' because `try.load = FALSE`.
#'
#' @seealso
#' See [dynload()] for details on the loader interface to the OS-specific
#' dynamic linker.
#'
#' @examples
#' diag <- dynfind_explain(c("msvcrt", "m", "m.so.6"), try.load = FALSE)
#' head(diag)
#'
#' @keywords programming interface
#' @rdname dynfind
#' @export
dynfind <- function(libnames, auto.unload = TRUE) {
    for (libname in libnames) {
        handle <- dynfind1(libname, auto.unload)
        if (!is.null(handle)) {
            return(handle)
        }
    }
}

#' @rdname dynfind
#' @export
dynfind_explain <- function(libnames, try.load = TRUE) {
    stopifnot(is.character(libnames))
    stopifnot(is.logical(try.load), length(try.load) == 1L, !is.na(try.load))

    rows <- dynfind_explain_rows(libnames)
    if (try.load) {
        rows <- dynfind_try_explain(rows)
    }
    class(rows) <- c("dynfind.explain", "data.frame")
    rows
}

#' @export
print.dynfind.explain <- function(x, ...) {
    if (!nrow(x)) {
        cat("No dynfind candidates.\n")
        return(invisible(x))
    }

    loaded <- which(x$loaded %in% TRUE)
    if (length(loaded)) {
        cat("First loadable dynfind candidate:\n")
        print.data.frame(x[loaded[[1L]], , drop = FALSE], row.names = FALSE, ...)
        cat("\nAll candidates:\n")
    } else if (all(is.na(x$loaded))) {
        cat("dynfind candidates; load attempts were not run:\n")
    } else {
        cat("No dynfind candidates loaded:\n")
    }
    print.data.frame(x, row.names = FALSE, ...)
    invisible(x)
}
