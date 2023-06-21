# Package: rdyncall
# File: R/dynstruct.R
# Description: Handling of aggregate (struct/union) C types

# ----------------------------------------------------------------------------
# dynport basetype sizes

.BASETYPE_SIZES <- c(
    B = .Machine$sizeof.long,
    c = 1,
    C = 1,
    s = 2,
    S = 2,
    i = 4,
    I = 4,
    j = .Machine$sizeof.long,
    J = .Machine$sizeof.long,
    l = .Machine$sizeof.longlong,
    L = .Machine$sizeof.longlong,
    f = 4,
    d = 8,
    p = .Machine$sizeof.pointer,
    x = .Machine$sizeof.pointer,
    Z = .Machine$sizeof.pointer,
    v = 0
)

# ----------------------------------------------------------------------------
# dynport type information
#

typeinfo <- function(name, type = c("base", "pointer", "struct", "union"),
                     size = NA, align = NA, basetype = NA, fields = NA,
                     signature = NA) {
    type <- match.arg(type)
    structure(
        list(
            name = name, type = type, size = size, align = align,
            basetype = basetype, fields = fields, signature = signature
        ),
        class = "typeinfo"
    )
}

is.typeinfo <- function(x) {
    inherits(x, "typeinfo")
}

get_typeinfo <- function(name, envir = parent.frame()) {
    if (is.character(name)) {
        get_typeinfo_by_name(name, envir)
    } else if (is.typeinfo(name)) {
        name
    } else {
        stop("unknown type")
    }
}

get_typeinfo_by_name <- function(type_name, envir = parent.frame()) {
    char1 <- substr(type_name, 1, 1)
    switch(char1,
        "*" = typeinfo(name = type_name, type = "pointer",
            size = .Machine$sizeof.pointer, align = .Machine$sizeof.pointer,
            basetype = substr(type_name, 2, nchar(type_name)),
            signature = type_name
        ),
        "<" = {
            x <- get_typeinfo(substr(type_name, 2, nchar(type_name) - 1), envir = envir)
            if (!is.null(x)) x else typeinfo(name = type_name, type = "struct")
        },
        {
            # try as basetype
            basetype_sizes <- unname(.BASETYPE_SIZES[type_name])
            if (!is.na(basetype_sizes)) {
                typeinfo(name = type_name, type = "base", size = basetype_sizes,
                    align = basetype_sizes, signature = type_name
                )
            } else if (exists(type_name, envir = envir)) {
                # try lookup symbol
                info <- get(type_name, envir = envir)
                if (!inherits(info, "typeinfo")) stop("not a type information symbol")
                info
            } else {
                # otherwise fail
                NULL
            }
        }
    )
}

# ----------------------------------------------------------------------------
# align C offsets

align <- function(offset, alignment) {
    as.integer(as.integer((offset + alignment - 1) / alignment) * alignment)
}

# ----------------------------------------------------------------------------
# field information (structures and unions)

make_field_info <- function(field_names, types, offsets) {
    data.frame(type = I(types), offset = offsets, row.names = field_names)
}

# ----------------------------------------------------------------------------
# parse structure signature

make_struct_info <- function(name, signature, field_names, envir = parent.frame()) {
    # computations:
    types    <- character()
    offsets  <- integer()
    offset   <- 0
    max_align <- 1
    # scan variables:
    n <- nchar(signature)
    i <- 1
    start <- i
    while (i <= n) {
        char <- substr(signature, i, i)
        if (char == "*") {
            i <- i + 1
            next
        } else if (char == "<") {
            i <- i + 1
            while (i < n) {
                if (substr(signature, i, i) == ">") break
                i <- i + 1
            }
        }
        type_name  <- substr(signature, start, i)
        types      <- c(types, type_name)
        type_info  <- get_typeinfo(type_name, envir = envir)
        alignment  <- type_info$align
        max_align  <- max(max_align, alignment)
        offset     <- align(offset, alignment)
        offsets    <- c(offsets, offset)

        # increment offset by size
        offset    <- offset + type_info$size

        # next token
        i <- i + 1
        start <- i
    }
    # align the structure size (compiler-specific?)
    size <- align(offset, max_align)
    # build field information
    fields <- make_field_info(field_names, types, offsets)
    typeinfo(name = name, type = "struct", size = size, align = max_align, fields = fields)
}

cstruct <- function(sigs, envir = parent.frame()) {
    # split functions at ';'
    sigs <- unlist(strsplit(sigs, ";"))
    # split name/struct signature at '('
    sigs <- strsplit(sigs, "[{]")
    for (i in seq(along = sigs)) {
        n <- length(sigs[[i]])
        if (n == 2) {
            # parse structure name
            name <- sigs[[i]][[1]]
            name <- gsub("[ \n\t]*", "", name)
            # split struct signature and field names
            tail <- unlist(strsplit(sigs[[i]][[2]], "[}]"))
            sig <- tail[[1]]
            if (length(tail) == 2) {
                fields <- unlist(strsplit(tail[[2]], "[ \n\t]+"))
            } else {
                fields <- NULL
            }
            assign(name, make_struct_info(name, sig, fields, envir = envir), envir = envir)
        }
    }
}

# ----------------------------------------------------------------------------
# parse union signature

make_union_info <- function(name, signature, field_names, envir = parent.frame()) {
    # computations:
    types <- character()
    max_size <- 0
    max_align <- 1
    # scan variables:
    i <- 1
    start <- i
    n <- nchar(signature)
    while (i <= n) {
        char <- substr(signature, i, i)
        if (char == "*") {
            i <- i + 1
            next
        } else if (char == "<") {
            i <- i + 1
            while (i < n) {
                if (substr(signature, i, i) == ">") break
                i <- i + 1
            }
        }
        type_name  <- substr(signature, start, i)
        types      <- c(types, type_name)
        type_info  <- get_typeinfo(type_name, envir)
        max_size   <- max(max_size, type_info$size)
        max_align  <- max(max_align, type_info$align)
        # next token
        i <- i + 1
        start <- i
    }
    offsets <- rep(0, length(types))
    fields <- make_field_info(field_names, types, offsets)
    typeinfo(name = name, type = "union", fields = fields, size = max_size, align = max_align)
}

cunion <- function(sigs, envir = parent.frame()) {
    # split functions at ';'
    sigs <- unlist(strsplit(sigs, ";"))
    # split name/union signature at '|'
    sigs <- strsplit(sigs, "[|]")
    for (i in seq(along = sigs)) {
        n <- length(sigs[[i]])
        if (n == 2) {
            # parse union name
            name <- sigs[[i]][[1]]
            name <- gsub("[ \n\t]*", "", name)
            # split union signature and field names
            tail <- unlist(strsplit(sigs[[i]][[2]], "[}]"))
            sig <- tail[[1]]
            if (length(tail) == 2) {
                fields <- unlist(strsplit(tail[[2]], "[ \n\t]+"))
            } else {
                fields <- NULL
            }
            assign(name, make_union_info(name, sig, fields, envir = envir), envir = envir)
        }
    }
}

# ----------------------------------------------------------------------------
# raw backed struct's (S3 Class)

as.ctype <- function(x, type) {
    # TODO: check
    if (is.typeinfo(x)) struct_name <- type$name
    attr(x, "ctype") <- type
    class(x) <- "ctype"
    return(x)
}

cdata <- function(type) {
    if (is.character(type)) {
        name <- type
        type <- get_typeinfo(type)
    } else if (is.typeinfo(type)) {
        name <- type$name
    } else {
        stop("type is not of class typeinfo and no character string")
    }
    if (!type$type %in% c("struct", "union")) stop("type must be C struct or union.")
    x <- raw(type$size)
    class(x) <- "struct"
    attr(x, "struct") <- type$name
    return(x)
}

`$.struct` <- unpack.struct <- function(x, index) {
    struct_name <- attr(x, "struct")
    struct_info <- get_typeinfo(struct_name)
    field_info <- struct_info$fields
    offset <- field_info[index, "offset"]
    if (is.na(offset)) stop("unknown field index '", index, "'")
    field_type_name <- as.character(field_info[[index, "type"]])
    field_type_info <- get_typeinfo(field_type_name)
    if (field_type_info$type %in% c("base", "pointer")) {
        unpack(x, offset, field_type_info$signature)
    } else if (!is.null(field_type_info$fields)) {
        if (is.raw(x)) {
            size <- field_type_info$size
            as.ctype(x[(offset + 1):(offset + 1 + size - 1)], field_type_name)
        } else if (is.externalptr(x)) {
            as.ctype(offset_ptr(x, offset), field_type_name)
        }
    } else {
        stop("invalid field type '", field_type_name, "' at field '", index)
    }
}

`$<-.struct` <- pack.struct <- function(x, index, value) {
    struct_name <- attr(x, "struct")
    struct_info <- get_typeinfo(struct_name)
    field_info <- struct_info$fields
    offset <- field_info[index, "offset"]
    if (is.na(offset)) stop("unknown field index '", index, "'")
    field_type_name <- as.character(field_info[index, "type"])
    field_type_info <- get_typeinfo(field_type_name)
    if (field_type_info$type %in% c("base", "pointer")) {
        pack(x, offset, field_type_info$signature, value)
    } else if (!is.null(field_type_info$fields)) {
        # substructure
        size <- field_type_info$size
        x[(offset + 1):(offset + 1 + size - 1)] <- as.raw(value)
    } else {
        stop("invalid field type '", field_type_name, "' at field '", index)
    }
    return(x)
}

print.struct <- function(x, indent = 0, ...) {
    struct_name <- attr(x, "struct")
    struct_info <- get_typeinfo(struct_name)
    field_info <- struct_info$fields
    field_names <- rownames(field_info)

    cat("struct ", struct_name, " ")
    if (typeof(x) == "externalptr") {
        cat("*")
        if (is.nullptr(x)) {
            cat("=NULL\n")
            return()
        }
    }
    cat("{\n")
    # print data without last
    for (i in seq(along = field_names))
    {
        cat(rep("  ", indent + 1), field_names[[i]], ":")
        val <- unpack.struct(x, field_names[[i]])
        if (typeof(val) == "externalptr") val <- "ptr" # .extptr2str(val)
        if (inherits(val, "struct")) {
            print.struct(val, indent = indent + 1)
        } else {
            cat(val, "\n")
        }
    }
    cat(rep("  ", indent), "}\n")
}
