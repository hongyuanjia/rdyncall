# Package: rdyncall
# File: demo/raylib.R
# Description: raylib window demo using aggregate Color arguments.

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

source(system.file("demo-support", "github-release.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

raylib_asset_pattern <- function() {
    sys <- Sys.info()[["sysname"]]
    arch <- tolower(paste(R.version$arch, Sys.info()[["machine"]]))

    if (identical(sys, "Darwin")) {
        "macos"
    } else if (identical(sys, "Linux")) {
        if (grepl("aarch64|arm64", arch)) {
            "linux_arm64"
        } else if (grepl("i386|i686|x86", arch) && !grepl("x86_64|amd64", arch)) {
            "linux_i386"
        } else {
            "linux_amd64"
        }
    } else if (.Platform$OS.type == "windows") {
        if (grepl("arm64|aarch64", arch)) {
            "winarm64_msvc"
        } else if (grepl("i386|i686|x86", arch) && !grepl("x86_64|amd64", arch)) {
            "win32_msvc"
        } else {
            "win64_msvc"
        }
    } else {
        stop("raylib demo does not know which release asset to use for this platform", call. = FALSE)
    }
}

find_raylib <- function() {
    env_path <- Sys.getenv("RAYLIB_LIB", unset = "")
    if (nzchar(env_path)) {
        if (!file.exists(env_path)) {
            stop("RAYLIB_LIB does not exist: ", env_path, call. = FALSE)
        }
        return(env_path)
    }

    cache_dir <- Sys.getenv("RDYNCALL_RAYLIB_CACHE", unset = "")
    if (!nzchar(cache_dir)) {
        cache_dir <- NULL
    }

    rdyncall_demo_download_github_library(
        repo = "raysan5/raylib",
        asset_pattern = raylib_asset_pattern(),
        cache_name = "raylib",
        exclude_pattern = "webassembly",
        preferred_libraries = c("libraylib.dylib", "libraylib.so", "raylib.dll"),
        cache_dir = cache_dir
    )
}

bind_symbols <- function(lib, signatures) {
    env <- new.env(parent = globalenv())
    entries <- strsplit(gsub("[ \n\t]*", "", signatures), ";", fixed = TRUE)[[1L]]
    entries <- entries[nzchar(entries)]

    for (entry in entries) {
        name <- sub("\\(.*$", "", entry)
        signature <- sub("^[^(]+\\(", "", entry)
        address <- dynsym(lib, name)
        if (is.null(address)) {
            stop("unresolved raylib symbol: ", name, call. = FALSE)
        }
        f <- function(...) NULL
        body(f) <- substitute(dyncall(address, signature, ...), list(address = address, signature = signature))
        environment(f) <- env
        assign(name, f, envir = env)
    }
    env
}

cstruct("Color{CCCC}r g b a;")

color <- function(r, g, b, a = 255L) {
    x <- cdata(Color)
    x$r <- as.integer(r)
    x$g <- as.integer(g)
    x$b <- as.integer(b)
    x$a <- as.integer(a)
    x
}

run_raylib_demo <- function() {
    raylib_path <- find_raylib()
    raylib <- dynload(raylib_path)
    if (is.null(raylib)) {
        stop("unable to load raylib library: ", raylib_path, call. = FALSE)
    }

    ray <- bind_symbols(
        raylib,
        paste(
            "InitWindow(iiZ)v",
            "CloseWindow()v",
            "WindowShouldClose()B",
            "BeginDrawing()v",
            "EndDrawing()v",
            "ClearBackground(<Color>)v",
            "DrawText(Ziii<Color>)v",
            "SetTargetFPS(i)v",
            sep = ";"
        )
    )

    probe_only <- tolower(Sys.getenv("RAYLIB_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")
    if (probe_only) {
        invisible(color(230L, 41L, 55L, 255L))
        cat("raylib probe ok: loaded ", raylib_path, "\n", sep = "")
        return(invisible(TRUE))
    }

    duration <- as.numeric(Sys.getenv("RAYLIB_DEMO_SECONDS", "2"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 2
    }

    ray$InitWindow(640L, 360L, "rdyncall raylib demo")
    on.exit(ray$CloseWindow(), add = TRUE)
    ray$SetTargetFPS(60L)

    background <- color(245L, 245L, 245L, 255L)
    text_color <- color(80L, 80L, 80L, 255L)
    accent <- color(230L, 41L, 55L, 255L)
    started <- proc.time()[["elapsed"]]

    while (!isTRUE(ray$WindowShouldClose()) && proc.time()[["elapsed"]] - started < duration) {
        ray$BeginDrawing()
        ray$ClearBackground(background)
        ray$DrawText("rdyncall + raylib", 190L, 145L, 28L, accent)
        ray$DrawText("Color is passed by value", 184L, 185L, 18L, text_color)
        ray$EndDrawing()
    }

    cat("raylib window closed after ", round(proc.time()[["elapsed"]] - started, 2), " seconds.\n", sep = "")
}

run_raylib_demo()
