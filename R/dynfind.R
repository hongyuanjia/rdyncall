dynfind_values <- function(x) {
    unique(x[!is.na(x) & nzchar(x)])
}

dynfind_name_variants <- function(name) {
    dynfind_values(c(name, tolower(name), toupper(name)))
}

dynfind_try <- function(paths, ..., existing.only = FALSE) {
    paths <- dynfind_values(paths)
    if (existing.only) {
        paths <- paths[file.exists(paths)]
    }
    for (path in paths) {
        handle <- dynload(path, ...)
        if (!is.null(handle)) {
            return(handle)
        }
    }
    NULL
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

dynfind_runtime_files <- function(name) {
    dynfind_files(dynfind_runtime_dirs(), dynfind_library_patterns(name))
}

dynfind_package_manager_dirs <- function(name) {
    names <- dynfind_name_variants(name)
    if (.Platform$OS.type == "windows") {
        userprofile <- Sys.getenv("USERPROFILE", "")
        programdata <- Sys.getenv("ProgramData", "")
        roots <- dynfind_values(c(
            Sys.getenv("SCOOP", ""),
            Sys.getenv("SCOOP_GLOBAL", ""),
            if (nzchar(userprofile)) file.path(userprofile, "scoop") else character(),
            if (nzchar(programdata)) file.path(programdata, "scoop") else character()
        ))
        return(unique(unlist(lapply(roots, function(root) {
            c(
                file.path(root, "apps", names, "current", "bin"),
                file.path(root, "apps", names, "current", "lib"),
                file.path(root, "apps", names, "current")
            )
        }), use.names = FALSE)))
    }

    if (Sys.info()[["sysname"]] == "Darwin") {
        homebrew <- dynfind_values(c(Sys.getenv("HOMEBREW_PREFIX", ""), "/opt/homebrew", "/usr/local"))
        macports <- dynfind_values(c(Sys.getenv("MACPORTS_PREFIX", ""), "/opt/local"))
        return(unique(c(
            file.path(homebrew, "lib"),
            unlist(lapply(homebrew, function(root) {
                file.path(root, "opt", names, "lib")
            }), use.names = FALSE),
            file.path(macports, "lib")
        )))
    }

    homebrew <- dynfind_values(c(Sys.getenv("HOMEBREW_PREFIX", ""), "/home/linuxbrew/.linuxbrew"))
    unique(c(
        file.path(homebrew, "lib"),
        unlist(lapply(homebrew, function(root) {
            file.path(root, "opt", names, "lib")
        }), use.names = FALSE)
    ))
}

dynfind_package_manager_files <- function(name) {
    dynfind_files(dynfind_package_manager_dirs(name), dynfind_library_patterns(name))
}

dynfind1 <- if (.Platform$OS.type == "windows") {
    function(name, ...) {
        handle <- dynfind_try(c(paste("lib", name, sep = ""), name), ...)
        if (!is.null(handle)) {
            return(handle)
        }
        handle <- dynfind_try(dynfind_runtime_files(name), ..., existing.only = TRUE)
        if (!is.null(handle)) {
            return(handle)
        }
        dynfind_try(dynfind_package_manager_files(name), ..., existing.only = TRUE)
    }
} else {
    if (Sys.info()[["sysname"]] == "Darwin") {
        function(name, ...) {
            handle <- dynfind_try(c(
                paste(name, ".framework/", name, sep = ""),
                paste("lib", name, ".dylib", sep = "")
            ), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynfind_try(dynfind_runtime_files(name), ..., existing.only = TRUE)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynfind_try(dynfind_package_manager_files(name), ..., existing.only = TRUE)
            if (!is.null(handle)) {
                return(handle)
            }
            # ref: https://developer.apple.com/forums/thread/692383
            # ref: https://developer.apple.com/forums/thread/655588
            #
            # Start from macOS 11.1, a dynamic linker shared cache is used
            # and there are no common .dylib files under '/usr/lib'.
            #
            # All the commonly-used dynamic libraries are pre-linked together
            # into a single shared file called 'libSystem.dylib'.
            #
            # Here have to try the full path
            #
            # Also, for C libraries, it seems that using
            # '/usr/lib/system/libsystem_*' works for 'dlSymsName'
            handle <- dynfind_try(paste("/usr/lib/system/libsystem_", name, ".dylib", sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynfind_try(paste("/usr/lib/lib", name, ".dylib", sep = ""), ...)
        }
    } else {
        function(name, ...) {
            handle <- dynfind_try(c(
                paste("lib", name, ".so", sep = ""),
                paste("lib", name, sep = "")
            ), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynfind_try(dynfind_runtime_files(name), ..., existing.only = TRUE)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynfind_try(dynfind_package_manager_files(name), ..., existing.only = TRUE)
            if (!is.null(handle)) {
                return(handle)
            }
            dynfind_try(paste(name, sep = ""), ...) # needed by Solaris to lookup 'R'.
        }
    }
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
#' Linuxbrew (`/home/linuxbrew/.linuxbrew`) and Scoop (`SCOOP`, `SCOOP_GLOBAL`,
#' `ProgramData/scoop`).
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

#' @param libnames vector of character strings specifying several short library
#'        names.
#'
#' @param auto.unload logical: if `TRUE` then a finalizer is registered that
#'        closes the library on garbage collection. See [dynload()] for details.
#'
#' @return
#' [dynfind()] returns an external pointer (library handle), if search was
#' successful.
#' Otherwise, if no library is located, a `NULL` is returned.
#'
#' @seealso
#' See [dynload()] for details on the loader interface to the OS-specific
#' dynamic linker.
#'
#' @keywords programming interface
#' @rdname dynfind
dynfind <- function(libnames, auto.unload = TRUE) {
    for (libname in libnames) {
        handle <- dynfind1(libname, auto.unload)
        if (!is.null(handle)) {
            return(handle)
        }
    }
}
