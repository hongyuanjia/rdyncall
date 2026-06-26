# Download a dynamic library from a GitHub latest-release asset and cache it.

demo_truthy_env <- function(name, default = "false") {
    value <- tolower(Sys.getenv(name, default))
    value %in% c("1", "true", "yes", "on")
}

demo_auto_download_enabled <- function(name) {
    demo_truthy_env(paste0(toupper(name), "_DEMO_AUTO_DOWNLOAD")) ||
        demo_truthy_env("RDYNCALL_DEMO_AUTO_DOWNLOAD")
}

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

    is_framework_binary <- function(path) {
        parts <- strsplit(path, .Platform$file.sep, fixed = TRUE)[[1L]]
        idx <- grep("\\.framework$", parts)
        if (!length(idx)) {
            return(FALSE)
        }
        framework_name <- sub("\\.framework$", "", parts[[idx[[length(idx)]]]])
        identical(basename(path), framework_name)
    }

    dynamic_libraries <- function(paths) {
        paths <- paths[file.exists(paths) & !dir.exists(paths)]
        paths[
            grepl("(\\.dylib$|\\.so(\\.[0-9]+)*$|\\.dll$)", paths) |
                vapply(paths, is_framework_binary, logical(1))
        ]
    }

    extract_archive <- function(archive, extract_dir) {
        if (grepl("\\.zip$", archive, ignore.case = TRUE)) {
            utils::unzip(archive, exdir = extract_dir)
        } else if (grepl("\\.dmg$", archive, ignore.case = TRUE)) {
            if (!identical(Sys.info()[["sysname"]], "Darwin")) {
                stop("DMG release assets can only be extracted on macOS", call. = FALSE)
            }
            mount_dir <- tempfile("rdyncall-dmg-")
            dir.create(mount_dir, recursive = TRUE)
            attached <- FALSE
            on.exit({
                if (attached) {
                    system2("hdiutil", c("detach", mount_dir, "-quiet"), stdout = FALSE, stderr = FALSE)
                }
                unlink(mount_dir, recursive = TRUE, force = TRUE)
            }, add = TRUE)

            status <- system2(
                "hdiutil",
                c("attach", "-readonly", "-nobrowse", "-mountpoint", mount_dir, archive),
                stdout = FALSE,
                stderr = FALSE
            )
            if (!identical(status, 0L)) {
                stop("failed to mount DMG release asset: ", archive, call. = FALSE)
            }
            attached <- TRUE

            entries <- list.files(mount_dir, all.files = TRUE, no.. = TRUE, full.names = TRUE)
            ok <- file.copy(entries, extract_dir, recursive = TRUE, copy.date = TRUE)
            if (!all(ok)) {
                stop("failed to copy files from DMG release asset: ", archive, call. = FALSE)
            }
        } else {
            utils::untar(archive, exdir = extract_dir)
        }
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
        extract_archive(archive, extract_dir)
    }

    lib <- preferred_library(list.files(extract_dir, recursive = TRUE, full.names = TRUE))
    if (!length(lib)) {
        stop("downloaded GitHub release asset did not contain a dynamic library", call. = FALSE)
    }
    lib
}
