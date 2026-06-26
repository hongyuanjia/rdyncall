# Shared raylib download and lookup helpers for demos.

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

raylib_system_libnames <- function() {
    "raylib"
}

find_system_raylib <- function() {
    candidates <- raylib_system_libnames()
    handle <- tryCatch(dynfind(candidates), error = function(e) NULL)
    if (is.null(handle)) {
        character()
    } else {
        candidates
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

    system_libs <- find_system_raylib()
    if (length(system_libs)) {
        return(system_libs)
    }

    if (!demo_auto_download_enabled("RAYLIB")) {
        stop(
            "Unable to load raylib. Install raylib, set RAYLIB_LIB to the shared library path, ",
            "or set RAYLIB_DEMO_AUTO_DOWNLOAD=true or RDYNCALL_DEMO_AUTO_DOWNLOAD=true to download a matching GitHub release asset.",
            call. = FALSE
        )
    }

    cache_dir <- Sys.getenv("RDYNCALL_RAYLIB_CACHE", unset = "")
    if (!nzchar(cache_dir)) {
        cache_dir <- NULL
    }

    github_release_library(
        repo = "raysan5/raylib",
        asset_pattern = raylib_asset_pattern(),
        cache_name = "raylib",
        exclude_pattern = "webassembly",
        preferred_libraries = c("libraylib.dylib", "libraylib.so", "raylib.dll"),
        cache_dir = cache_dir
    )
}
