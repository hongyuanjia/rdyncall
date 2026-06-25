#' Dynamic wrapping of R functions as C callbacks
#'
#' @description
#' Function to wrap R functions as C function pointers.
#'
#' @param signature character string specifying the
#'        [call signature][call-signature] of the C function callback type.
#'
#' @param fun R function to be wrapped as a C function pointer.
#'
#' @param envir the environment in which to evaluate the call to `fun`.
#'
#' @param callback external pointer returned by `ccallback()`.
#'
#' @param x object returned by `callback_status()`.
#'
#' @param ... unused.
#'
#' @details
#'
#' Callbacks are user-defined functions that are registered in a foreign library
#' and that are executed at a later time from within that library.
#' Examples include user-interface event handlers that are registered in GUI
#' toolkits, and, comparison functions for custom data types to be passed to
#' generic sort algorithm.
#'
#' The function `ccallback()` wraps an R function `fun` as a C function pointer
#' and returns an external pointer.
#' The foreign C function type of the wrapped R function is specified by a [call
#' signature][call-signature] given by `signature`.
#'
#' When the C function pointer is called, a global callback handler (implemented
#' in C) is executed first, that dynamically creates an R call expression to
#' `fun` using the arguments, passed from C and converted to R, according to the
#' argument types signature within the [call signature][call-signature]
#' specified. See [dyncall()] for details on the format.
#'
#' Finally, the handler evaluates the R call expression within the environment
#' given by `envir`. On return, the R return value of `fun` is coerced to the C
#' value, according to the return type signature specified in `signature` .
#'
#' Aggregate by-value callback arguments and returns use the same `<Type>`
#' signature syntax as [dyncall()]. An aggregate argument is passed to the R
#' callback as a raw-backed `cdata` object with `struct` and `typeinfo`
#' attributes. An aggregate return value must be a raw-backed object for the
#' same aggregate type and size. Type or storage mismatches disable the callback
#' and emit a warning.
#'
#' Aggregate callbacks are supported on the implemented 64-bit x86 and ARM64
#' dyncallback backends. On unsupported backends, creating a callback whose
#' signature contains `<Type>` fails early.
#'
#' If an error occurs during the evaluation, the callback will be disabled for
#' further invocations. Use `callback_status()` or `callback_last_error()` to
#' inspect a callback after foreign code has invoked it.
#'
#' @return
#' An external pointer to a synthetically generated C function.
#'
#' @note
#' The call signature **MUST** match the foreign C callback function type,
#' otherwise an activated callback call from C can lead to a **fatal R, process
#' crash**.
#'
#' A small amount of memory is allocated with each wrapper.
#' A finalizer function that frees the allocated memory is registered at the
#' external pointer.
#' If the external callback function pointer is registered in a C library, a
#' reference should also be held in R as long as the callback can be activated
#' from a foreign C run-time context,
#' otherwise the garbage collector might call the finalizer and the next
#' invocation of the callback could lead to a **fatal R process crash** as well.
#'
#' @references
#' Adler, D. (2012) "Foreign Library Interface", *The R Journal*,
#'   **4(1)** , 30--40, June 2012.
#'   \url{https://journal.r-project.org/articles/RJ-2012-004/}
#'
#'  Adler, D., Philipp, T. (2008) *DynCall Project*.
#'    \url{https://dyncall.org}
#'
#' @seealso
#' See [call signature][call-signature] for details on call signatures,
#' [reg.finalizer()] for details on finalizers.
#'
#' @examples
#' # Create a function, wrap it to a callback and call it via dyncall:
#' f <- function(x, y) x + y
#' cb <- ccallback("ii)i", f)
#' r <- dyncall(cb, "ii)i", 20, 3)
#'
#' # Sort vectors directly via 'qsort' C library function using an R callback:
#' dynbind(c("msvcrt","c","c.so.6"), "qsort(piip)v;")
#' cb <- ccallback("pp)i", function(px, py) {
#'     x <- unpack(px, 0, "d")
#'     y <- unpack(py, 0, "d")
#'     if (x >  y) return(1) else if (x == y) return(0) else return(-1)
#' })
#' x <- rnorm(100)
#' qsort(x, length(x), 8, cb)
#' x
#'
#' @keywords programming interface
#' @aliases callback dyncallback
#' @rdname callback
#' @export
ccallback <- function(signature, fun, envir = new.env()) {
    caller <- parent.frame()
    if (!is.character(signature) || length(signature) != 1L || is.na(signature)) {
        stop("'signature' must be a single character string", call. = FALSE)
    }
    stopifnot(is.function(fun))
    stopifnot(is.environment(envir))

    info <- callback_signature_info(signature, caller)
    state <- new.env(parent = emptyenv())
    state$last_error <- NULL
    wrapped <- function(...) {
        tryCatch(
            fun(...),
            error = function(err) {
                state$last_error <- list(
                    message = conditionMessage(err),
                    class = class(err),
                    reason = "r_error"
                )
                stop(err)
            }
        )
    }

    .Call(
        "C_callback", info$signature, info$aggregates, info$typeinfos,
        wrapped, envir, state, PACKAGE = "rdyncall"
    )
}

callback_signature_info <- function(signature, envir = parent.frame()) {
    if (!is.character(signature) || length(signature) != 1L || is.na(signature)) {
        stop("'signature' must be a single character string", call. = FALSE)
    }

    n <- nchar(signature)
    i <- 1L
    out <- character()
    aggregates <- list()
    typeinfos <- list()

    append_aggregate <- function(name) {
        info <- get_typeinfo(name, envir = envir)
        if (is.null(info)) {
            stop("unknown aggregate type '", name, "'", call. = FALSE)
        }
        aggregates[[length(aggregates) + 1L]] <<- dyncall_aggregate_layout(name, envir = envir)
        typeinfos[[length(typeinfos) + 1L]] <<- info
    }

    append_pointer <- function() {
        out[[length(out) + 1L]] <<- "p"
    }

    if (n >= 2L && substr(signature, 1L, 1L) == "_") {
        out <- c(substr(signature, 1L, 1L), substr(signature, 2L, 2L))
        i <- 3L
    }

    while (i <= n) {
        ch <- substr(signature, i, i)

        if (ch == "A") {
            stop("signature type 'A' is reserved for internal aggregate callbacks; use '<Type>'", call. = FALSE)
        }

        if (ch == "*") {
            while (i <= n && substr(signature, i, i) == "*") {
                i <- i + 1L
            }
            if (i > n) {
                stop("invalid pointer signature: missing pointed-to type", call. = FALSE)
            }
            if (substr(signature, i, i) == "<") {
                type <- dyncall_aggregate_signature_type(signature, i)
                i <- type$next_index + 1L
            } else {
                i <- i + 1L
            }
            append_pointer()
            next
        }

        if (ch == "<") {
            type <- dyncall_aggregate_signature_type(signature, i)
            append_aggregate(type$name)
            out[[length(out) + 1L]] <- "A"
            i <- type$next_index + 1L
            next
        }

        out[[length(out) + 1L]] <- ch
        i <- i + 1L
    }

    list(signature = paste0(out, collapse = ""), aggregates = aggregates, typeinfos = typeinfos)
}

#' @details
#' `callback_status()` reports whether a callback is still active, how many
#' times it has been invoked, and why it was disabled. A disabled callback is
#' not re-enabled by these helpers; create a new callback if foreign code needs
#' to call into R again.
#'
#' `callback_is_active()` returns only the active flag. `callback_last_error()`
#' returns `NULL` until an error disables the callback. Once an error has been
#' recorded, it returns a list with `message`, `class`, and `reason`.
#'
#' @return
#' `callback_status()` returns a list with class `callback_status`.
#' `callback_is_active()` returns a single logical value.
#' `callback_last_error()` returns `NULL` or a list describing the last error.
#'
#' @examples
#' cb <- ccallback("i)i", function(x) {
#'     if (x < 0) stop("negative values are not supported")
#'     x
#' })
#' callback_is_active(cb)
#' callback_status(cb)
#'
#' @rdname callback
#' @export
callback_status <- function(callback) {
    .Call("C_callback_status", callback, PACKAGE = "rdyncall")
}

#' @rdname callback
#' @export
callback_is_active <- function(callback) {
    .Call("C_callback_is_active", callback, PACKAGE = "rdyncall")
}

#' @rdname callback
#' @export
callback_last_error <- function(callback) {
    .Call("C_callback_last_error", callback, PACKAGE = "rdyncall")
}

#' @rdname callback
#' @export
print.callback_status <- function(x, ...) {
    state <- if (isTRUE(x$active)) "active" else "disabled"
    cat("<rdyncall callback: ", state, ">\n", sep = "")
    cat("signature: ", x$signature, "\n", sep = "")
    cat(
        "invocations: ", format(x$invocations),
        " (success: ", format(x$successful_invocations),
        ", errors: ", format(x$error_invocations),
        ", disabled: ", format(x$disabled_invocations), ")\n",
        sep = ""
    )
    if (!is.null(x$disable_reason)) {
        cat("disable reason: ", x$disable_reason, "\n", sep = "")
    }
    if (!is.null(x$last_error)) {
        cat("last error: ", x$last_error$message, "\n", sep = "")
    }
    invisible(x)
}
