# Package: rdyncall
# File: demo/libxml2.R
# Description: XML parsing via direct libxml2 calls.

library(rdyncall)

# Bind libxml2's streaming reader API. The demo reads text nodes from a small
# in-memory XML document without using the R `xml2` package.
xml <- new.env(parent = globalenv())
xml_info <- dynbind(
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

if (length(xml_info$unresolved.symbols)) {
    stop("unresolved libxml2 symbols: ", paste(xml_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(xml_info)

# libxml2 node type value for ordinary text.
XML_READER_TYPE_TEXT <- 3L
# libxml2 node type value for CDATA text.
XML_READER_TYPE_CDATA <- 4L

xml_text <- "<root><message>rdyncall libxml2 demo</message></root>"
expected <- "rdyncall libxml2 demo"

# Parse an XML string with `xmlReaderForMemory()` and concatenate text-like
# nodes returned by the pull reader.
libxml2_text <- function(text) {
    # The second argument is the byte length, not the number of R characters.
    reader <- xml$xmlReaderForMemory(text, nchar(text, type = "bytes"), "memory.xml", NULL, 0L)
    if (is.null(reader) || is.nullptr(reader)) {
        stop("xmlReaderForMemory failed", call. = FALSE)
    }
    on.exit(xml$xmlFreeTextReader(reader), add = TRUE)

    values <- character()
    repeat {
        # Return values: 1 means a node was read, 0 is EOF, negative is error.
        status <- xml$xmlTextReaderRead(reader)
        if (status == 0L) {
            break
        }
        if (status < 0L) {
            stop("xmlTextReaderRead failed", call. = FALSE)
        }
        node_type <- xml$xmlTextReaderNodeType(reader)
        # `xmlTextReaderConstValue()` returns a borrowed const xmlChar*.
        if (node_type %in% c(XML_READER_TYPE_TEXT, XML_READER_TYPE_CDATA)) {
            values <- c(values, xml$xmlTextReaderConstValue(reader))
        }
    }

    paste(values, collapse = "")
}

# Run the libxml2 parse and verify the text result.
run_libxml2_demo <- function() {
    on.exit(xml$xmlCleanupParser(), add = TRUE)

    via_libxml2 <- libxml2_text(xml_text)
    cat("libxml2: ", via_libxml2, "\n", sep = "")
    stopifnot(identical(expected, via_libxml2))
}

run_libxml2_demo()
