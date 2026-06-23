#!/usr/bin/env Rscript

script_root <- function() {
    cmd <- commandArgs(FALSE)
    file_arg <- grep("^--file=", cmd, value = TRUE)
    if (length(file_arg)) {
        script <- normalizePath(sub("^--file=", "", file_arg[[1L]]), mustWork = TRUE)
        normalizePath(file.path(dirname(script), "..", ".."), mustWork = TRUE)
    } else {
        normalizePath(".", mustWork = TRUE)
    }
}

parse_args <- function(args) {
    out <- list(
        include = NULL,
        version = NULL,
        output = NULL,
        snapshot = NULL,
        intersect_with = NULL,
        help = FALSE
    )

    for (arg in args) {
        if (arg %in% c("-h", "--help")) {
            out$help <- TRUE
            next
        }
        if (!startsWith(arg, "--") || !grepl("=", arg, fixed = TRUE)) {
            stop("Unsupported argument: ", arg, call. = FALSE)
        }
        key <- sub("^--", "", sub("=.*$", "", arg))
        key <- gsub("-", "_", key, fixed = TRUE)
        val <- sub("^[^=]*=", "", arg)
        if (!key %in% names(out)) {
            stop("Unknown option: --", gsub("_", "-", key, fixed = TRUE), call. = FALSE)
        }
        out[[key]] <- val
    }

    out
}

usage <- function() {
    cat(
        "Usage: Rscript tools/dynports/generate-R.R [options]\n",
        "\n",
        "Options:\n",
        "  --include=DIR          R include directory. Defaults to R.home('include').\n",
        "  --version=VERSION      Version stored in the dynport. Defaults to detected R version.\n",
        "  --output=FILE          Output dynport path. Defaults to inst/dynports/R.dynport.\n",
        "  --snapshot=FILE        Optional unfiltered dynport snapshot path.\n",
        "  --intersect-with=FILE  Keep only entries also present in another dynport file.\n",
        sep = ""
    )
}

root <- script_root()
args <- parse_args(commandArgs(TRUE))
if (isTRUE(args$help)) {
    usage()
    quit(save = "no")
}

porter_repo <- Sys.getenv("PORTER_REPO", unset = "")
if (nzchar(porter_repo)) {
    porter_repo <- normalizePath(porter_repo, mustWork = TRUE)
    if (!requireNamespace("pkgload", quietly = TRUE)) {
        stop("Package 'pkgload' is required when PORTER_REPO is set.", call. = FALSE)
    }
    pkgload::load_all(porter_repo, quiet = TRUE)
} else if (!requireNamespace("porter", quietly = TRUE)) {
    sibling <- normalizePath(file.path(root, "..", "porter"), mustWork = FALSE)
    if (dir.exists(sibling) && requireNamespace("pkgload", quietly = TRUE)) {
        pkgload::load_all(sibling, quiet = TRUE)
    }
}
if (!"porter" %in% loadedNamespaces()) {
    stop("Package 'porter' is required to generate R.dynport.", call. = FALSE)
}

detect_r_version <- function(include) {
    rversion <- file.path(include, "Rversion.h")
    if (!file.exists(rversion)) return(as.character(getRversion()))

    lines <- readLines(rversion, warn = FALSE)
    get_define <- function(name) {
        pat <- paste0('^#define[[:space:]]+', name, '[[:space:]]+"([^"]+)".*$')
        hit <- grep(pat, lines, value = TRUE)
        if (!length(hit)) return(NA_character_)
        sub(pat, "\\1", hit[[1L]])
    }
    major <- get_define("R_MAJOR")
    minor <- get_define("R_MINOR")
    if (is.na(major) || is.na(minor)) as.character(getRversion()) else paste(major, minor, sep = ".")
}

read_dynport_values <- function(file) {
    lines <- readLines(file, warn = FALSE)

    con <- textConnection(lines, local = TRUE)
    keys <- colnames(read.dcf(con))
    close(con)

    con <- textConnection(lines, local = TRUE)
    dcf <- read.dcf(con, keep.white = keys)
    close(con)

    values <- as.list(dcf[1L, ])
    names(values) <- keys
    lapply(values, function(value) {
        if (is.na(value)) return(character())
        if (substr(value, 1L, 1L) == "\n") value <- substr(value, 2L, nchar(value))
        value <- trimws(strsplit(value, "\n", fixed = TRUE)[[1L]])
        value[nzchar(value)]
    })
}

field_count <- function(port, field) {
    value <- port[[field]]$value
    if (is.null(value)) 0L else nrow(value)
}

intersect_simple_field <- function(port, reference, field) {
    value <- port[[field]]$value
    if (is.null(value) || !nrow(value)) return(port)

    raw <- format(port[[field]], raw = TRUE)
    keep <- raw %in% reference[[field]]
    args <- list(value[keep, , drop = FALSE])
    names(args) <- field
    do.call(porter::port_set, c(list(port), args))
}

intersect_enum_field <- function(port, reference) {
    value <- port$Enum$value
    if (is.null(value) || !nrow(value)) return(port)

    raw <- format(port$Enum, raw = TRUE)
    keep <- vapply(seq_len(nrow(value)), function(i) {
        name <- value$name[[i]]
        ref <- reference[[paste0("Enum/", name)]]
        if (is.null(ref) && !is.null(reference$Enum) && nrow(value) == 1L) {
            ref <- reference$Enum
        }
        !is.null(ref) && identical(unname(raw[[name]]), unname(ref))
    }, logical(1))

    porter::port_set(port, Enum = value[keep, , drop = FALSE])
}

defined_type_names <- function(port) {
    fields <- c("Enum", "Struct", "Union")
    unique(unlist(lapply(fields, function(field) {
        value <- port[[field]]$value
        if (is.null(value) || !nrow(value)) character() else value$name
    }), use.names = FALSE))
}

value_type_refs <- function(sig) {
    # Pointer references are safe as opaque pointers even when the pointed-to
    # type definition did not survive the version intersection.
    sig <- gsub("\\*+<[^>]+>", "", sig, perl = TRUE)
    refs <- regmatches(sig, gregexpr("<[^>]+>", sig, perl = TRUE))[[1L]]
    if (!length(refs) || identical(refs, character(0))) return(character())
    unique(sub("^<(.+)>$", "\\1", refs))
}

intersect_type_field_dependencies <- function(port, field, defined) {
    value <- port[[field]]$value
    if (is.null(value) || !nrow(value)) return(port)

    raw <- format(port[[field]], raw = TRUE)
    keep <- vapply(raw, function(sig) {
        !length(setdiff(value_type_refs(sig), defined))
    }, logical(1))
    args <- list(value[keep, , drop = FALSE])
    names(args) <- field
    do.call(porter::port_set, c(list(port), args))
}

intersect_signature_dependencies <- function(port) {
    before <- vapply(
        c("Function", "Variadic", "FuncPtr", "Enum", "Struct", "Union"),
        field_count, integer(1), port = port
    )

    repeat {
        defined <- defined_type_names(port)
        counts <- vapply(c("Struct", "Union"), field_count, integer(1), port = port)
        port <- intersect_type_field_dependencies(port, "Struct", defined)
        port <- intersect_type_field_dependencies(port, "Union", defined)
        next_counts <- vapply(c("Struct", "Union"), field_count, integer(1), port = port)
        if (identical(counts, next_counts)) break
    }

    defined <- defined_type_names(port)
    for (field in c("Function", "Variadic", "FuncPtr")) {
        port <- intersect_type_field_dependencies(port, field, defined)
    }

    after <- vapply(
        c("Function", "Variadic", "FuncPtr", "Enum", "Struct", "Union"),
        field_count, integer(1), port = port
    )
    if (!identical(before, after)) {
        message("Dependency closure for by-value named types:")
        for (field in names(before)) {
            if (before[[field]] != after[[field]]) {
                message("  ", field, ": ", before[[field]], " -> ", after[[field]])
            }
        }
    }

    port
}

intersect_port <- function(port, reference_file) {
    reference <- read_dynport_values(reference_file)
    before <- vapply(
        c("Function", "Variadic", "FuncPtr", "Enum", "Struct", "Union"),
        field_count, integer(1), port = port
    )

    for (field in c("Function", "Variadic", "FuncPtr", "Struct", "Union")) {
        port <- intersect_simple_field(port, reference, field)
    }
    port <- intersect_enum_field(port, reference)
    port <- intersect_signature_dependencies(port)

    after <- vapply(
        c("Function", "Variadic", "FuncPtr", "Enum", "Struct", "Union"),
        field_count, integer(1), port = port
    )
    message("Intersection against ", reference_file, ":")
    for (field in names(before)) {
        message("  ", field, ": ", before[[field]], " -> ", after[[field]])
    }

    port
}

generate_port <- function(include, version) {
    headers <- file.path(include, c("R.h", "Rinternals.h"))
    missing <- headers[!file.exists(headers)]
    if (length(missing)) {
        stop("Cannot find R header(s): ", paste(missing, collapse = ", "), call. = FALSE)
    }

    header <- tempfile("rdyncall-R-", fileext = ".h")
    writeLines(c("#include <R.h>", "#include <Rinternals.h>"), header)
    on.exit(unlink(header), add = TRUE)

    cflags <- paste0("-I", include)
    porter::port_set(
        porter::port(header, limit = include, cflags = cflags),
        Package = "R",
        Version = version,
        Library = "R"
    )
}

trim_trailing_ws <- function(file) {
    lines <- readLines(file, warn = FALSE)
    writeLines(sub("[ \t]+$", "", lines, perl = TRUE), file, useBytes = TRUE)
}

include <- if (is.null(args$include)) file.path(R.home(), "include") else args$include
include <- normalizePath(include, mustWork = TRUE)
version <- if (is.null(args$version)) detect_r_version(include) else args$version
outfile <- if (is.null(args$output)) {
    file.path(root, "inst", "dynports", "R.dynport")
} else {
    args$output
}
outfile <- normalizePath(dirname(outfile), mustWork = TRUE)
outfile <- file.path(outfile, if (is.null(args$output)) "R.dynport" else basename(args$output))

port <- generate_port(include, version)

if (!is.null(args$snapshot)) {
    snapshot <- normalizePath(dirname(args$snapshot), mustWork = TRUE)
    snapshot <- file.path(snapshot, basename(args$snapshot))
    suppressWarnings(porter::port_write(port, snapshot))
    trim_trailing_ws(snapshot)
    message("Wrote unfiltered snapshot ", snapshot)
}

if (!is.null(args$intersect_with)) {
    port <- intersect_port(port, normalizePath(args$intersect_with, mustWork = TRUE))
}

suppressWarnings(porter::port_write(port, outfile))
trim_trailing_ws(outfile)

report <- porter::port_report(port)
message("Wrote ", outfile)
message("Version: ", version)
if (nrow(report)) {
    message(
        "porter recorded ", nrow(report), " diagnostic item",
        if (nrow(report) == 1L) "" else "s",
        "; inspect with porter::port_report()."
    )
}
