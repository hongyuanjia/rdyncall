#' Binding C library functions via thin call wrappers
#'
#' @description
#' Function to bind several foreign functions of a C library via installation of
#' thin R call wrappers.
#'
#' @details
#' `dynbind()` makes a set of C functions available to R through installation of
#' thin call wrappers. The set of functions, including the symbolic name and
#' function type, is specified by `signature`; a character string that encodes a
#' library signature:
#'
#' The **library signature** is a compact plain-text format to specify a
#' set of function bindings.
#' It consists of function names and corresponding
#' [call signature][call-signature].
#' Function bindings are separated by ";" (semicolon);
#' white spaces (including tab and new line) are allowed before and after
#' semicolon.
#'
#' ```
#' function-name ( call-signature ; ...
#' ```
#'
#' Here is an example that specifies three function bindings to the OpenGL
#' library:
#'
#' ```
#' `"glAccum(If)v ; glClear(I)v ; glClearColor(ffff)v ;"`
#' ```
#'
#' Symbolic names are resolved using the library specified by `libnames`.
#' Character short library names are loaded using [dynfind()], character paths
#' are loaded directly using [dynload()], and external pointer handles returned
#' by [dynload()] or [dynfind()] are used as-is.
#' For each function, a thin call wrapper function is created using the
#' following template:
#'
#' ```
#' function(...) .dyncall.<MODE> ( <TARGET>, <SIGNATURE>, ... )
#' ```
#'
#' `<MODE>` is replaced by `callmode` argument, see [dyncall()] for details on
#' calling conventions.
#' `<TARGET>` is replaced by the external pointer, resolved by the
#' `function-name`.
#' `<SIGNATURE>` is replaced by the call signature string contained in
#' `signature`.
#'
#' The call wrapper is installed in the environment given by `envir`.
#' The assignment name is obtained from the function signature.
#' If `pattern` and `replace` is given, a text replacement is applied to the
#' name before assignment, useful for basic C name space mangling such as
#' exchanging the prefix.
#'
#' As a special case, [dynbind()] supports binding of pointer-to-function
#' variables, indicated by setting `funcptr` to `TRUE`, in which case
#' `<TARGET>` is replaced with the expression `unpack(<TARGET>,"p",0)` in order
#' to dereference `<TARGET>` as a pointer-to-function variable at call-time.
#'
#' @param libnames character vector or external pointer handle specifying the
#'        shared library. Character values that contain a path separator, or
#'        name an existing file, are passed directly to [dynload()]. Other
#'        character values are treated as short library names and loaded using
#'        [dynfind()]. External pointer handles returned by [dynload()] or
#'        [dynfind()] are used directly.
#' @param signature character string specifying the *library signature* that
#'        determines the set of foreign function names and types. See details.
#'
#' @param envir the environment to use for installation of call wrappers.
#'
#' @param callmode character string specifying the calling convention, see
#'        details.
#'
#' @param pattern `NULL` or regular expression character string applied to
#'        symbolic names.
#'
#' @param replace `NULL` or replacement character string applied to `pattern`
#'        part of symbolic names.
#'
#' @param funcptr logical, that indicates whether foreign objects refer to
#'        functions (`FALSE`, default) or to function pointer variables
#'        (`TRUE` rarely needed).
#'
#' @return
#' The function returns a list with two fields:
#'
#' \item{libhandle}{External pointer returned by [dynload()].}
#' \item{unresolved.symbols}{vector of character strings, the names of
#' unresolved symbols.}
#'
#' As a side effect, for each wrapper, [dynbind()] assigns the
#' `function-name` to  the corresponding call wrapper function in the
#' environment given by `envir`.
#'
#' If no shared library is found, an error is reported.
#'
#' @examples
#' \donttest{
#' info <- dynbind("R", "R_ShowMessage(Z)v; R_rsort(pi)v;")
#' R_ShowMessage("hello")
#' }
#'
#' @seealso
#' [dyncall()] for details on call signatures and calling conventions,
#' [dynfind()] for details on short library names,
#' [unpack()] for details on reading low-level memory (e.g. dereferencing of
#' (function) pointer variables).
#'
#' @keywords programming interface
#' @export
# TODO: use named character vector for signatures?
dynbind <- function(libnames, signature, envir = parent.frame(), callmode = "default", pattern = NULL, replace = NULL, funcptr = FALSE) {
    # load shared library
    libh <- dynbind_resolve_libhandle(libnames)
    if (is.null(libh)) {
        liblabel <- dynbind_libnames_label(libnames)
        cat("dynbind error: Unable to find shared library '", liblabel, "'.\n", sep = "")
        cat("For details how to install dynport shared libs, type: ?'rdyncall-demos' might help.\n")
        cat("If there is no information about your OS, consult the projects page how to build and install the shared library for your operating-system.\n")
        cat("Make sure the shared library can be found at the default system places or adjust environment variables (e.g. %PATH% or $LD_LIBRARY_PATH).\n")
        stop("unable to find shared library '", liblabel, "'.\n", call. = FALSE)
    }

    # -- convert library signature to signature table

    # eat white spaces
    sigtab <- gsub("[ \n\t]*", "", signature)
    # split functions at ';'
    sigtab <- strsplit(sigtab, ";", fixed = TRUE)[[1L]]
    # split name/call signature at '('
    sigtab <- strsplit(sigtab, "(", fixed = TRUE)

    # -- install functions

    # make function call symbol
    dyncallfunc <- as.symbol(paste("dyncall.", callmode, sep = ""))
    # report info
    syms.failed <- character(0)

    for (i in seq_along(sigtab))
    {
        symname <- sigtab[[i]][[1]]
        rname <- if (!is.null(pattern)) sub(pattern, replace, symname) else symname
        signature <- sigtab[[i]][[2]]
        # lookup symbol
        address <- dynsym(libh, symname)

        if (!is.null(address)) {
            # make call function f
            f <- function(...) NULL
            if (funcptr) {
                body(f) <- substitute(
                    dyncallfunc(unpack(address, 0, "p"), signature, ...),
                    list(dyncallfunc = dyncallfunc, address = address, signature = signature)
                )
            } else {
                body(f) <- substitute(
                    dyncallfunc(address, signature, ...),
                    list(dyncallfunc = dyncallfunc, address = address, signature = signature)
                )
            }
            environment(f) <- envir # NEW
            # install symbol
            assign(rname, f, envir = envir)
        } else {
            syms.failed <- c(syms.failed, symname)
        }
    }
    # return dynbind.report
    structure(
        list(libhandle = libh, unresolved.symbols = syms.failed),
        class = "dynbind.report"
    )
}

dynbind_resolve_libhandle <- function(libnames) {
    if (is.externalptr(libnames)) {
        if (!dynload_is_handle(libnames)) {
            stop("libnames external pointer must be returned by dynload() or dynfind()", call. = FALSE)
        }
        return(libnames)
    }

    if (!is.character(libnames)) {
        stop("libnames must be a character vector or external pointer handle", call. = FALSE)
    }

    for (libname in libnames) {
        handle <- if (dynbind_is_library_path(libname)) {
            dynload(libname)
        } else {
            dynfind(libname)
        }
        if (!is.null(handle)) {
            return(handle)
        }
    }

    NULL
}

dynbind_is_library_path <- function(libname) {
    !is.na(libname) && (grepl("[/\\\\]", libname) || (file.exists(libname) && !dir.exists(libname)))
}

dynbind_libnames_label <- function(libnames) {
    if (is.externalptr(libnames)) {
        return("<external pointer>")
    }
    if (length(libnames)) {
        return(libnames[[1L]])
    }
    "<empty>"
}
