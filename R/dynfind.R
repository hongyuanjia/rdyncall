dynfind1 <- if (.Platform$OS.type == "windows") {
    function(name, ...) {
        handle <- dynload(paste("lib", name, sep = ""), ...)
        if (!is.null(handle)) {
            return(handle)
        }
        dynload(name, ...)
    }
} else {
    if (Sys.info()[["sysname"]] == "Darwin") {
        function(name, ...) {
            handle <- dynload(paste(name, ".framework/", name, sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynload(paste("lib", name, ".dylib", sep = ""), ...)
        }
    } else {
        function(name, ...) {
            handle <- dynload(paste("lib", name, ".so", sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynload(paste("lib", name, sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynload(paste(name, sep = ""), ...) # needed by Solaris to lookup 'R'.
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
#' The vector of `location`s is initialized by environment variables such
#' as `PATH` on Windows and `LD_LIBRARY_PATH` on Unix-flavour systems in
#' additional to some hardcoded locations: `/opt/local/lib`, `/usr/local/lib`,
#' `/usr/lib` and `/lib`.
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
