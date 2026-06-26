# Shared SDL3 download and lookup helpers for demos.

source(system.file("demo-support", "github-release.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

if (!exists("demo_auto_download_enabled", mode = "function")) {
    demo_truthy_env <- function(name, default = "false") {
        value <- tolower(Sys.getenv(name, default))
        value %in% c("1", "true", "yes", "on")
    }
    demo_auto_download_enabled <- function(name) {
        demo_truthy_env(paste0(toupper(name), "_DEMO_AUTO_DOWNLOAD")) ||
            demo_truthy_env("RDYNCALL_DEMO_AUTO_DOWNLOAD")
    }
}

sdl3_system_libnames <- function() {
    c("SDL3", "SDL3-0", "SDL3-3")
}

sdl3_asset_pattern <- function() {
    sys <- Sys.info()[["sysname"]]
    arch <- tolower(paste(R.version$arch, Sys.info()[["machine"]]))

    if (identical(sys, "Darwin")) {
        "SDL3-[0-9.]+\\.dmg$"
    } else if (.Platform$OS.type == "windows") {
        if (grepl("arm64|aarch64", arch)) {
            "SDL3-[0-9.]+-win32-arm64\\.zip$"
        } else if (grepl("i386|i686|x86", arch) && !grepl("x86_64|amd64", arch)) {
            "SDL3-[0-9.]+-win32-x86\\.zip$"
        } else {
            "SDL3-[0-9.]+-win32-x64\\.zip$"
        }
    } else if (identical(sys, "Linux")) {
        NA_character_
    } else {
        stop("SDL3 demo does not know which release asset to use for this platform", call. = FALSE)
    }
}

find_system_sdl3 <- function() {
    candidates <- sdl3_system_libnames()
    handle <- tryCatch(dynfind(candidates), error = function(e) NULL)
    if (is.null(handle)) {
        character()
    } else {
        candidates
    }
}

find_sdl3 <- function() {
    env_path <- Sys.getenv("SDL3_LIB", unset = "")
    if (nzchar(env_path)) {
        if (!file.exists(env_path)) {
            stop("SDL3_LIB does not exist: ", env_path, call. = FALSE)
        }
        return(env_path)
    }

    system_libs <- find_system_sdl3()
    if (length(system_libs)) {
        return(system_libs)
    }

    if (!demo_auto_download_enabled("SDL3")) {
        stop(
            "Unable to load SDL3. Install SDL3, set SDL3_LIB to the shared library path, ",
            "or set SDL3_DEMO_AUTO_DOWNLOAD=true or RDYNCALL_DEMO_AUTO_DOWNLOAD=true to download a matching GitHub release asset.",
            call. = FALSE
        )
    }

    asset_pattern <- sdl3_asset_pattern()
    if (is.na(asset_pattern)) {
        stop(
            "Official SDL3 GitHub releases do not provide prebuilt Linux shared libraries. ",
            "Install SDL3 with your system package manager or set SDL3_LIB to the shared library path.",
            call. = FALSE
        )
    }

    cache_dir <- Sys.getenv("RDYNCALL_SDL3_CACHE", unset = "")
    if (!nzchar(cache_dir)) {
        cache_dir <- NULL
    }

    github_release_library(
        repo = "libsdl-org/SDL",
        asset_pattern = asset_pattern,
        cache_name = "sdl3",
        exclude_pattern = "devel|android|mingw|\\.sig$|\\.tar\\.gz$",
        preferred_libraries = c("libSDL3.dylib", "SDL3.dll", "SDL3"),
        cache_dir = cache_dir
    )
}

sdl3_demo_dynport <- function(libnames = find_sdl3()) {
    src <- system.file("dynports", "SDL3.dynport", package = "rdyncall", mustWork = TRUE)
    lines <- readLines(src, warn = FALSE)
    start <- grep("^Library:[[:space:]]*$", lines)
    if (!length(start)) {
        stop("SDL3 DynPort file does not contain a Library field", call. = FALSE)
    }
    start <- start[[1L]]

    next_fields <- which(seq_along(lines) > start & grepl("^[A-Za-z][A-Za-z0-9_/-]*:", lines))
    end <- if (length(next_fields)) next_fields[[1L]] - 1L else length(lines)
    replacement <- c("Library:", paste0("    ", libnames))
    before <- if (start > 1L) lines[seq_len(start - 1L)] else character()
    after <- if (end < length(lines)) lines[seq.int(end + 1L, length(lines))] else character()
    lines <- c(before, replacement, after)

    dst <- tempfile("rdyncall-SDL3-", fileext = ".dynport")
    writeLines(lines, dst, useBytes = TRUE)
    dst
}
