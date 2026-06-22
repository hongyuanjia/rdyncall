# Shared helpers for demos that can download optional third-party libraries.

rdyncall_demo_cache_root <- function() {
    if (getRversion() >= "4.0.0") {
        return(tools::R_user_dir("rdyncall", "cache"))
    }

    cache <- Sys.getenv("R_USER_CACHE_DIR", "")
    if (nzchar(cache)) {
        return(file.path(cache, "rdyncall"))
    }

    cache <- Sys.getenv("XDG_CACHE_HOME", "")
    if (nzchar(cache)) {
        return(file.path(cache, "rdyncall"))
    }

    if (.Platform$OS.type == "windows") {
        cache <- Sys.getenv("LOCALAPPDATA", "")
        if (!nzchar(cache)) {
            cache <- tempdir()
        }
        return(file.path(cache, "rdyncall", "cache"))
    }

    home <- path.expand("~")
    if (identical(Sys.info()[["sysname"]], "Darwin")) {
        return(file.path(home, "Library", "Caches", "rdyncall"))
    }

    file.path(home, ".cache", "rdyncall")
}

rdyncall_demo_dynamic_libraries <- function(paths) {
    paths[file.exists(paths) & grepl("(\\.dylib$|\\.so(\\.[0-9]+)*$|\\.dll$)", paths)]
}

rdyncall_demo_preferred_library <- function(paths, preferred = character()) {
    libs <- rdyncall_demo_dynamic_libraries(paths)
    if (!length(libs)) {
        return(character())
    }
    if (length(preferred)) {
        matched <- libs[basename(libs) %in% preferred]
        if (length(matched)) {
            return(matched[[1L]])
        }
    }
    libs[[1L]]
}

rdyncall_demo_cached_github_library <- function(cache_dir, preferred = character()) {
    if (!dir.exists(cache_dir)) {
        return(character())
    }
    rdyncall_demo_preferred_library(
        list.files(cache_dir, recursive = TRUE, full.names = TRUE),
        preferred = preferred
    )
}

rdyncall_demo_github_latest_assets <- function(repo) {
    api <- paste0("https://api.github.com/repos/", repo, "/releases/latest")
    json_file <- tempfile("rdyncall-github-release-", fileext = ".json")
    utils::download.file(api, json_file, mode = "wb", quiet = TRUE)
    json <- paste(readLines(json_file, warn = FALSE), collapse = "\n")

    tag <- sub('.*"tag_name"[[:space:]]*:[[:space:]]*"([^"]+)".*', "\\1", json)
    if (identical(tag, json)) {
        tag <- "latest"
    }

    matches <- regmatches(json, gregexpr('"browser_download_url"[[:space:]]*:[[:space:]]*"[^"]+"', json))[[1L]]
    urls <- sub('^"browser_download_url"[[:space:]]*:[[:space:]]*"([^"]+)".*$', "\\1", matches)
    list(tag = tag, urls = urls)
}

rdyncall_demo_download_github_library <- function(repo, asset_pattern, cache_name,
                                                  exclude_pattern = NULL,
                                                  preferred_libraries = character(),
                                                  cache_dir = NULL) {
    if (is.null(cache_dir)) {
        cache_dir <- file.path(rdyncall_demo_cache_root(), cache_name)
    }

    cached <- rdyncall_demo_cached_github_library(cache_dir, preferred = preferred_libraries)
    if (length(cached)) {
        message("Using cached ", cache_name, " library: ", cached)
        return(cached)
    }

    release <- rdyncall_demo_github_latest_assets(repo)
    urls <- release$urls[grepl(asset_pattern, release$urls, ignore.case = TRUE)]
    if (!is.null(exclude_pattern)) {
        urls <- urls[!grepl(exclude_pattern, urls, ignore.case = TRUE)]
    }
    if (!length(urls)) {
        stop("no GitHub release asset matched this platform pattern: ", asset_pattern, call. = FALSE)
    }

    version_dir <- file.path(cache_dir, release$tag)
    dir.create(version_dir, recursive = TRUE, showWarnings = FALSE)

    archive <- file.path(version_dir, basename(urls[[1L]]))
    if (!file.exists(archive)) {
        message("Downloading ", cache_name, " ", release$tag, " to ", archive)
        utils::download.file(urls[[1L]], archive, mode = "wb")
    } else {
        message("Using cached ", cache_name, " archive: ", archive)
    }

    extract_dir <- file.path(version_dir, "extract")
    if (!dir.exists(extract_dir)) {
        dir.create(extract_dir, recursive = TRUE)
        if (grepl("\\.zip$", archive, ignore.case = TRUE)) {
            utils::unzip(archive, exdir = extract_dir)
        } else {
            utils::untar(archive, exdir = extract_dir)
        }
    }

    lib <- rdyncall_demo_preferred_library(
        list.files(extract_dir, recursive = TRUE, full.names = TRUE),
        preferred = preferred_libraries
    )
    if (!length(lib)) {
        stop("downloaded GitHub release asset did not contain a dynamic library", call. = FALSE)
    }
    lib
}
