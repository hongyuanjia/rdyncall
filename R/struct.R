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

.BITFIELD_TYPES <- c("B", "c", "C", "s", "S", "i", "I", "j", "J", "l", "L")

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
#' @param fields data frame with name, type, offset and optional array or
#'        bitfield layout information that specifies aggregate struct and union
#'        types.
#'
#' @param x S3 `typeinfo` object to print.
#'
#' @param ... additional arguments to be passed to [base::print()] methods.
#'
#' @return
#' List object tagged as S3 class `typeinfo` with the following named entries
#' \item{type}{Type name.}
#' \item{size}{Size in bytes.}
#' \item{align}{Alignment in bytes.}
#' \item{fields}{Data frame for field information with the following columns:
#'     \tabular{ll}{
#'         \code{name} \tab field name\cr
#'         \code{type} \tab type name\cr
#'         \code{offset} \tab byte offset (starts counted from 0)\cr
#'         \code{array_len} \tab fixed array length, or 1 for scalar fields\cr
#'         \code{bit_offset} \tab bitfield offset, or \code{NA} for ordinary fields\cr
#'         \code{bit_width} \tab bitfield width, or \code{NA} for ordinary fields\cr
#'         \code{storage_offset} \tab bitfield storage-unit byte offset\cr
#'         \code{storage_size} \tab bitfield storage-unit size in bytes\cr
#'     }
#' }
#'
#' @seealso
#' [cstruct()] for details on the framework for handling foreign C data types.
#'
#' @aliases type-information
#' @rdname typeinfo
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

#' @rdname typeinfo
#' @export
print.typeinfo <- function(x, ...) {
    typeinfo_value <- function(value) {
        if (length(value) == 0L || all(is.na(value))) "<unknown>" else as.character(value)
    }

    cat(x$type, " typeinfo ", x$name, "\n", sep = "")
    cat("  size: ", typeinfo_value(x$size), "\n", sep = "")
    cat("  align: ", typeinfo_value(x$align), "\n", sep = "")
    if (!all(is.na(x$signature))) {
        cat("  signature: ", x$signature, "\n", sep = "")
    }
    if (identical(x$type, "pointer") && !all(is.na(x$basetype))) {
        cat("  basetype: ", x$basetype, "\n", sep = "")
    }

    if (is.data.frame(x$fields)) {
        cat("  fields:\n")
        if (!nrow(x$fields)) {
            cat("    <none>\n")
        } else {
            fields <- x$fields
            fields$type <- as.character(fields$type)
            base_cols <- c("name", "type", "offset", "array_len")
            bit_cols <- c("bit_offset", "bit_width", "storage_offset", "storage_size")
            cols <- base_cols[base_cols %in% names(fields)]
            if ("bit_width" %in% names(fields) && any(!is.na(fields$bit_width))) {
                cols <- c(cols, bit_cols[bit_cols %in% names(fields)])
            }
            print(fields[cols], row.names = FALSE)
        }
    }

    invisible(x)
}

is.typeinfo <- function(x) {
    inherits(x, "typeinfo")
}

#' @rdname typeinfo
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

align_bits <- function(offset, alignment) {
    if (is.na(alignment) || alignment <= 0L) return(offset)
    as.integer(as.integer((offset + alignment - 1L) / alignment) * alignment)
}

bits_to_bytes <- function(bits) {
    as.integer(as.integer((bits + 7L) / 8L))
}

# ----------------------------------------------------------------------------
# field information (structures and unions)

make_field_info <- function(field_names, types, offsets,
                            array_len = rep.int(1L, length(types)),
                            bit_offsets = NULL, bit_widths = NULL,
                            storage_offsets = NULL, storage_sizes = NULL) {
    if (is.null(field_names)) field_names <- character()
    if (is.null(types)) types <- character()
    if (is.null(offsets)) offsets <- integer()
    if (length(types) != length(field_names)) {
        stop("number of field types and names does not match")
    }
    n <- length(types)
    if (is.null(bit_offsets)) bit_offsets <- rep(NA_integer_, n)
    if (is.null(bit_widths)) bit_widths <- rep(NA_integer_, n)
    if (is.null(storage_offsets)) storage_offsets <- rep(NA_integer_, n)
    if (is.null(storage_sizes)) storage_sizes <- rep(NA_integer_, n)
    data.frame(
        name = field_names,
        type = I(types),
        offset = offsets,
        array_len = array_len,
        bit_offset = bit_offsets,
        bit_width = bit_widths,
        storage_offset = storage_offsets,
        storage_size = storage_sizes,
        stringsAsFactors = FALSE
    )
}

parse_field_names <- function(x) {
    x <- trimws(x)
    if (!nzchar(x)) return(NULL)
    strsplit(x, "[ \n\t]+")[[1L]]
}

new_field_specs <- function(names = character(), bit_widths = rep(NA_integer_, length(names))) {
    data.frame(
        name = as.character(names),
        bit_width = as.integer(bit_widths),
        stringsAsFactors = FALSE
    )
}

empty_field_specs <- function() {
    new_field_specs()
}

parse_field_specs <- function(field_names) {
    if (is.null(field_names)) field_names <- character()

    if (is.data.frame(field_names)) {
        if (!all(c("name", "bit_width") %in% names(field_names))) {
            stop("invalid field specification table", call. = FALSE)
        }
        fields <- new_field_specs(field_names$name, field_names$bit_width)
        if (any(!is.na(fields$bit_width) & fields$bit_width == 0L & nzchar(fields$name))) {
            stop("zero-width bitfield must be unnamed", call. = FALSE)
        }
        return(fields)
    }

    names <- character(length(field_names))
    bit_widths <- rep(NA_integer_, length(field_names))

    for (i in seq_along(field_names)) {
        field <- field_names[[i]]
        if (!grepl(":", field, fixed = TRUE)) {
            names[[i]] <- field
            next
        }

        parts <- strsplit(field, ":", fixed = TRUE)[[1L]]
        if (length(parts) != 2L) {
            stop("invalid bitfield specification '", field, "'", call. = FALSE)
        }
        width <- suppressWarnings(as.integer(parts[[2L]]))
        if (is.na(width) || !identical(as.character(width), parts[[2L]]) || width < 0L) {
            stop("invalid bitfield width in field '", field, "'", call. = FALSE)
        }
        if (width == 0L && nzchar(parts[[1L]])) {
            stop("zero-width bitfield must be unnamed", call. = FALSE)
        }

        names[[i]] <- parts[[1L]]
        bit_widths[[i]] <- width
    }

    new_field_specs(names, bit_widths)
}

aggregate_layout <- function(pack = NA_integer_, align = NA_integer_) {
    list(pack = pack, align = align)
}

is_power_of_two <- function(x) {
    if (length(x) != 1L || is.na(x) || x < 1L) return(FALSE)
    while (x %% 2L == 0L) x <- x %/% 2L
    x == 1L
}

parse_aggregate_layout_value <- function(value, directive) {
    if (!grepl("^[0-9]+$", value)) {
        stop("invalid aggregate layout directive '", directive, "'", call. = FALSE)
    }
    value <- suppressWarnings(as.integer(value))
    if (!is_power_of_two(value)) {
        stop("aggregate layout directive '", directive,
            "' must use a positive power-of-two integer", call. = FALSE)
    }
    value
}

parse_aggregate_layout_directive <- function(token, layout) {
    if (identical(token, "@packed")) {
        if (!is.na(layout$pack)) {
            stop("duplicate aggregate layout directive '@pack'", call. = FALSE)
        }
        layout$pack <- 1L
        return(layout)
    }

    pack <- regexec("^@pack\\(([0-9]+)\\)$", token)
    match <- regmatches(token, pack)[[1L]]
    if (length(match)) {
        if (!is.na(layout$pack)) {
            stop("duplicate aggregate layout directive '@pack'", call. = FALSE)
        }
        layout$pack <- parse_aggregate_layout_value(match[[2L]], token)
        return(layout)
    }

    align <- regexec("^@align\\(([0-9]+)\\)$", token)
    match <- regmatches(token, align)[[1L]]
    if (length(match)) {
        if (!is.na(layout$align)) {
            stop("duplicate aggregate layout directive '@align'", call. = FALSE)
        }
        layout$align <- parse_aggregate_layout_value(match[[2L]], token)
        return(layout)
    }

    stop("unknown aggregate layout directive '", token, "'", call. = FALSE)
}

parse_aggregate_fields <- function(x) {
    x <- trimws(x)
    layout <- aggregate_layout()
    if (!nzchar(x)) return(list(fields = empty_field_specs(), layout = layout))

    tokens <- scan_field_tail(x)
    if (!isTRUE(tokens$ok)) {
        token <- substr(x, tokens$error_start, tokens$error_end)
        if (identical(tokens$error_reason, "bitfield_spec")) {
            stop("invalid bitfield specification '", token, "'", call. = FALSE)
        }
        stop("invalid bitfield width in field '", token, "'", call. = FALSE)
    }

    for (directive in tokens$directive) {
        layout <- parse_aggregate_layout_directive(directive, layout)
    }

    list(fields = new_field_specs(tokens$field_name, tokens$bit_width), layout = layout)
}

aggregate_member_alignment <- function(alignment, layout) {
    if (!is.na(layout$pack)) min(alignment, layout$pack) else alignment
}

aggregate_final_alignment <- function(alignment, layout) {
    if (!is.na(layout$align)) max(alignment, layout$align) else alignment
}

parse_type_error <- function(pos, type = NULL, reason = NULL) {
    res <- list()
    attr(res, "pos") <- pos
    if (!is.null(type)) attr(res, "type") <- type
    if (!is.null(reason)) attr(res, "reason") <- reason
    res
}

scan_signature_tokens <- function(signature) {
    .Call("C_scan_signature_tokens", signature, PACKAGE = "rdyncall")
}

scan_field_tail <- function(tail) {
    .Call("C_scan_field_tail", tail, PACKAGE = "rdyncall")
}

parse_aggregate_types <- function(kind = c("struct", "union"), signature,
                                  envir = parent.frame(), allow_arrays = TRUE,
                                  layout = aggregate_layout(),
                                  on_error = c("stop", "return")) {
    kind <- match.arg(kind)
    on_error <- match.arg(on_error)
    signature <- trimws(signature)

    fail <- function(pos, type = NULL, reason = NULL) {
        if (on_error == "return") {
            return(parse_type_error(pos, type = type, reason = reason))
        }
        if (!is.null(type)) {
            stop("invalid base type name ", sQuote(type), call. = FALSE)
        }
        if (identical(reason, "array")) {
            stop("invalid array length in type signature", call. = FALSE)
        }
        stop("missing '>' in struct member", call. = FALSE)
    }

    types <- character()
    array_lens <- integer()
    max_size <- 0L
    max_align <- 1L

    if (kind == "struct") {
        offset <- 0L
        offsets <- integer()
    }

    n <- nchar(signature)
    if (n == 0L) {
        max_align <- aggregate_final_alignment(max_align, layout)
        return(list(
            size = align(0L, max_align), align = max_align, type = character(),
            offset = integer(), array_len = integer()
        ))
    }

    tokens <- scan_signature_tokens(signature)
    if (!isTRUE(tokens$ok)) {
        return(fail(
            c(tokens$error_start, tokens$error_end),
            reason = tokens$error_reason
        ))
    }

    for (i in seq_along(tokens$type)) {
        type <- tokens$type[[i]]
        array_len <- tokens$array_len[[i]]
        start <- tokens$start[[i]]
        end <- tokens$end[[i]]

        if (!allow_arrays && array_len != 1L) {
            return(fail(c(start, end), reason = "array"))
        }

        info <- get_typeinfo(type, envir = envir)
        if (is.null(info)) {
            return(fail(c(start, end), type = type))
        }

        types <- c(types, type)
        array_lens <- c(array_lens, array_len)
        field_size <- info$size * array_len

        if (kind == "struct") {
            alignment <- aggregate_member_alignment(info$align, layout)
            max_align <- max(max_align, alignment)
            offset <- align(offset, alignment)
            offsets <- c(offsets, offset)
            offset <- offset + field_size
        } else {
            max_align <- max(max_align, aggregate_member_alignment(info$align, layout))
            max_size <- max(max_size, field_size)
        }
    }

    if (kind == "struct") {
        max_align <- aggregate_final_alignment(max_align, layout)
        size <- align(offset, max_align)
    } else {
        max_align <- aggregate_final_alignment(max_align, layout)
        size <- align(max_size, max_align)
        offsets <- rep(0L, length(types))
    }

    list(size = size, align = max_align, type = types, offset = offsets, array_len = array_lens)
}

validate_bitfield_type <- function(type, width, info) {
    if (!type %in% .BITFIELD_TYPES) {
        stop("bitfield type '", type, "' is not an integer type", call. = FALSE)
    }
    type_bits <- as.integer(info$size * 8L)
    if (width > type_bits) {
        stop("bitfield width ", width, " exceeds width of type '", type, "'", call. = FALSE)
    }
    if (type == "B" && width > 1L) {
        stop("bool bitfield width must not exceed 1", call. = FALSE)
    }
}

make_aggregate_info <- function(name, kind = c("struct", "union"), signature,
                                field_names, envir = parent.frame(),
                                layout = aggregate_layout()) {
    kind <- match.arg(kind)
    parsed <- parse_aggregate_types(kind, signature, envir = envir, layout = layout)
    fields <- parse_field_specs(field_names)
    if (length(parsed$type) != nrow(fields)) {
        stop("number of field types and names does not match", call. = FALSE)
    }

    if (!any(!is.na(fields$bit_width))) {
        field_info <- make_field_info(
            fields$name, parsed$type, parsed$offset, parsed$array_len
        )
        return(typeinfo(
            name = name, type = kind, size = parsed$size, align = parsed$align,
            fields = field_info, signature = signature
        ))
    }

    types <- parsed$type
    array_lens <- parsed$array_len
    offsets <- integer(length(types))
    bit_offsets <- rep(NA_integer_, length(types))
    bit_widths <- fields$bit_width
    storage_offsets <- rep(NA_integer_, length(types))
    storage_sizes <- rep(NA_integer_, length(types))

    max_align <- 1L
    max_size <- 0L
    bitpos <- 0L

    for (i in seq_along(types)) {
        type <- types[[i]]
        info <- get_typeinfo(type, envir = envir)
        width <- bit_widths[[i]]
        member_align <- aggregate_member_alignment(info$align, layout)

        if (is.na(width)) {
            field_size <- info$size * array_lens[[i]]
            max_align <- max(max_align, member_align)
            if (kind == "struct") {
                offset <- align(bits_to_bytes(bitpos), member_align)
                offsets[[i]] <- offset
                bitpos <- as.integer((offset + field_size) * 8L)
            } else {
                offsets[[i]] <- 0L
                max_size <- max(max_size, field_size)
            }
            next
        }

        if (array_lens[[i]] != 1L) {
            stop("fixed array field cannot be a bitfield", call. = FALSE)
        }
        validate_bitfield_type(type, width, info)
        max_align <- max(max_align, member_align)
        unit_bits <- as.integer(info$size * 8L)

        if (width == 0L) {
            if (kind == "struct") {
                bitpos <- align_bits(bitpos, unit_bits)
                offsets[[i]] <- bits_to_bytes(bitpos)
            } else {
                offsets[[i]] <- 0L
            }
            next
        }

        if (kind == "struct") {
            if ((bitpos %% unit_bits) + width > unit_bits) {
                bitpos <- align_bits(bitpos, unit_bits)
            }
            bit_offsets[[i]] <- bitpos
            offsets[[i]] <- bitpos %/% 8L
            storage_offsets[[i]] <- (bitpos %/% unit_bits) * info$size
            storage_sizes[[i]] <- info$size
            bitpos <- bitpos + width
        } else {
            bit_offsets[[i]] <- 0L
            offsets[[i]] <- 0L
            storage_offsets[[i]] <- 0L
            storage_sizes[[i]] <- info$size
            max_size <- max(max_size, info$size)
        }
    }

    max_align <- aggregate_final_alignment(max_align, layout)
    size <- if (kind == "struct") {
        align(bits_to_bytes(bitpos), max_align)
    } else {
        align(max_size, max_align)
    }

    field_info <- make_field_info(
        fields$name, types, offsets,
        array_len = array_lens,
        bit_offsets = bit_offsets,
        bit_widths = bit_widths,
        storage_offsets = storage_offsets,
        storage_sizes = storage_sizes
    )
    typeinfo(
        name = name, type = kind, size = size, align = max_align,
        fields = field_info, signature = signature
    )
}

is_bitfield <- function(field_info) {
    "bit_width" %in% names(field_info) && !is.na(field_info[["bit_width"]])
}

# ----------------------------------------------------------------------------
# parse structure signature

make_struct_info <- function(name, signature, field_names, envir = parent.frame(),
                             layout = aggregate_layout()) {
    make_aggregate_info(name, "struct", signature, field_names, envir = envir, layout = layout)
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
#' Fixed-size array fields are written as a type signature followed by `[N]`,
#' for example `C[4]` for `unsigned char[4]` or `<Point>[2]` for two nested
#' aggregate values.
#' `field-names` consists of space separated identifier names and should match
#' the number of fields. Integer bitfields are written as `name:width` in the
#' field name list. Unnamed padding bitfields use `:width`; zero-width alignment
#' bitfields use `:0`.
#' Optional layout directives can follow the field names before the final
#' semicolon.
#'
#' ```
#' struct-name { field-types } field-names [layout-directives] ;
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
#' Bitfields keep the ordinary type signature in `field-types` and put the bit
#' width next to the field name:
#' ```
#' "Flags{IIII}a:1 b:3 :4 c:8;"
#' ```
#' Packed or manually aligned aggregate layouts can be registered with
#' `@packed`, `@pack(n)` and `@align(n)` directives, where `n` must be a
#' positive power of two. `@packed` is equivalent to `@pack(1)`, `@pack(n)`
#' caps member alignment at `n`, and `@align(n)` raises the final aggregate
#' alignment to at least `n`.
#'
#' ```
#' "Packed{Cd}c d @packed;"
#' "Pack4{Cd}c d @pack(4);"
#' "PackedAligned{Cd}c d @packed @align(8);"
#' ```
#'
#' **Union type signatures** describe the components of the `union` C
#' data type.
#' Type signatures are used within the `field-types`.
#' Fixed-size array fields use the same `[N]` suffix as structure fields.
#' `field-names` consists of space separated identifier names and should match
#' the number of fields. The same layout directives can follow union field
#' names.
#'
#' ```
#' union-name | field-types } field-names [layout-directives] ;
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
                field_layout <- parse_aggregate_fields(tail[[2]])
            } else {
                field_layout <- list(fields = empty_field_specs(), layout = aggregate_layout())
            }
            assign(name, make_struct_info(name, sig, field_layout$fields,
                envir = envir, layout = field_layout$layout), envir = envir)
        }
    }
}

# ----------------------------------------------------------------------------
# parse union signature

make_union_info <- function(name, signature, field_names, envir = parent.frame(),
                            layout = aggregate_layout()) {
    make_aggregate_info(name, "union", signature, field_names, envir = envir, layout = layout)
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
                field_layout <- parse_aggregate_fields(tail[[2]])
            } else {
                field_layout <- list(fields = empty_field_specs(), layout = aggregate_layout())
            }
            assign(name, make_union_info(name, sig, field_layout$fields,
                envir = envir, layout = field_layout$layout), envir = envir)
        }
    }
}

# ----------------------------------------------------------------------------
# raw backed struct's (S3 Class)

#' @rdname struct
#' @export
as.ctype <- function(x, type) {
    caller <- parent.frame()
    if (is.character(type)) {
        type <- get_typeinfo(type, caller)
    } else if (!is.typeinfo(type)) {
        stop("type is not of class typeinfo and no character string")
    }
    if (!type$type %in% c("struct", "union")) stop("type must be C struct or union.")
    attr(x, "ctype") <- type
    attr(x, "struct") <- type$name
    attr(x, "typeinfo") <- type
    attr(x, "typeinfo_env") <- caller
    class(x) <- c("ctype", "struct")
    return(x)
}

#' @rdname struct
#' @export
cdata <- function(type) {
    caller <- parent.frame()
    if (is.character(type)) {
        name <- type
        type <- get_typeinfo(type, caller)
    } else if (is.typeinfo(type)) {
        name <- type$name
    } else {
        stop("type is not of class typeinfo and no character string")
    }
    if (!type$type %in% c("struct", "union")) stop("type must be C struct or union.")
    x <- raw(type$size)
    class(x) <- "struct"
    attr(x, "struct") <- type$name
    attr(x, "typeinfo") <- type
    attr(x, "typeinfo_env") <- caller
    return(x)
}

as_aggregate_field <- function(x, type, envir = parent.frame()) {
    if (is.character(type)) {
        type <- get_typeinfo(type, envir)
    } else if (!is.typeinfo(type)) {
        stop("type is not of class typeinfo and no character string")
    }
    if (!type$type %in% c("struct", "union")) stop("type must be C struct or union.")
    class(x) <- "struct"
    attr(x, "struct") <- type$name
    attr(x, "typeinfo") <- type
    attr(x, "typeinfo_env") <- envir
    x
}

struct_typeinfo <- function(x, envir = parent.frame()) {
    struct_name <- attr(x, "struct")
    info <- attr(x, "typeinfo")
    if (is.typeinfo(info) && identical(info$name, struct_name)) {
        return(info)
    }

    lookup_env <- attr(x, "typeinfo_env")
    if (!is.environment(lookup_env)) lookup_env <- envir
    info <- get_typeinfo(struct_name, envir = lookup_env)
    if (!is.null(info)) return(info)

    stop("unknown struct type '", struct_name, "'")
}

field_array_len <- function(field_info, field_index) {
    if ("array_len" %in% names(field_info)) {
        len <- as.integer(field_info[[field_index, "array_len"]])
        if (!is.na(len) && len > 0L) return(len)
    }
    1L
}

unpack_array_field <- function(x, offset, field_type_info, array_len) {
    if (array_len == 1L) {
        return(unpack(x, offset, field_type_info$signature))
    }

    values <- lapply(seq_len(array_len), function(i) {
        unpack(x, offset + (i - 1L) * field_type_info$size, field_type_info$signature)
    })

    if (field_type_info$signature %in% c("p", "x", "Z") || startsWith(field_type_info$signature, "*")) {
        values
    } else {
        unlist(values, recursive = FALSE, use.names = FALSE)
    }
}

pack_array_field <- function(x, offset, field_type_info, array_len, value) {
    if (array_len == 1L) {
        return(pack(x, offset, field_type_info$signature, value))
    }

    if (length(value) != array_len) {
        stop("value length does not match fixed array field length")
    }

    for (i in seq_len(array_len)) {
        pack(x, offset + (i - 1L) * field_type_info$size, field_type_info$signature, value[[i]])
    }
    invisible(NULL)
}

unpack_aggregate_array_field <- function(x, offset, field_type_name, field_type_info,
                                         array_len, envir = parent.frame()) {
    unpack_one <- function(i) {
        element_offset <- offset + (i - 1L) * field_type_info$size
        if (is.raw(x)) {
            size <- field_type_info$size
            as_aggregate_field(x[(element_offset + 1):(element_offset + size)],
                field_type_info, envir = envir
            )
        } else if (is.externalptr(x)) {
            as_aggregate_field(offset_ptr(x, element_offset), field_type_info, envir = envir)
        }
    }

    if (array_len == 1L) unpack_one(1L) else lapply(seq_len(array_len), unpack_one)
}

pack_aggregate_array_field <- function(x, offset, field_type_info, array_len, value) {
    if (array_len == 1L) {
        size <- field_type_info$size
        x[(offset + 1):(offset + size)] <- as.raw(value)
        return(invisible(NULL))
    }

    if (!is.list(value) || length(value) != array_len) {
        stop("value for fixed aggregate array field must be a list with the array length")
    }

    size <- field_type_info$size
    for (i in seq_len(array_len)) {
        element_offset <- offset + (i - 1L) * size
        x[(element_offset + 1):(element_offset + size)] <- as.raw(value[[i]])
    }
    invisible(NULL)
}

#' @rdname struct
#' @export
`$.struct` <- unpack.struct <- function(x, index) {
    caller <- parent.frame()
    struct_info <- struct_typeinfo(x, caller)
    lookup_env <- attr(x, "typeinfo_env")
    if (!is.environment(lookup_env)) lookup_env <- caller
    field_info <- struct_info$fields
    field_index <- match(index, field_info$name)
    if (is.na(field_index)) stop("unknown field index '", index, "'")
    field <- field_info[field_index, , drop = FALSE]
    if (is_bitfield(field)) {
        return(.Call(
            "C_unpack_bitfield", x, as.integer(field$bit_offset),
            as.integer(field$bit_width), as.character(field$type),
            PACKAGE = "rdyncall"
        ))
    }
    offset <- field_info[field_index, "offset"]
    field_type_name <- as.character(field_info[[field_index, "type"]])
    field_type_info <- get_typeinfo(field_type_name, lookup_env)
    array_len <- field_array_len(field_info, field_index)
    if (field_type_info$type %in% c("base", "pointer")) {
        unpack_array_field(x, offset, field_type_info, array_len)
    } else if (!is.null(field_type_info$fields)) {
        unpack_aggregate_array_field(x, offset, field_type_name, field_type_info,
            array_len, envir = lookup_env
        )
    } else {
        stop("invalid field type '", field_type_name, "' at field '", index)
    }
}

#' @rdname struct
#' @export
`$<-.struct` <- pack.struct <- function(x, index, value) {
    caller <- parent.frame()
    struct_info <- struct_typeinfo(x, caller)
    lookup_env <- attr(x, "typeinfo_env")
    if (!is.environment(lookup_env)) lookup_env <- caller
    field_info <- struct_info$fields
    field_index <- match(index, field_info$name)
    if (is.na(field_index)) stop("unknown field index '", index, "'")
    field <- field_info[field_index, , drop = FALSE]
    if (is_bitfield(field)) {
        .Call(
            "C_pack_bitfield", x, as.integer(field$bit_offset),
            as.integer(field$bit_width), as.character(field$type), value,
            PACKAGE = "rdyncall"
        )
        return(x)
    }
    offset <- field_info[field_index, "offset"]
    field_type_name <- as.character(field_info[field_index, "type"])
    field_type_info <- get_typeinfo(field_type_name, lookup_env)
    array_len <- field_array_len(field_info, field_index)
    if (field_type_info$type %in% c("base", "pointer")) {
        pack_array_field(x, offset, field_type_info, array_len, value)
    } else if (!is.null(field_type_info$fields)) {
        # substructure
        pack_aggregate_array_field(x, offset, field_type_info, array_len, value)
    } else {
        stop("invalid field type '", field_type_name, "' at field '", index)
    }
    return(x)
}

#' @rdname struct
#' @export
print.struct <- function(x, indent = 0, ...) {
    print_struct_value <- function(value, indent) {
        if (typeof(value) == "externalptr") {
            cat(if (is.nullptr(value)) "NULL" else "ptr", "\n")
        } else if (inherits(value, "struct")) {
            print.struct(value, indent = indent)
        } else if (is.list(value) && length(value) && all(vapply(value, inherits, logical(1L), "struct"))) {
            cat("[\n")
            for (i in seq_along(value)) {
                cat(rep("  ", indent + 1L), "[[", i, "]]: ", sep = "")
                print.struct(value[[i]], indent = indent + 1L)
            }
            cat(rep("  ", indent), "]\n", sep = "")
        } else if (length(value) == 0L) {
            cat("<empty>\n")
        } else {
            cat(paste(value, collapse = " "), "\n")
        }
    }

    struct_name <- attr(x, "struct")
    struct_info <- struct_typeinfo(x, parent.frame())
    field_info <- struct_info$fields
    field_names <- field_info$name
    field_names <- field_names[nzchar(field_names)]

    cat(struct_info$type, " ", struct_name, " ", sep = "")
    if (typeof(x) == "externalptr") {
        cat("*")
        if (is.nullptr(x)) {
            cat("=NULL\n")
            return(invisible(x))
        }
    }
    cat("{\n")
    # print data without last
    for (i in seq(along = field_names))
    {
        cat(rep("  ", indent + 1), field_names[[i]], ":")
        val <- unpack.struct(x, field_names[[i]])
        print_struct_value(val, indent = indent + 1L)
    }
    cat(rep("  ", indent), "}\n")
    invisible(x)
}

#' @rdname struct
#' @export
print.ctype <- function(x, ...) {
    print.struct(x, ...)
    invisible(x)
}
