# Download a dynamic library from a GitHub latest-release asset and cache it.

github_release_library <- function(repo, asset_pattern, cache_name,
                                   exclude_pattern = NULL,
                                   preferred_libraries = character(),
                                   cache_dir = NULL) {
    cache_root <- function() {
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

    dynamic_libraries <- function(paths) {
        paths[file.exists(paths) & grepl("(\\.dylib$|\\.so(\\.[0-9]+)*$|\\.dll$)", paths)]
    }

    preferred_library <- function(paths) {
        libs <- dynamic_libraries(paths)
        if (!length(libs)) {
            return(character())
        }
        if (length(preferred_libraries)) {
            matched <- libs[basename(libs) %in% preferred_libraries]
            if (length(matched)) {
                return(matched[[1L]])
            }
        }
        libs[[1L]]
    }

    latest_assets <- function() {
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

    if (is.null(cache_dir)) {
        cache_dir <- file.path(cache_root(), cache_name)
    }

    if (dir.exists(cache_dir)) {
        cached <- preferred_library(list.files(cache_dir, recursive = TRUE, full.names = TRUE))
        if (length(cached)) {
            message("Using cached ", cache_name, " library: ", cached)
            return(cached)
        }
    }

    release <- latest_assets()
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

    lib <- preferred_library(list.files(extract_dir, recursive = TRUE, full.names = TRUE))
    if (!length(lib)) {
        stop("downloaded GitHub release asset did not contain a dynamic library", call. = FALSE)
    }
    lib
}
