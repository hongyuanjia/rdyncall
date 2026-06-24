#' Dynamic R Bindings to standard and common C libraries
#'
#' @description
#' Functions to turn DCF DynPort files into generated R packages that provide
#' wrappers for C functions, object-like macros, enums and data types.
#'
#' @details
#' `dynport()` offers a convenient method for binding entire C libraries to R.
#' This mechanism runs cross-platform and uses dynamic linkage but it implies
#' that the run-time library of a chosen binding need to be pre-installed in the
#' system.
#' Depending on the OS, the run-time libraries may be pre-installed or require
#' manual installation.
#' See [rdyncall-demos] for OS-specific installation notes for several C
#' libraries.
#'
#' The binding method is data-driven using platform-portable specifications named
#' _DynPort_ files. The current implementation supports DCF (Debian Control File)
#' `.dynport` files.
#'
#' When `dynport()` processes a _DynPort_ file, it generates and installs a real
#' R package whose namespace is populated at load time from the DynPort metadata.
#' By default, generated package names use the prefix given by option
#' `rdyncall.dynport.package.prefix`, which defaults to `"dyn."`. For example,
#' a DynPort with `Package: SDL2` is installed as `dyn.SDL2` unless a package
#' name is explicitly supplied.
#'
#' The following gives a list of currently supported DCF _DynPorts_:
#'
#' | **DynPort name/C library** | **Description**                                 |
#' |:---------------------------|:------------------------------------------------|
#' | `SDL2`                     | Simple DirectMedia Layer 2                      |
#'
#' The DCF format records the following binding metadata:
#'
#' - Functions (and pointer-to-function variables) are mapped via [dynbind()]
#'   and a description of the C library using a _library signatures_.
#' - Symbolic names are assigned to its values for object-like macro defines and
#'   C enum types.
#' - Run-time type-information objects for aggregate C data types (struct and
#'   union) are registered via [cstruct()] and [cunion()].
#'
#' The file path to the _DynPort_ file is derived from `portname` per default.
#' This would refer to `"<repo>/<portname>.dynport"` where `repo` usually refers
#' to the initial _DynPort_ repository located at the sub-folder `"dynports/"`
#' of the package.
#' If `portfile` is given, then this value is taken as file path.
#'
#' A tool suite, comprising AWK (was boost wave), GCC Preprocessor, GCC-XML and
#' XSLT, was used to generate the available _DynPort_ files automatically
#' by extracting type information from C library header files.
#'
#' @param portname the name of a dynport, given as a literal or character
#'        string.
#'
#' @param portfile `NULL` or character string giving a DCF `.dynport` file to
#'        parse.
#'
#' @param repo character string giving the path to the root of the `dynport`
#'        repository.
#'
#' @param package `NULL` or character string giving the generated R package name.
#'        When `NULL`, the `Package` field from the DynPort file is prefixed by
#'        option `rdyncall.dynport.package.prefix`.
#'
#' @param lib character string giving the R library path where the generated
#'        package is installed. Defaults to `dynport_lib()`.
#'
#' @param rebuild logical. If `TRUE`, reinstall an existing generated package
#'        when the DynPort file contents have changed.
#'
#' @param load logical. If `TRUE`, load and attach the generated package in the
#'        current R session after installation.
#'
#' @param quiet logical. If `TRUE`, suppress installation and loading output
#'        where possible.
#'
#' @param create logical. If `TRUE`, create the default DynPort package library
#'        when it does not exist.
#'
#' @param add logical. If `TRUE`, prepend the DynPort package library to
#'        `.libPaths()`.
#'
#' @param envir environment to populate from a DynPort file.
#'
#' @return
#' `dynport()` invisibly returns the generated package name.
#' `dynport_install_package()` invisibly returns the installed package path with
#' the generated package name stored in attribute `"package"`.
#' `dynport_load_into()` invisibly returns `envir`.
#' `dynport_lib()` returns the DynPort package library path.
#'
#' @references
#'
#' Adler, D. (2012) \dQuote{Foreign Library Interface}, _The R Journal_,
#'   **4(1)**, 30--40, June 2012.
#'   \url{https://journal.r-project.org/articles/RJ-2012-004/}
#'
#' Adler, D., Philipp, T. (2008) _DynCall Project_.
#'   \url{https://dyncall.org}
#'
#' Clark, J. (1998). expat - XML Parser Toolkit.
#'   \url{https://expat.sourceforge.net}
#'
#' Ikits, M. and Magallon, M. (2002).  The OpenGL Extension Wrangler Library.
#'   \url{https://glew.sourceforge.net}
#'
#' Latinga, S. (1998). The Simple DirectMedia Layer Library.
#'   \url{https://www.libsdl.org/}
#'
#' Segal, M. and Akeley, K. (1992). The OpenGL Graphics System. A Specification,
#' Version 1.0. \url{https://www.opengl.org}
#'
#' Smith, R. (2001). Open Dynamics Engine. \url{https://ode.org/}
#'
#' @examples
#' \dontrun{
#' dynport(SDL2)
#' dyn.SDL2::SDL_GetPlatform()
#' }
#' @aliases dynport_install_package dynport_load_into dynport_lib
#' @keywords programming interface
#' @author Daniel Adler <dadler@uni-goettingen.de>
#' @export
dynport <- function(portname, portfile = NULL, repo = system.file("dynports", package = "rdyncall"),
                    package = NULL, lib = dynport_lib(), rebuild = FALSE,
                    load = TRUE, quiet = FALSE) {
    # literate portname string
    portname <- as.character(substitute(portname))
    if (is.null(portfile)) {
        # search for portfile
        portfile <- file.path(repo, paste(portname, ".dynport", sep = ""))
        if (!file.exists(portfile)) stop("dynport '", portname, "' not found.")
    }
    installed <- dynport_install_package_impl(
        portname, portfile = portfile, repo = repo, package = package, lib = lib,
        rebuild = rebuild, load = load, quiet = quiet
    )
    invisible(attr(installed, "package"))
}

# ref: {r-lib/desc:::read_dcf()}
dynport_read <- function(file) {
    tryCatch(
        lines <- readLines(file),
        error = function(e) {
            stop(sprintf("Failed to read file '%s': %s", file, e$message), call. = FALSE)
        }
    )

    # get key names
    con <- textConnection(lines, local = TRUE)
    keys <- colnames(read.dcf(con))
    close(con)

    # TODO: handle empty
    if (!length(keys)) return(NULL)

    # check empty lines
    con <- textConnection(lines, local = TRUE)
    res <- read.dcf(con, keep.white = keys)
    close(con)
    if (nrow(res) > 1L) stop("Empty lines found in 'dynport' file.", call. = FALSE)

    con <- textConnection(lines, local = TRUE)
    res2 <- read.dcf(con, keep.white = keys, all = TRUE)
    close(con)
    if (any(mis <- res != res2)) {
        stop(sprintf("Duplicate 'dynport' keys found: [%s]",
            paste(sQuote(colnames(res)[mis]), collapse = ", ")
        ), call. = FALSE)
    }

    # in base::read.dcf(), if values start at a new line, there will be an extra
    # '\n' at the beginning.
    # should remove it in order to get the correct line number
    values <- res[1L, ]
    if (any(lf <- substr(values, 1L, 1L) == "\n")) {
        values[lf] <- substr(values[lf], 2L, nchar(values[lf]))
    }
    if (any(crlf <- nchar(values[!lf]) > 2L & substr(values[!lf], 1L, 2L) == "\r\n")) {
        ind <- which(!lf)[crlf]
        values[ind] <- substr(values[ind], 3L, nchar(values[ind]))
    }

    # get line number for each field
    lnums <- lapply(keys, function(key) {
        pre <- paste0("^\\s*", key, ":")
        loc <- grep(pre, lines)
        # failed to match
        if (!length(loc)) return(integer())
        # only use the first match
        if (length(loc) > 1L) loc <- loc[[1L]]

        # check if the value starts at next line
        if (grepl(paste0(pre, "\\s*$"), lines[[loc]])) loc <- loc + 1L
        loc
    })

    # check both 'Enum' and 'Enum/...'
    if ("Enum" %in% keys && any(grepl("^Enum/.+", keys))) {
        stop("Both 'Enum' and 'Enum/...' found. Should have either one.", call. = FALSE)
    }

    dynport_parse_fields(keys, values, lnums, envir = parent.frame(2L))
}

dynport_parse_fields <- function(keys, values, lnums, envir = parent.frame()) {
    out <- mapply(dynport_parse_field,
        key = keys, value = values, lnum = lnums, MoreArgs = list(envir = envir),
        SIMPLIFY = FALSE, USE.NAMES = TRUE
    )

    # put all enums into a single element
    if (is.null(out[["Enum"]]) && any(is_enum <- grepl("^Enum/.+", names(out)))) {
        enums <- unlist(out[is_enum], FALSE, FALSE)
        names(enums) <- vapply(out[is_enum], names, "", USE.NAMES = FALSE)
        out <- c(out[!is_enum], list(Enum = enums))
    }
    out
}

dynport_parse_field <- function(key, value, lnum, envir = parent.frame()) {
    if (grepl("^Enum/.+", key)) {
        dynport_parse_enum(value, lnum, key)
    } else {
        switch(key,
            "Package"  = dynport_parse_package(value,  lnum),
            "Version"  = dynport_parse_version(value,  lnum),
            "Library"  = dynport_parse_library(value,  lnum),
            "Function" = dynport_parse_function(value, lnum, envir),
            "FuncPtr"  = dynport_parse_funcptr(value,  lnum, envir),
            "Struct"   = dynport_parse_struct(value,   lnum, envir),
            "Union"    = dynport_parse_union(value,    lnum, envir),
            "Enum"     = dynport_parse_enum(value,     lnum, key = "Enum"),
            NULL
        )
    }
}

dynport_parse_package <- function(value, lnum = 1L) {
    val <- split_lines(value)
    lnum <- lnum + seq_along(val) - 1L
    empty <- val == ""

    if (all(empty)) return(NULL)

    if (any(empty)) {
        val <- val[!empty]
        lnum <- lnum[!lnum]
    }

    if (length(val) > 1L) {
        dynport_issue_error("Package", NULL, lnum, val, "Only a single string is allowed")
    }

    if (!grepl("^[a-zA-Z0-9\\.]*$", val)) {
        dynport_issue_error("Package", NULL, lnum, val, "Only contain ASCII letters, numbers and dots are allowed")
    }

    if (nchar(val) < 2L) {
        dynport_issue_error("Package", NULL, lnum, val, "At least two character long is required")
    }

    if (!grepl("^[a-zA-z]", val)) {
        dynport_issue_error("Package", NULL, lnum, val, "First character should be a letter")
    }

    if (grepl("\\.$", val)) {
        dynport_issue_error("Package", NULL, lnum, val, "Last character should not be a dot")
    }

    val
}

dynport_parse_version <- function(value, lnum = 1L) {
    val <- split_lines(value)
    lnum <- lnum + seq_along(val) - 1L
    empty <- val == ""

    if (all(empty)) return(NULL)

    if (any(empty)) {
        val <- val[!empty]
        lnum <- lnum[!lnum]
    }

    if (length(val) > 1L) {
        dynport_issue_error("Version", NULL, lnum, val, "Only a single string is allowed")
    }

    re <- "^[0-9]+[-\\.][0-9]+([-\\.][0-9]+)*$"
    if (!grepl(re, val)) {
        dynport_issue_error("Version", NULL, lnum, value, "Invalid specification")
    }

    numeric_version(val)
}

dynport_parse_library <- function(value, lnum = 1L) {
    vals <- split_lines(value)
    lnum <- lnum + seq_along(vals) - 1L

    lnum <- lnum[vals != ""]
    vals <- vals[vals != ""]

    # check if valid file names
    # ref: fs::path_sanitize
    illegal <- "[/\\?<>\\:*|\":]"
    control <- "[[:cntrl:]]"
    reserved <- "^[.]+$"
    windows_reserved <- "^(con|prn|aux|nul|com[0-9]|lpt[0-9])([.].*)?$"
    windows_trailing <- "[. ]+$"

    invld <- vapply(
        c(illegal, control, reserved, windows_reserved, windows_trailing),
        grepl, logical(length(vals)), x = vals, ignore.case = TRUE
    )
    invld <- vapply(seq_len(nrow(invld)), function(i) Reduce(`||`, invld[i, ]), logical(1L))

    if (any(invld)) {
        dynport_issue_error("Library", NULL, lnum[invld], vals[invld], "Invalid file name found")
    }

    gsub("\\", "/", vals, fixed = TRUE)
}

dynport_parse_function <- function(value, lnum = 1L, envir = parent.frame()) {
    # check if empty
    if (trimws(value) == "") return(NULL)

    # split functions at ';'
    sigs <- strsplit(value, ";", fixed = TRUE)[[1L]]

    # count lines per signature
    lncnt <- vapply(gregexpr("[\r]?\n", sigs), function(m) sum(m > -1L), integer(1L))

    # split name/call signature at '('
    sigs <- strsplit(sigs, "(", fixed = TRUE)

    issue_error <- function(name = NULL, msg) {
        str <- split_lines(paste0(sig, collapse = "("))
        # if first line is an empty line, skip it
        ln <- lnum + c(0L, lncnt[[i]][lncnt[[i]] > 0L])
        if (str[[1L]] == "") {
            str <- str[-1L]
            ln <- ln[-1L]
        }
        stopifnot(length(ln) == length(str))
        dynport_issue_error("Function", name, ln, str, msg)
    }

    # init results
    out <- vector("list", length(sigs))
    for (i in seq_along(sigs)) {
        sig <- sigs[[i]]
        if (length(sig) != 2L) {
            issue_error(NULL, "Invalid specification")
        }

        # parse struct name
        name <- gsub("[ \r\n\t]*", "", sig[[1L]])

        if (!nchar(name)) {
            issue_error(NULL, "Missing name in specification")
        }

        # split argument signature and return value
        if (!grepl(")", sig[[2L]], fixed = TRUE)) {
            issue_error(name, "Missing ')' in specification")
        }

        tail <- strsplit(sig[[2L]], ")", fixed = TRUE)[[1L]]

        len <- length(tail)
        if (!len || len > 2L) {
            issue_error(name, "Missing ')' in specification")
        } else if (len == 1L) {
            issue_error(name, "Missing return signature in specification")
        }

        # TODO: invalid names?
        ret_nm <- strsplit(trimws(tail[[2L]]), "[ \r\n\t]+")[[1L]]
        # this is the case when there are extra ')'
        if (!length(ret_nm)) {
            issue_error(name, "Extra ')' in specification")
        }

        arg <- dynport_parse_types("struct", tail[[1L]], envir, allow_arrays = FALSE)
        dynport_issue_type_error(arg, tail[[1L]], issue_error, name, "argument")

        nm <- ret_nm[-1L]
        if (length(nm)) {
            if (length(arg$type) != length(nm)) {
                issue_error(name,
                    sprintf("Imbalance number of argument types (%s) and names (%s) found",
                        sQuote(length(arg$type)), sQuote(length(nm))
                    )
                )
            }

            if (anyDuplicated(nm)) {
                issue_error(name,
                    sprintf("Duplicated argument names (%s) found",
                        paste0(sQuote(nm[duplicated(nm)]), collapse = ", ")
                    )
                )
            }

            arg <- lapply(arg$type, get_typeinfo_by_name, envir = envir)
            for (j in seq_along(arg)) {
                arg[[j]]$arg_name <- nm[[j]]
            }
        }

        ret <- dynport_parse_types("struct", ret_nm[[1L]], allow_arrays = FALSE)
        dynport_issue_type_error(ret, ret_nm[[1L]], issue_error, name, "return")

        lnum <- lnum + lncnt[[i]]

        out[[i]] <- list(name = name, argument = list(sig = tail[[1L]], name = nm), return = ret_nm[[1L]])
    }

    names(out) <- vapply(out, .subset2, "", "name")
    out
}

dynport_parse_funcptr <- function(value, lnum = 1L, envir = parent.frame()) {
    dynport_parse_function(value, lnum, envir)
}

dynport_parse_struct <- function(value, lnum = 1L, envir = parent.frame()) {
    dynport_parse_struct_union(value, lnum, envir, kind = "struct")
}

dynport_parse_union <- function(value, lnum = 1L, envir = parent.frame()) {
    dynport_parse_struct_union(value, lnum, envir, kind = "union")
}

dynport_parse_struct_union <- function(value, lnum = 1L, envir = parent.frame(), kind = "struct") {
    # check if empty
    if (trimws(value) == "") return(NULL)

    # split entries at ';'
    sigs <- unlist(strsplit(value, ";"), FALSE, FALSE)

    # count lines per signature
    lncnt <- vapply(gregexpr("[\r]?\n", sigs), function(m) sum(m > -1L), integer(1L))

    # split name and members at '{'
    sigs <- strsplit(sigs, "{", fixed = TRUE)

    issue_error <- function(name = NULL, msg) {
        str <- split_lines(paste0(sig, collapse = "{"))
        # if first line is an empty line, skip it
        ln <- lnum + c(0L, lncnt[[i]][lncnt[[i]] > 0L])
        if (str[[1L]] == "") {
            str <- str[-1L]
            ln <- ln[-1L]
        }
        stopifnot(length(ln) == length(str))
        dynport_issue_error(
            switch(kind, "struct" = "Struct", "union" = "Union", NULL),
            name, ln, str, msg
        )
    }

    # init results
    out <- vector("list", length(sigs))
    for (i in seq_along(sigs)) {
        sig <- sigs[[i]]

        if (length(sig) != 2L) issue_error(NULL, "Missing '{' in specification")

        # parse struct name
        name <- gsub("[ \r\n\t]*", "", sig[[1L]])

        if (!nchar(name)) {
            issue_error(NULL, "Missing name in specification")
        }

        # split struct signature and field names
        if (!grepl("}", sig[[2L]], fixed = TRUE)) {
            issue_error(name, "Missing '}' in specification")
        }
        tail <- strsplit(sig[[2L]], "}", fixed = TRUE)[[1L]]

        # check field names
        len <- length(tail)
        if (!len || len > 2L) {
            issue_error(name, "Missing '}' in specification")
        } else if (len == 1L) {
            field_layout <- list(fields = empty_field_specs(), layout = aggregate_layout())
        } else {
            # TODO: invalid field names?
            field_layout <- tryCatch(
                parse_aggregate_fields(tail[[2L]]),
                error = function(e) issue_error(name, conditionMessage(e))
            )
            # this is the case when there are extra '}'
            if (!nrow(field_layout$fields)) {
                issue_error(name, "Extra '}' in specification")
            }
        }

        parsed <- dynport_parse_types(kind, tail[[1L]], envir, layout = field_layout$layout)
        dynport_issue_type_error(parsed, tail[[1L]], issue_error, name)

        # check imbalance between signatures and field names
        if (length(parsed$type) != nrow(field_layout$fields)) {
            issue_error(name,
                sprintf("Imbalance number of field types (%s) and names (%s) found",
                    sQuote(length(parsed$type)), sQuote(nrow(field_layout$fields))
                )
            )
        }

        lnum <- lnum + lncnt[[i]]

        out[[i]] <- tryCatch(
            make_aggregate_info(name, kind, tail[[1L]], field_layout$fields,
                envir = envir, layout = field_layout$layout),
            error = function(e) issue_error(name, conditionMessage(e))
        )
    }

    names(out) <- vapply(out, .subset2, "", "name")
    out
}

dynport_parse_types <- function(kind = c("struct", "union"), signature, envir = parent.frame(),
                                allow_arrays = TRUE, layout = aggregate_layout()) {
    parse_aggregate_types(kind, signature, envir = envir, allow_arrays = allow_arrays,
        layout = layout, on_error = "return")
}

dynport_type_error_message <- function(parsed, signature, context = NULL) {
    found <- if (is.null(context)) "found" else paste("found in", context)
    type <- attr(parsed, "type")
    if (!is.null(type)) {
        return(sprintf("Invalid base type name %s %s", sQuote(type), found))
    }

    pos <- attr(parsed, "pos")
    str <- if (is.null(pos)) signature else substr(signature, pos[1L], pos[2L])
    if (identical(attr(parsed, "reason"), "array")) {
        return(sprintf("Invalid fixed array member %s %s", sQuote(str), found))
    }

    sprintf("Missing '>' in struct member %s %s", sQuote(str), found)
}

dynport_issue_type_error <- function(parsed, signature, issue_error, name = NULL, context = NULL) {
    if (!is.null(parsed) && !length(parsed)) {
        issue_error(name, dynport_type_error_message(parsed, signature, context))
    }
}

dynport_parse_enum <- function(value, lnum, key) {
    if (key == "Enum") {
        # no enums
        if (trimws(value) == "") return(NULL)

        # otherwise, should be invalid
        dynport_issue_error("Enum", NULL, lnum, value, "Invalid specification found")
    }

    # split lines
    s <- trimws(strsplit(value, "[\r]?\n")[[1L]])
    # calculate line numbers
    l <- lnum + seq_along(s) - 1L

    # remove empty lines
    l <- l[s != ""]
    s <- s[s != ""]

    # get the enum name
    if (grepl("^Enum/", key)) key <- sub("^Enum/", "", key)

    # split member names and values by "="
    nms_vals <- strsplit(s, "=", fixed = TRUE)

    # check if invalid
    if (any(invld <- lengths(nms_vals) != 2L)) {
        dynport_issue_error("Enum", key, l[invld], s[invld],
            "Invalid member specification found"
        )
    }

    # valid names
    nms <- trimws(vapply(nms_vals, .subset2, "", 1L))
    # TODO: check if this is sufficient
    if (any(invld <- nms != make.names(nms))) {
        dynport_issue_error("Enum", key, l[invld], s[invld],
            "Invalid member name found"
        )
    }

    # check values
    vals <- trimws(vapply(nms_vals, .subset2, "", 2L))
    inits <- suppressWarnings(as.integer(vals))
    if (any(invld <- is.na(inits) | vals != as.character(inits))) {
        dynport_issue_error("Enum", key, l[invld], s[invld],
            "Invalid member value found"
        )
    }

    names(inits) <- nms
    out <- list(inits)
    names(out) <- key
    out
}

dynport_issue_error <- function(type, name, lnums, values, reason) {
    stop(sprintf(
        "%s for %s%s:\n%s",
        reason,
        if (length(name)) type else sQuote(type),
        if (length(name)) paste("", sQuote(name)) else "",
        paste0(sprintf("  [Line %s]: \"%s\"", lnums, values), collapse = "\n")
    ), call. = FALSE)
}

#' @rdname dynport
#' @export
dynport_install_package <- function(portname, portfile = NULL,
                                    repo = system.file("dynports", package = "rdyncall"),
                                    package = NULL, lib = dynport_lib(), rebuild = FALSE,
                                    load = FALSE, quiet = FALSE) {
    dynport_install_package_impl(
        as.character(substitute(portname)), portfile = portfile, repo = repo,
        package = package, lib = lib, rebuild = rebuild, load = load,
        quiet = quiet
    )
}

dynport_install_package_impl <- function(portname, portfile = NULL, repo, package = NULL,
                                         lib = dynport_lib(), rebuild = FALSE,
                                         load = FALSE, quiet = FALSE) {
    portfile <- dynport_resolve_portfile(portname, portfile, repo)
    port <- dynport_read(portfile)
    if (is.null(port)) {
        stop("Empty 'dynport' file.", call. = FALSE)
    }

    package <- dynport_package_name(port, package)
    md5 <- dynport_md5(portfile)
    lib <- dynport_lib_path(lib, create = TRUE)

    skip_install <- dynport_prepare_install(package, lib, md5, rebuild)
    if (!skip_install) {
        src <- dynport_create_package_source(port, portfile, portname, package, md5)
        on.exit(unlink(src, recursive = TRUE, force = TRUE), add = TRUE)
        dynport_install_source(src, lib, quiet = quiet)
    }

    path <- normalizePath(file.path(lib, package), "/", mustWork = FALSE)
    if (load) {
        dynport_load_package(package, lib, quiet = quiet)
    }

    attr(path, "package") <- package
    invisible(path)
}

#' @rdname dynport
#' @export
dynport_load_into <- function(portfile, envir) {
    if (!is.environment(envir)) {
        stop("'envir' must be an environment.", call. = FALSE)
    }

    port <- dynport_read(portfile)
    if (is.null(port)) {
        stop("Empty 'dynport' file.", call. = FALSE)
    }

    dynport_validate_export_names(dynport_export_names(port))
    dynport_assign_typeinfos(port[["Struct"]], envir)
    dynport_assign_typeinfos(port[["Union"]], envir)
    dynport_assign_enums(port[["Enum"]], envir)
    dynport_assign_functions(port, "Function", envir, funcptr = FALSE)
    dynport_assign_functions(port, "FuncPtr", envir, funcptr = TRUE)

    invisible(envir)
}

#' @rdname dynport
#' @export
dynport_lib <- function(create = TRUE, add = FALSE) {
    lib <- getOption("rdyncall.dynport.lib", NULL)
    if (is.null(lib)) {
        cache <- if (exists("R_user_dir", envir = asNamespace("tools"), mode = "function")) {
            tools::R_user_dir("rdyncall", "cache")
        } else {
            file.path(path.expand("~"), ".cache", "R", "rdyncall")
        }
        lib <- file.path(cache, "dynports", paste0("R-", as.character(getRversion())))
    }

    lib <- dynport_lib_path(lib, create = create)
    if (add) {
        .libPaths(unique(c(lib, normalizePath(.libPaths(), "/", mustWork = FALSE))))
    }
    lib
}

dynport_resolve_portfile <- function(portname, portfile = NULL, repo) {
    if (is.null(portfile)) {
        portfile <- file.path(repo, paste0(portname, ".dynport"))
    }
    portfile <- path.expand(as.character(portfile))
    if (length(portfile) != 1L || is.na(portfile) || !nzchar(portfile)) {
        stop("'portfile' must be a single non-empty path.", call. = FALSE)
    }
    if (!file.exists(portfile)) {
        stop("dynport '", portname, "' not found.", call. = FALSE)
    }
    normalizePath(portfile, "/", mustWork = TRUE)
}

dynport_lib_path <- function(lib, create = TRUE) {
    lib <- path.expand(as.character(lib))
    if (length(lib) != 1L || is.na(lib) || !nzchar(lib)) {
        stop("'lib' must be a single non-empty path.", call. = FALSE)
    }
    if (create && !dir.exists(lib)) {
        dir.create(lib, recursive = TRUE, showWarnings = FALSE)
    }
    if (create && !dir.exists(lib)) {
        stop("Failed to create dynport package library '", lib, "'.", call. = FALSE)
    }
    normalizePath(lib, "/", mustWork = create)
}

dynport_package_name <- function(port, package = NULL) {
    base <- if (!is.null(port[["Package"]])) {
        as.character(port[["Package"]])
    } else {
        NULL
    }
    if (is.null(base) || !nzchar(base)) {
        stop("The 'dynport' file must define a non-empty 'Package' field.", call. = FALSE)
    }

    if (is.null(package)) {
        prefix <- getOption("rdyncall.dynport.package.prefix", "dyn.")
        package <- paste0(prefix, base)
    }
    dynport_validate_package_name(package)
    package
}

dynport_validate_package_name <- function(package) {
    package <- as.character(package)
    if (length(package) != 1L || is.na(package) || !nzchar(package)) {
        stop("'package' must be a single non-empty string.", call. = FALSE)
    }
    if (!grepl("^[A-Za-z][A-Za-z0-9.]*$", package) || grepl("\\.$", package)) {
        stop("Invalid package name '", package, "'.", call. = FALSE)
    }
    invisible(package)
}

dynport_export_names <- function(port) {
    exports <- character()
    exports <- c(exports, names(port[["Function"]]))
    exports <- c(exports, names(port[["FuncPtr"]]))
    exports <- c(exports, names(port[["Struct"]]))
    exports <- c(exports, names(port[["Union"]]))

    enums <- port[["Enum"]]
    if (!is.null(enums)) {
        exports <- c(exports, names(enums))
        exports <- c(exports, unlist(lapply(enums, base::names), use.names = FALSE))
    }

    dynport_validate_export_names(exports)
}

dynport_validate_export_names <- function(names) {
    names <- names[nzchar(names)]
    invalid <- names != make.names(names)
    if (any(invalid)) {
        stop("Invalid export names found in 'dynport' file: ",
            paste(sQuote(names[invalid]), collapse = ", "),
            call. = FALSE
        )
    }
    duplicates <- unique(names[duplicated(names)])
    if (length(duplicates)) {
        stop("Duplicate export names found in 'dynport' file: ",
            paste(sQuote(duplicates), collapse = ", "),
            call. = FALSE
        )
    }
    names
}

dynport_assign_typeinfos <- function(objects, envir) {
    if (!length(objects)) return(invisible())
    for (nm in names(objects)) {
        assign(nm, objects[[nm]], envir = envir)
    }
    invisible()
}

dynport_assign_enums <- function(enums, envir) {
    if (!length(enums)) return(invisible())
    for (nm in names(enums)) {
        vals <- enums[[nm]]
        assign(nm, vals, envir = envir)
        if (length(vals)) {
            list2env(as.list(vals), envir = envir)
        }
    }
    invisible()
}

dynport_assign_functions <- function(port, field, envir, funcptr = FALSE) {
    functions <- port[[field]]
    if (!length(functions)) return(invisible())

    libraries <- port[["Library"]]
    if (!length(libraries)) {
        stop("The 'dynport' file must define 'Library' before binding functions.", call. = FALSE)
    }

    report <- dynbind(
        libraries, dynport_compact_signature(functions),
        envir = envir, funcptr = funcptr
    )
    dynport_assign_unresolved(report$unresolved.symbols, envir)
    invisible(report)
}

dynport_compact_signature <- function(functions) {
    paste0(vapply(functions, function(x) {
        paste0(x$name, "(", x$argument$sig, ")", x$return, ";")
    }, character(1L)), collapse = "\n")
}

dynport_assign_unresolved <- function(symbols, envir) {
    for (symbol in symbols) {
        f <- local({
            unresolved <- symbol
            function(...) {
                stop("Unresolved DynPort symbol '", unresolved, "'.", call. = FALSE)
            }
        })
        environment(f) <- envir
        assign(symbol, f, envir = envir)
    }
    invisible()
}

dynport_md5 <- function(file) {
    unname(tools::md5sum(file))
}

dynport_prepare_install <- function(package, lib, md5, rebuild = FALSE) {
    loaded <- package %in% loadedNamespaces()
    if (loaded) {
        loaded_info <- dynport_package_description(getNamespaceInfo(getNamespace(package), "path"))
        if (!dynport_is_generated_package(loaded_info)) {
            stop("Package '", package, "' is already loaded and was not generated by rdyncall.",
                call. = FALSE
            )
        }
        if (!identical(dynport_description_value(loaded_info, "Config/rdyncall/dynport-md5"), md5)) {
            if (!rebuild) {
                stop("Generated dynport package '", package,
                    "' is already loaded with different contents; use rebuild = TRUE.",
                    call. = FALSE
                )
            }
            dynport_unload_package(package)
        }
    }

    installed <- dynport_package_description(file.path(lib, package))
    if (is.null(installed)) {
        return(FALSE)
    }
    if (!dynport_is_generated_package(installed)) {
        stop("Package '", package, "' is already installed in '", lib,
            "' and was not generated by rdyncall.", call. = FALSE
        )
    }

    installed_md5 <- dynport_description_value(installed, "Config/rdyncall/dynport-md5")
    if (identical(installed_md5, md5)) {
        return(TRUE)
    }
    if (!rebuild) {
        stop("Generated dynport package '", package,
            "' is already installed with different contents; use rebuild = TRUE.",
            call. = FALSE
        )
    }

    if (package %in% loadedNamespaces()) {
        dynport_unload_package(package)
    }
    unlink(file.path(lib, package), recursive = TRUE, force = TRUE)
    FALSE
}

dynport_unload_package <- function(package) {
    search_name <- paste0("package:", package)
    if (search_name %in% search()) {
        detach(search_name, character.only = TRUE)
    }
    if (package %in% loadedNamespaces()) {
        tryCatch(
            unloadNamespace(package),
            error = function(e) {
                stop("Failed to unload generated dynport package '", package,
                    "'. Restart R and try again. Details: ", conditionMessage(e),
                    call. = FALSE
                )
            }
        )
    }
    invisible()
}

dynport_package_description <- function(path) {
    desc <- file.path(path, "DESCRIPTION")
    if (!file.exists(desc)) return(NULL)
    as.list(read.dcf(desc)[1L, ])
}

dynport_description_value <- function(desc, field) {
    if (is.null(desc)) return(NULL)
    value <- desc[[field]]
    if (is.null(value) || is.na(value)) NULL else value
}

dynport_is_generated_package <- function(desc) {
    isTRUE(identical(dynport_description_value(desc, "Config/rdyncall/generated"), "true"))
}

dynport_create_package_source <- function(port, portfile, portname, package, md5) {
    src <- tempfile(paste0(package, "-"))
    dir.create(src, recursive = TRUE, showWarnings = FALSE)
    dir.create(file.path(src, "R"), recursive = TRUE)
    dir.create(file.path(src, "inst", "dynports"), recursive = TRUE)

    dynport_basename <- basename(portfile)
    file.copy(portfile, file.path(src, "inst", "dynports", dynport_basename), overwrite = TRUE)
    dynport_write_description(src, port, portname, package, dynport_basename, md5)
    dynport_write_namespace(src, dynport_export_names(port))
    dynport_write_loader(src, dynport_basename)
    dynport_write_license(src)
    src
}

dynport_write_description <- function(src, port, portname, package, dynport_file, md5) {
    dynport_package <- as.character(port[["Package"]])
    dynport_version <- if (is.null(port[["Version"]])) "0.0.0" else as.character(port[["Version"]])
    rdyncall_version <- tryCatch(
        as.character(utils::packageVersion("rdyncall")),
        error = function(e) "0.0.0"
    )
    desc <- data.frame(
        check.names = FALSE,
        Package = package,
        Type = "Package",
        Title = paste("DynPort Bindings for", dynport_package),
        Version = dynport_version,
        Author = "Generated by rdyncall",
        Maintainer = "rdyncall DynPort generator <noreply@example.com>",
        Description = paste("Generated rdyncall DynPort wrapper package for", dynport_package, "bindings."),
        License = "file LICENSE",
        Encoding = "UTF-8",
        Imports = "rdyncall",
        `Config/rdyncall/generated` = "true",
        `Config/rdyncall/dynport-portname` = portname,
        `Config/rdyncall/dynport-package` = dynport_package,
        `Config/rdyncall/dynport-version` = dynport_version,
        `Config/rdyncall/dynport-file` = dynport_file,
        `Config/rdyncall/dynport-md5` = md5,
        `Config/rdyncall/rdyncall-version` = rdyncall_version
    )
    write.dcf(desc, file = file.path(src, "DESCRIPTION"))
}

dynport_write_namespace <- function(src, exports) {
    lines <- if (length(exports)) paste0("export(", exports, ")") else character()
    writeLines(lines, file.path(src, "NAMESPACE"), useBytes = TRUE)
}

dynport_write_loader <- function(src, dynport_file) {
    lines <- c(
        ".onLoad <- function(libname, pkgname) {",
        sprintf("    portfile <- system.file(\"dynports\", %s, package = pkgname, mustWork = TRUE)", deparse(dynport_file)),
        "    rdyncall::dynport_load_into(portfile, envir = parent.env(environment()))",
        "}"
    )
    writeLines(lines, file.path(src, "R", "zzz.R"), useBytes = TRUE)
}

dynport_write_license <- function(src) {
    writeLines(c(
        "This package was generated by rdyncall from a DynPort specification.",
        "",
        "Permission to use, copy, modify, and/or distribute this generated package",
        "for any purpose with or without fee is hereby granted, provided that this",
        "permission notice appears in all copies.",
        "",
        "THE GENERATED PACKAGE IS PROVIDED \"AS IS\" AND WITHOUT ANY WARRANTY."
    ), file.path(src, "LICENSE"), useBytes = TRUE)
}

dynport_install_source <- function(src, lib, quiet = FALSE) {
    args <- c("CMD", "INSTALL", "--no-test-load", "-l", shQuote(lib), shQuote(src))
    env <- paste0("R_LIBS=", paste(unique(c(lib, .libPaths())), collapse = .Platform$path.sep))
    if (quiet) {
        out <- system2(file.path(R.home("bin"), "R"), args, stdout = TRUE, stderr = TRUE, env = env)
        status <- attr(out, "status")
        if (is.null(status)) status <- 0L
        if (status != 0L) {
            stop("Failed to install generated dynport package:\n",
                paste(out, collapse = "\n"), call. = FALSE
            )
        }
    } else {
        status <- system2(file.path(R.home("bin"), "R"), args, env = env)
        if (status != 0L) {
            stop("Failed to install generated dynport package.", call. = FALSE)
        }
    }
    invisible()
}

dynport_load_package <- function(package, lib, quiet = FALSE) {
    lib <- dynport_lib_path(lib, create = TRUE)
    if (!lib %in% normalizePath(.libPaths(), "/", mustWork = FALSE)) {
        .libPaths(unique(c(lib, normalizePath(.libPaths(), "/", mustWork = FALSE))))
    }
    if (paste0("package:", package) %in% search()) {
        return(invisible(TRUE))
    }
    library(package = package, character.only = TRUE, lib.loc = lib,
        quietly = quiet, warn.conflicts = !quiet
    )
    invisible(TRUE)
}

split_lines <- function(x, trim = TRUE) {
    s <- strsplit(x, "[\r]?\n")[[1L]]
    if (trim) trimws(s) else s
}
