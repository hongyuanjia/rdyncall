#' Loading of shared libraries and resolving of symbols (Alternative Framework)
#'
#' @description
#' Alternative framework for loading of shared libraries and resolving of
#' symbols. The framework offers _automatic unload management_ of shared
#' libraries and provides a direct interface to the dynamic linker of the OS.
#'
#' @details
#' `dynload()` loads a shared library into the current R process using the
#' OS-specific dynamic linker interface.
#' The `libname` is passed _as-is_ directly to the dynamic linker and thus is
#' given in OS-specific notation - see below for details.
#' On success, a handle to the library represented as an external pointer R
#' objects is returned, otherwise `NULL`.
#' If `auto.unload` is `TRUE`, a finalizer function is registered that will
#' unload the library on garbage collection via `dynunload()`.
#'
#' `dynsym()` looks up symbol names in loaded libraries and resolves them to
#' memory addresses returned as external pointer R objects.
#' Otherwise `NULL` is returned.
#' If `protect.lib` is `TRUE`, the library handle is _protected_ by resolved
#' address external pointers from unloading.
#'
#' `dynpath()` returns the full path of the loaded library specified by
#' `libhandle`.
#'
#' `dyncount()` returns the number of symbols in the loaded library specified by
#' `libhandle`.
#'
#' `dynlist()` returns all symbol names in the loaded library specified by
#' `libhandle`.
#'
#' `dynunload()` explicitly unreferences the loaded library specified by
#' `libhandle`.
#'
#' Setting both `auto.unload` and `protect.lib` to `TRUE`, libraries remain
#' loaded as long as resolved symbols are in use, and they get automatic
#' unloaded when no resolved symbols remain.
#'
#' Dynamic linkers usually hold an internal link count, such that a library can
#' be opened multiple times via `dynload()` - with a balanced number of calls to
#' `dynunload()` that decreases the link count to unload the library again.
#'
#' Similar functionality is available via [base::dyn.load()] and
#' [base::getNativeSymbolInfo()],
#' except that path names are filtered and no automatic unloading of libraries
#' is supported.
#'
#' # Shared library
#'
#' Shared libraries are single files that contain compiled code, data and
#' meta-information. The code and data can be loaded and mapped to a process at
#' run-time once. Operating system platforms have slightly different schemes for
#' naming, searching and linking options.
#'
#' | Platform                             | Binary format | File Extension |
#' |:-------------------------------------|:--------------|:---------------|
#' | Linux, BSD derivates and Sun Solaris | ELF format    | `so`           |
#' | Darwin / Apple macOS                 | Mach-O format | `dylib`        |
#' | Microsoft Windows                    | PE format     | `dll`          |
#'
#' # Library search on Posix platforms (Linux,BSD,Sun Solaris)
#'
#' The following text is taken from the Linux `dlopen` manual page:
#'
#' These search rules will only be applied to path names that do not contain an
#' embedded '/'.
#'
#' - If the `LD_LIBRARY_PATH` environment variable is defined to contain a
#'   colon-separated list of directories, then these are searched.
#' - The cache file `/etc/ld.so.cache` is checked to see whether it contains an
#'   entry for filename.
#' - The directories `/lib` and `/usr/lib` are searched (in that order).
#'
#' If the library has dependencies on other shared libraries, then these are
#' also automatically loaded by the dynamic linker using the same rules.
#'
#' # Library search on Darwin (Mac OS X) platforms
#'
#' The following text is taken from the Mac OS X `dlopen` manual page:
#'
#' `dlopen()` searches for a compatible Mach-O file in the directories specified
#' by a set of environment variables and the process's current working directory.
#' When set, the environment variables must contain a colon-separated list of
#' directory paths, which can be absolute or relative to the current working
#' directory. The environment variables are `$LD_LIBRARY_PATH`,
#' `$DYLD_LIBRARY_PATH`, and `$DYLD_FALLBACK_LIBRARY_PATH`.
#' The first two variables have no default value. The default value of
#' `$DYLD_FALLBACK_LIBRARY_PATH` is `$HOME/lib;/usr/local/lib;/usr/lib`.
#' `dlopen()` searches the directories specified in the environment variables in
#' the order they are listed.
#'
#' When path doesn't contain a slash character (i.e. it is just a leaf name),
#' `dlopen()` searches the following until it finds a compatible Mach-O file:
#' `$LD_LIBRARY_PATH`, `$DYLD_LIBRARY_PATH`, current working directory,
#' `$DYLD_FALLBACK_LIBRARY_PATH`.
#'
#' When path contains a slash (i.e. a full path or a partial path) `dlopen()`
#' searches the following the following until it finds a compatible Mach-O file:
#' `$DYLD_LIBRARY_PATH` (with leaf name from path ), current working directory
#' (for partial paths), `$DYLD_FALLBACK_LIBRARY_PATH` (with leaf name from path).
#'
#' # Library search on Microsoft Windows platforms
#'
#' The following text is taken from the Window SDK Documentation:
#'
#' If no file name extension is specified [...], the default library extension
#' `.dll` is appended.
#' However, the file name string can include a trailing point character (.) to
#' indicate that the shared library module name has no extension.
#' When no path is specified, the function searches for loaded modules whose
#' base name matches the base name of the module to be loaded.
#' If the name matches, the load succeeds.
#' Otherwise, the function searches for the file in the following sequence:
#'
#' - The directory from which the application loaded.
#' - The current directory.
#' - The system directory. Use the `GetSystemDirectory` Win32 API function to
#'   get the path of this directory.
#' - The 16-bit system directory. There is no function that obtains the path of
#'   this directory, but it is searched. Windows Me/98/95: This directory does
#'   not exist.
#' - The Windows directory. Use the `GetWindowsDirectory` Win32 API function to
#'   get the path of this directory.
#' - The directories that are listed in the `PATH` environment variable.
#'
#' Windows Server 2003, Windows XP SP1:  The default value of
#' `HKLM\System\CurrentControlSet\Control\Session Manager\SafeDllSearchMode` is
#' 1 (current directory is searched after the
#' system and Windows directories).
#'
#' Windows XP:  If `HKLM\System\CurrentControlSet\Control\Session
#' Manager\SafeDllSearchMode` is 1, the current directory is searched after the
#' system and Windows directories, but before the directories in the PATH
#' environment variable. The default value is 0 (current directory is searched
#' before the system and Windows directories).
#'
#' The first directory searched is the one directory containing the image file
#' used to create the calling process.
#' Doing this allows private dynamic-link library (DLL) files associated with a
#' process to be found without adding the process's installed directory to the
#' `PATH` environment variable.
#'
#' The search path can be altered using the `SetDllDirectory()` function.
#' This solution is recommended instead of using `SetCurrentDirectory()` or
#' hard-coding the full path to the DLL.
#'
#' If a path is specified and there is a redirection file for the application,
#' the function searches for the module in the application's directory.
#' If the module exists in the application's directory, the `LoadLibrary()`
#' function ignores the specified path and loads the module from the
#' application's directory.
#' If the module does not exist in the application's directory, `LoadLibrary()`
#' loads the module from the specified directory.
#' For more information, see Dynamic Link Library Redirection from the Windows
#' SDK Documentation.
#'
#' # Portability
#'
#' The implementation is based on the _dynload_ library (part of the DynCall
#' project) which has been ported to all major R platforms (ELF (Linux, BSD,
#' Solaris), Mach-O (Mac OS X) and Portable Executable (Win32/64)).
#'
#' @param libname character string giving the pathname to a shared library in
#'        OS-specific notation.
#'
#' @param libhandle external pointer representing a handle to an opened library.
#'
#' @param symname character string specifying a symbolic name to be resolved.
#'
#' @param auto.unload logical, if `TRUE` a finalizer will be registered that
#'        will automatically unload the library.
#'
#' @param protect.lib logical, if `TRUE` resolved external pointers protect
#'        library handles from finalization.
#'
#' @return
#' `dynload` returns an external pointer `libhandle` on success. Otherwise
#' `NULL` is returned, if the library is not found or the linkage failed.
#'
#' `dynsym` returns an external pointer `address` on success. Otherwise `NULL`
#' is returned, if the address was invalid or the symbol has not been found.
#'
#' `dynunload` always returns `NULL`.
#'
#' `dynpath` returns a single string.
#'
#' `dyncount` returns a single integer.
#'
#' `dynlist` returns a character vector.
#'
#' @note
#' On macOS, `dynlist()` enumerates symbols from system libraries in the dyld
#' shared cache on a best-effort basis using Mach-O export information. For
#' `/usr/lib/lib*.dylib` system aliases, matching `/usr/lib/system/libsystem_*`
#' re-exports are included without expanding the entire libSystem umbrella.
#'
#' @seealso
#' This facility is used by [dynfind()] and [dynbind()].
#' Similar functionality is available from [base::dyn.load()] and
#' [base::getNativeSymbolInfo()].
#'
#' @keywords programming interface
#' @rdname dynload
#' @export
dynload <- function(libname, auto.unload = TRUE) {
    libname <- as.character(libname)
    stopifnot(is.character(libname))

    libh <- .Call("C_dynload", libname, PACKAGE = "rdyncall")
    # append ".dll" if on Windows
    if (is.null(libh) && .Platform$OS.type == "windows" &&
        any(nodll <- !is.na(libname) & !grepl("\\.dll$", libname, ignore.case = TRUE))
    ) {
        libname[nodll] <- paste0(libname[nodll], ".dll")
        # try again
        libh <- .Call("C_dynload", libname, PACKAGE = "rdyncall")
    }

    if (!is.null(libh)) {
        attr(libh, "path") <- libname
        attr(libh, "auto.unload") <- auto.unload
        if (auto.unload) reg.finalizer(libh, dynunload)
    }
    libh
}

#' @rdname dynload
#' @export
dynunload <- function(libhandle) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dynunload", libhandle, PACKAGE = "rdyncall")
}

#' @rdname dynload
#' @export
dynsym <- function(libhandle, symname, protect.lib = TRUE) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dynsym", libhandle, as.character(symname), as.logical(protect.lib), PACKAGE = "rdyncall")
}

#' @rdname dynload
#' @export
dynpath <- function(libhandle) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dynpath", libhandle, PACKAGE = "rdyncall")
}

#' @rdname dynload
#' @export
dyncount <- function(libhandle) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dyncount", libhandle, PACKAGE = "rdyncall")
}

#' @rdname dynload
#' @export
dynlist <- function(libhandle) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dynlist", libhandle, PACKAGE = "rdyncall")
}
