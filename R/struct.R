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

#' S3 class for run-time type information of foreign C data types
#'
#' @description
#' S3 class for run-time type information of foreign C data types.
#'
#' @details
#' Type information objects are created at run-time to describe the concrete
#' layout of foreign C data types on the host machine.
#' While [type signature][type-signature]s give an abstract information on e.g.
#' the field types and names of aggregate structure types, these objects store
#' concrete memory size, alignment and layout information about C data types.
#'
#' @param name character string specifying the type name.
#'
#' @param type character string specifying the type.
#'
#' @param size integer, size of type in bytes.
#'
#' @param align integer, alignment of type in bytes.
#'
#' @param basetype character string, base type of 'pointer' types.
#'
#' @param signature character string specifying the struct/union type
#'        [signature][type-signature].
#'
#' @param envir the environment to look for type object.
#'
#' @param fields data frame with type and offset information that specifies
#'        aggregate struct and union types.
#'
#' @return
#' List object tagged as S3 class `typeinfo` with the following named entries
#' \item{type}{Type name.}
#' \item{size}{Size in bytes.}
#' \item{align}{Alignment in bytes.}
#' \item{fields}{Data frame for field information with the following columns:
#'     \tabular{ll}{
#'         \code{type} \tab type name\cr
#'         \code{offset} \tab byte offset (starts counted from 0)\cr
#'     }
#' }
#'
#' @seealso
#' [cstruct()] for details on the framework for handling foreign C data types.
#'
#' @aliases type-information
#' @rdname typeinfo
#' @export
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

#' @rdname typeinfo
#' @export
get_typeinfo <- function(name, envir = parent.frame()) {
    if (is.character(name)) {
        get_typeinfo_by_name(name, envir)
    } else if (is.typeinfo(name)) {
        name
    } else {
        stop("unknown type")
    }
}

get_typeinfo_by_name <- function(name, envir = parent.frame()) {
    char1 <- substr(name, 1L, 1L)
    switch(char1,
        "*" = typeinfo(name = name, type = "pointer",
            size = .Machine$sizeof.pointer, align = .Machine$sizeof.pointer,
            basetype = substr(name, 2L, nchar(name)),
            signature = name
        ),
        "<" = {
            x <- get_typeinfo(substr(name, 2L, nchar(name) - 1L), envir = envir)
            if (!is.null(x)) x else typeinfo(name = name, type = "struct")
        },
        {
            # try as basetype
            basetype_sizes <- unname(.BASETYPE_SIZES[name])
            if (!is.na(basetype_sizes)) {
                typeinfo(name = name, type = "base", size = basetype_sizes,
                    align = basetype_sizes, signature = name
                )
            } else if (exists(name, envir = envir)) {
                # try lookup symbol
                info <- get(name, envir = envir)
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
    if (is.na(alignment) || alignment <= 0L) return(offset)
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

#' Allocation and handling of foreign C aggregate data types
#'
#' @description
#' Functions for allocation, access and registration of foreign C `struct` and
#' `union` data type.
#'
#' @details
#'
#' References to foreign C data objects are represented by objects of class
#' 'struct'.
#'
#' Two reference types are supported:
#'
#' - _External pointers_ returned by [dyncall()] using a call signature with a
#'   _typed pointer_ return type signature and pointers extracted as a result of
#'   [unpack()] and S3 `struct` `$`-operators.
#' - _Internal objects_, memory-managed by R, are allocated by `cdata()`: An
#'   atomic `raw` storage object is returned, initialized with length equal to
#'   the byte size of the foreign C data type.
#'
#' In order to access and manipulate the data fields of foreign C aggregate data
#' objects, the `$` and `$<-` S3 operator methods can be used.
#'
#' S3 objects of class `struct` have an attribute `struct` set to the name of a
#' [typeinfo] object, which provides the run-time type information of a
#' particular foreign C type.
#'
#' The run-time type information for foreign C `struct` and `union` types need
#' to be registered once via `cstruct` and `cunion` functions.
#' The C data types are specified by `sigs`, a signature character string.
#' The formats for both types are described next:
#'
#' **Structure type signatures** describe the layout of aggregate `struct` C
#' data types.
#' Type Signatures are used within the `field-types`.
#' `field-names` consists of space separated identifier names and should match
#' the number of fields.
#'
#' ```
#' struct-name { field-types } field-names ;
#' ```
#' Here is an example of a C `struct` type:
#'
#' ```
#' struct Rect {
#'   signed short x, y;
#'   unsigned short w, h;
#' };
#' ```
#'
#' The corresponding structure type signature string is:
#' ```
#' "Rect{ssSS}x y w h;"
#' ```
#'
#' **Union type signatures** describe the components of the `union` C
#' data type.
#' Type signatures are used within the `field-types`.
#' `field-names` consists of space separated identifier names and should match
#' the number of fields.
#'
#' ```
#' union-name | field-types } field-names ;
#' ```
#'
#' Here is an example of a C \code{union} type:
#'
#' ```
#' union Value {
#'   int anInt;
#'   float aFloat;
#'   struct LongValue aStruct
#' };
#' ```
#'
#' The corresponding union type signature string is:
#'
#' ```
#' "Value|if<LongValue>}anInt aFloat aStruct;"
#' ```
#'
#' [as.ctype()] can be used to _cast_ a foreign C data reference to a different
#' type.
#' When using an external pointer reference, this can lead quickly to a
#' **fatal R process crash** - like in C.
#'
#' @param x external pointer or atomic raw vector of S3 class 'struct'.
#'
#' @param type S3 [typeinfo()] Object or character string that names the
#'        structure type.
#'
#' @param sigs character string that specifies several C struct/union type
#'        `signature`s.
#'
#' @param envir the environment to install S3 type information object(s).
#'
#' @param index character string specifying the field name.
#'
#' @param indent indentation level for pretty printing structures.
#'
#' @param value value to be converted according to struct/union field type given
#'        by field index.
#' @param ... additional arguments to be passed to [base::print()] method.
#'
#' @seealso
#' [dyncall()] for type signatures and [typeinfo()] for details on run-time type
#' information S3 objects.
#' @examples
#' # Specify the following foreign type:
#' # struct Rect {
#' #     short x, y;
#' #     unsigned short w, h;
#' # }
#' cstruct("Rect{ssSS}x y w h;")
#' r <- cdata(Rect)
#' print(r)
#' r$x <- 40
#' r$y <- 60
#' r$w <- 10
#' r$h <- 15
#' print(r)
#' str(r)
#' @keywords programming interface
#' @rdname struct
#' @export
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

#' @rdname struct
#' @export
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

#' @rdname struct
#' @export
as.ctype <- function(x, type) {
    # TODO: check
    if (is.typeinfo(x)) struct_name <- type$name
    attr(x, "ctype") <- type
    class(x) <- "ctype"
    return(x)
}

#' @rdname struct
#' @export
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

#' @rdname struct
#' @export
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

#' @rdname struct
#' @export
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

#' @rdname struct
#' @export
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
