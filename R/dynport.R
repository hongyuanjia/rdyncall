#' Dynamic R Bindings to standard and common C libraries
#'
#' @description
#' Function to bind APIs of standard and common C libraries to R via dynamically
#' created interface environment objects comprising R wrappers for C functions,
#' object-like macros, enums and data types.
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
#' The binding method is data-driven using platform-portable specifications
#' named _DynPort_ files.
#' _DynPort_ files are stored in a repository that is installed as part of the
#' package installation. They are generated using the \pkg{porter} package.
#' When `dynport()` processes a _DynPort_ file given by `portname`, an
#' environment object is created, populated with R wrapper and helper objects
#' that make up the interface to the C library, and attached to the search path
#' with the name `dynport:<PORTNAME>`.
#' Unloading of previously loaded dynport environments is achieved via
#' `detach(dynport:<PORTNAME>)`.
#'
#' Up to \pkg{rdyncall} version 0.7.4, R name space objects were used as
#' containers as described in the article _Foreign Library Interface_, thus
#' dynport \sQuote{packages} appeared as `"package:<PORTNAME>"` on the
#' search path.
#' The mechanism to create synthesized R packages at run-time required the use
#' of `.Internal` calls.
#' But since the use of internal R functions is not permitted for packages
#' distributed on CRAN we downgraded the package to use ordinary environment
#' objects starting with version 0.7.5 until a public interface for the creation
#' of R namespace objects is available.
#'
#' The following gives a list of currently available _DynPorts_:
#'
#' | **DynPort name/C library** | **Description**                                 |
#' |:---------------------------|:------------------------------------------------|
#' | `expat`                    | Expat XML Parser Library                        |
#' | `GL`                       | OpenGL 1.1 API                                  |
#' | `GLU`                      | OpenGL Utility Library                          |
#' | `GLUT`                     | OpenGL Utility Toolkit Library                  |
#' | `SDL`                      | Simple DirectMedia Layer Library                |
#' | `SDL_image`                | Loading of image files (png, jpeg, ...)         |
#' | `SDL_mixer`                | Loading/Playing of ogg/mp3/mod music files.     |
#' | `SDL_ttf`                  | Loading/Rendering of True Type Fonts.           |
#' | `SDL_net`                  | Networking library.                             |
#' | `glew`                     | OpenGL Extension Wrangler (includes OpenGL 3.0) |
#' | `glfw`                     | OpenGL Windowing/Setup Library                  |
#' | `gl3`                      | strict OpenGL 3 (untested)                      |
#' | `R`                        | R shared library                                |
#' | `ode`                      | Open Dynamics (Physics-) Engine (untested)      |
#' | `cuda`                     | NVIDIA Cuda (untested)                          |
#' | `csound`                   | Sound programming language and library          |
#' | `opencl`                   | OpenCL (untested)                               |
#' | `stdio`                    | C Standard Library I/O Functions                |
#' | `glpk`                     | GNU Linear Programming Kit                      |
#' | `EGL`                      | Embedded Systems Graphics Library               |
#'
#' As of the current implementation _DynPort_ files are DCF (Debian Control File)
#' files which follow the same rules for R package `DESCRIPTION` files.
#'
#' The format records the following binding metadata:
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
#' If `portfile` is given, then this value is taken as file path (usually for
#' testing purpose).
#'
#' A tool suite, comprising AWK (was boost wave), GCC Preprocessor, GCC-XML and
#' XSLT, was used to generate the available _DynPort_ files automatically
#' by extracting type information from C library header files.
#'
#' In a future release, the DynPort format will be changed to
#' a language-neutral text file document.
#'
#' @param portname the name of a dynport, given as a literal or character
#'        string. It will be used as the namespace name.
#'
#' @param portfile `NULL` or character string giving a script file to parse.
#'
#' @param repo character string giving the path to the root of the `dynport`
#'        repository.
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
#'   \url{http://www.libsdl.org}
#'
#' Segal, M. and Akeley, K. (1992). The OpenGL Graphics System. A Specification,
#' Version 1.0. \url{http://www.opengl.org}
#'
#' Smith, R. (2001). Open Dynamics Engine. \url{http://www.ode.org}
#'
#' @examples
#' \dontrun{
#' # Using SDL and OpenGL in R
#' dynport(SDL)
#' dynport(GL)
#' # Initialize Video Sub-system
#' SDL_Init(SDL_INIT_VIDEO)
#' # Initialize Screen with OpenGL Context and Double Buffering
#' SDL_SetVideoMode(320, 256, 32, SDL_OPENGL+SDL_DOUBLEBUF)
#' # Clear Color and Clear Screen
#' glClearColor(0, 0, 1, 0) # blue
#' glClear(GL_COLOR_BUFFER_BIT)
#' # Flip Double-Buffer
#' SDL_GL_SwapBuffers()
#' }
#' @aliases loadDynportNamespace
#' @keywords programming interface
#' @author Daniel Adler <dadler@uni-goettingen.de>
#' @export
dynport <- function(portname, portfile = NULL, repo = system.file("dynports", package = "rdyncall")) {
    # literate portname string
    portname <- as.character(substitute(portname))
    if (missing(portfile)) {
        # search for portfile
        portfile <- file.path(repo, paste(portname, ".dynport", sep = ""))
        if (!file.exists(portfile)) stop("dynport '", portname, "' not found.")
    }
    loadDynportNamespace(portname, portfile)
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
    if ("Enum" %in% keys && grepl("^Enum", keys)) {
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
        # error if failed to parse argument types
        if (!is.null(arg) && !length(arg)) {
            type <- attr(arg, "type")
            if (!is.null(type)) {
                issue_error(name, sprintf("Invalid base type name %s found in argument", sQuote(type)))
            } else if (identical(attr(arg, "reason"), "array")) {
                pos <- attr(arg, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Invalid fixed array member %s found in argument", sQuote(str)))
            } else {
                pos <- attr(arg, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Missing '>' in struct member %s found in argument", sQuote(str)))
            }
        }

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
        # error if failed to parse field types
        if (!is.null(ret) && !length(ret)) {
            type <- attr(ret, "type")
            if (!is.null(type)) {
                issue_error(name, sprintf("Invalid base type name %s found in return", sQuote(type)))
            } else if (identical(attr(ret, "reason"), "array")) {
                pos <- attr(ret, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Invalid fixed array member %s found in return", sQuote(str)))
            } else {
                pos <- attr(ret, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Missing '>' in struct member %s found in return", sQuote(str)))
            }
        }

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
            fields <- NULL
        } else {
            # TODO: invalid field names?
            fields <- parse_field_names(tail[[2L]])
            # this is the case when there are extra '}'
            if (!length(fields)) {
                issue_error(name, "Extra '}' in specification")
            }
        }

        # parse field types
        parsed <- dynport_parse_types(kind, tail[[1L]], envir)

        # error if failed to parse field types
        if (!is.null(parsed) && !length(parsed)) {
            type <- attr(parsed, "type")
            if (!is.null(type)) {
                issue_error(name, sprintf("Invalid base type name %s found", sQuote(type)))
            } else if (identical(attr(parsed, "reason"), "array")) {
                pos <- attr(parsed, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Invalid fixed array member %s found", sQuote(str)))
            } else {
                pos <- attr(parsed, "pos")
                str <- substr(sig, pos[1], pos[2])
                issue_error(name, sprintf("Missing '>' in struct member %s found", sQuote(str)))
            }
        }

        # check imbalance between signatures and field names
        if (length(parsed$type) != length(fields)) {
            issue_error(name,
                sprintf("Imbalance number of field types (%s) and names (%s) found",
                    sQuote(length(parsed$type)), sQuote(length(fields))
                )
            )
        }

        lnum <- lnum + lncnt[[i]]

        out[[i]] <- typeinfo(
            name = name, type = kind,
            size = parsed$size, align = parsed$align,
            fields = make_field_info(fields, parsed$type, parsed$offset, parsed$array_len)
        )
    }

    names(out) <- vapply(out, .subset2, "", "name")
    out
}

dynport_parse_types <- function(kind = c("struct", "union"), signature, envir = parent.frame(),
                                allow_arrays = TRUE) {
    parse_aggregate_types(kind, signature, envir = envir, allow_arrays = allow_arrays,
        on_error = "return")
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

loadDynportNamespace <- function(name, portfile, do.attach = TRUE) {
    name <- as.character(name)
    portfile <- as.character(portfile)
    port <- dynport_read(portfile)
    if (do.attach) {
        envname <- paste("dynport", name, sep = ":")
        if (envname %in% search()) {
            return()
        }
        env <- new.env()
        sys.source(portfile, envir = env)

        # directly use base::attach will cause a CRAN check NOTE
        getExportedValue(.BaseNamespaceEnv, "attach")(env, name = envname)
    } else {
        env <- new.env()
        sys.source(portfile, envir = env)
        return(env)
    }
}

makeNamespace <- function(name, version = NULL, lib = NULL) {
    impenv <- new.env(parent = .BaseNamespaceEnv, hash = TRUE)
    attr(impenv, "name") <- paste("imports", name, sep = ":")
    env <- new.env(parent = impenv, hash = TRUE)
    name <- as.character(as.name(name))
    version <- as.character(version)
    info <- new.env(hash = TRUE, parent = baseenv())
    assign(".__NAMESPACE__.", info, envir = env)
    assign("spec", c(name = name, version = version), envir = info)
    setNamespaceInfo(env, "exports", new.env(hash = TRUE, parent = baseenv()))
    dimpenv <- new.env(parent = baseenv(), hash = TRUE)
    attr(dimpenv, "name") <- paste("lazydata", name, sep = ":")
    setNamespaceInfo(env, "lazydata", dimpenv)
    setNamespaceInfo(env, "imports", list(base = TRUE))
    setNamespaceInfo(env, "path", normalizePath(file.path(lib, name), "/", TRUE))
    setNamespaceInfo(env, "dynlibs", NULL)
    setNamespaceInfo(env, "S3methods", matrix(NA_character_, 0L, 3L))
    assign(".__S3MethodsTable__.", new.env(hash = TRUE, parent = baseenv()), envir = env)
    eval(as.call(list(quote(.Internal), quote(registerNamespace(name, env)))))
    env
}

env2namespace <- function(name, version, env, lib = NULL) {
    env <- force(env)
    ns <- makeNamespace(name, version, lib)
    exports <- getNamespaceInfo(ns, "exports")
    objects <- ls(env, all.names = TRUE)
    lapply(objects, function(nm) {
        assign(nm, get(nm, env, inherits = FALSE), ns)
        assign(nm, nm, exports)
    })
}

split_lines <- function(x, trim = TRUE) {
    s <- strsplit(x, "[\r]?\n")[[1L]]
    if (trim) trimws(s) else s
}
