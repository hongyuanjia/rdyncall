# Package: rdyncall
# File: demo/SDL.R
# Description: SDL3 window lifecycle demo.

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

shared_library_candidates <- function(envvar, names) {
    env_path <- Sys.getenv(envvar, unset = "")
    if (nzchar(env_path)) {
        return(env_path)
    }

    dirs <- c(
        "/opt/homebrew/lib",
        "/usr/local/lib",
        "/opt/local/lib",
        "/usr/lib",
        "/usr/lib/x86_64-linux-gnu",
        "/usr/lib/aarch64-linux-gnu",
        "/lib/x86_64-linux-gnu",
        "/lib/aarch64-linux-gnu"
    )
    unique(file.path(rep(dirs, each = length(names)), names))
}

bind_library <- function(libnames, signatures, envir, envvar = NULL, path_candidates = character()) {
    paths <- path_candidates[file.exists(path_candidates)]
    if (length(paths)) {
        lib <- dynload(paths[[1L]])
        if (is.null(lib)) {
            stop("unable to load shared library: ", paths[[1L]], call. = FALSE)
        }
        return(bind_symbols(lib, signatures, envir))
    }

    tryCatch(
        dynbind(libnames, signatures, envir = envir),
        error = function(e) {
            hint <- if (!is.null(envvar)) paste0(" Set ", envvar, " to the shared library path.") else ""
            stop(conditionMessage(e), hint, call. = FALSE)
        }
    )
}

bind_symbols <- function(lib, signatures, envir) {
    entries <- strsplit(gsub("[ \n\t]*", "", signatures), ";", fixed = TRUE)[[1L]]
    entries <- entries[nzchar(entries)]
    unresolved <- character()

    for (entry in entries) {
        name <- sub("\\(.*$", "", entry)
        signature <- sub("^[^(]+\\(", "", entry)
        address <- dynsym(lib, name)
        if (is.null(address)) {
            unresolved <- c(unresolved, name)
            next
        }
        f <- function(...) NULL
        body(f) <- substitute(dyncall(address, signature, ...), list(address = address, signature = signature))
        environment(f) <- envir
        assign(name, f, envir = envir)
    }

    list(libhandle = lib, unresolved.symbols = unresolved)
}

SDL_INIT_VIDEO <- 0x00000020L

sdl <- new.env(parent = globalenv())
sdl_info <- bind_library(
    c("SDL3", "SDL3-0", "SDL3-3"),
    paste(
        "SDL_Init(I)B",
        "SDL_CreateWindow(ZiiL)p",
        "SDL_Delay(I)v",
        "SDL_DestroyWindow(p)v",
        "SDL_Quit()v",
        "SDL_GetError()Z",
        sep = ";"
    ),
    envir = sdl,
    envvar = "SDL3_LIB",
    path_candidates = shared_library_candidates(
        "SDL3_LIB",
        c("libSDL3.dylib", "libSDL3.so", "libSDL3.so.0", "SDL3.dll")
    )
)

if (length(sdl_info$unresolved.symbols)) {
    stop("unresolved SDL3 symbols: ", paste(sdl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}

run_sdl_demo <- function() {
    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3 demo", 640L, 360L, 0)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)

    cat("SDL3 window created; closing in 1.5 seconds.\n")
    sdl$SDL_Delay(1500L)
}

run_sdl_demo()
