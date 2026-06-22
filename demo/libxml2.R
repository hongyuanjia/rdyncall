# Package: rdyncall
# File: demo/libxml2.R
# Description: XML parsing via direct libxml2 calls, compared with xml2 when available.

load_rdyncall <- function() {
    if ("package:rdyncall" %in% search()) {
        return(invisible(TRUE))
    }
    lib.loc <- Sys.getenv("RDYNCALL_LIB", unset = "")
    if (nzchar(lib.loc)) {
        return(library("rdyncall", lib.loc = lib.loc, character.only = TRUE))
    }
    file <- ""
    for (frame in rev(sys.frames())) {
        if (!is.null(frame$ofile)) {
            file <- normalizePath(frame$ofile, mustWork = FALSE)
            break
        }
    }
    if (nzchar(file)) {
        lib.loc <- dirname(dirname(dirname(file)))
        if (file.exists(file.path(lib.loc, "rdyncall"))) {
            return(library("rdyncall", lib.loc = lib.loc, character.only = TRUE))
        }
    }
    library("rdyncall", character.only = TRUE)
}

load_rdyncall()

xml <- new.env(parent = globalenv())
dynbind(
    c("xml2", "xml2-2", "libxml2-2", "libxml2"),
    paste(
        "xmlReaderForMemory(ZiZZi)p",
        "xmlTextReaderRead(p)i",
        "xmlTextReaderNodeType(p)i",
        "xmlTextReaderConstValue(p)Z",
        "xmlFreeTextReader(p)v",
        "xmlCleanupParser()v",
        sep = ";"
    ),
    envir = xml
)

XML_READER_TYPE_TEXT <- 3L
XML_READER_TYPE_CDATA <- 4L

xml_text <- "<root><message>rdyncall libxml2 demo</message></root>"
expected <- "rdyncall libxml2 demo"

libxml2_text <- function(text) {
    reader <- xml$xmlReaderForMemory(text, nchar(text, type = "bytes"), "memory.xml", NULL, 0L)
    if (is.null(reader) || is.nullptr(reader)) {
        stop("xmlReaderForMemory failed", call. = FALSE)
    }
    on.exit(xml$xmlFreeTextReader(reader), add = TRUE)

    values <- character()
    repeat {
        status <- xml$xmlTextReaderRead(reader)
        if (status == 0L) {
            break
        }
        if (status < 0L) {
            stop("xmlTextReaderRead failed", call. = FALSE)
        }
        node_type <- xml$xmlTextReaderNodeType(reader)
        if (node_type %in% c(XML_READER_TYPE_TEXT, XML_READER_TYPE_CDATA)) {
            values <- c(values, xml$xmlTextReaderConstValue(reader))
        }
    }

    paste(values, collapse = "")
}

run_libxml2_demo <- function() {
    on.exit(xml$xmlCleanupParser(), add = TRUE)

    via_libxml2 <- libxml2_text(xml_text)
    cat("libxml2: ", via_libxml2, "\n", sep = "")
    stopifnot(identical(expected, via_libxml2))

    if (requireNamespace("xml2", quietly = TRUE)) {
        via_xml2 <- xml2::xml_text(xml2::read_xml(xml_text))
        cat("xml2:    ", via_xml2, "\n", sep = "")
        stopifnot(identical(expected, via_xml2))
    } else {
        cat("xml2 package not installed; comparison skipped.\n")
    }
}

run_libxml2_demo()
