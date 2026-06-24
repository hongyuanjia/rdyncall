article_math_names <- c("msvcrt", "m", "m.so.6")
article_libc_names <- c("msvcrt", "c", "c.so.6")
article_sdl2_names <- c("SDL2", "SDL2-2.0", "SDL2-2.0.so.0", "SDL2-2", "SDL2-0")

article_external_enabled <- function() {
    value <- tolower(Sys.getenv("RDYNCALL_ARTICLE_EXTERNAL", "false"))
    value %in% c("1", "true", "yes", "on")
}

article_library_available <- function(libnames) {
    handle <- tryCatch(rdyncall::dynfind(libnames), error = function(e) NULL)
    !is.null(handle) && !rdyncall::is.nullptr(handle)
}

article_eval_external <- function(libnames, label = paste(libnames, collapse = ", ")) {
    enabled <- article_external_enabled()
    available <- article_library_available(libnames)

    if (enabled && !available) {
        stop("external article chunk requested, but shared library was not found: ", label, call. = FALSE)
    }

    enabled && available
}

article_expect_symbols <- function(info, label = "foreign library") {
    unresolved <- info$unresolved.symbols
    if (length(unresolved)) {
        stop(label, " has unresolved symbols: ", paste(unresolved, collapse = ", "), call. = FALSE)
    }
    invisible(info)
}
