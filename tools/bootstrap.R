VERSION <- commandArgs(TRUE)
if (!length(VERSION)) VERSION <- "latest"
VERSION <- VERSION[[1L]]

dyncall_repo <- "https://dyncall.org/pub/dyncall/dyncall/"
dyncall_dir <- "src/dyncall"
dyncall_version_header <- file.path(dyncall_dir, "dyncall", "dyncall_version.h")

run <- function(command, args) {
    status <- system2(command, args)
    if (!identical(status, 0L)) {
        stop(
            sprintf("Command failed: %s %s", command, paste(args, collapse = " ")),
            call. = FALSE
        )
    }
}

# Download dyncall source code
if (VERSION == "latest") {
    hg <- Sys.which("hg")
    if (hg == "") {
        stop(
            "Mercurial not found. Please install Mercurial first ",
            "(for example, `brew install mercurial`) to fetch latest dyncall from ",
            dyncall_repo,
            call. = FALSE
        )
    }

    # Delete the folder if it is not the checkout source
    if (!dir.exists(file.path(dyncall_dir, ".hg"))) {
        unlink(dyncall_dir, recursive = TRUE, force = TRUE)
    }

    if (!file.exists(dyncall_version_header)) {
        run(hg, c("clone", dyncall_repo, dyncall_dir))
    } else {
        run(hg, c("-R", dyncall_dir, "pull", "-u"))
    }

    if (!file.exists(dyncall_version_header)) {
        stop("dyncall checkout did not create ", dyncall_version_header, call. = FALSE)
    }
} else {
    # Use https
    if (getRversion() < "3.3.0") setInternet2()

    # Delete the folder if it is the checkout source
    if (dir.exists(file.path(dyncall_dir, ".hg"))) {
        unlink(dyncall_dir, recursive = TRUE, force = TRUE)
    }

    # Version header is missing
    if (!file.exists(dyncall_version_header)) {
        # Delete the folder since the source is incomplete
        if (dir.exists(dyncall_dir)) {
            unlink(dyncall_dir, recursive = TRUE, force = TRUE)
        }
    } else {
        # Check if the version matches
        dyncall_ver_h <- readLines(dyncall_version_header)
        dyncall_ver <- regexec("^#define DYNCALL_VERSION\\s+0x(.*)", dyncall_ver_h)
        dyncall_ver <- unlist(regmatches(dyncall_ver_h, dyncall_ver))[2L]

        # c -> current version
        # This is the checkout source
        if (endsWith(dyncall_ver, "c")) {
            # Delete the folder
            unlink(dyncall_dir, recursive = TRUE, force = TRUE)
        # f -> release version
        } else if (endsWith(dyncall_ver, "f")) {
            ver_spl <- strsplit(dyncall_ver, "")[[1L]]
            if (length(ver_spl) >= 4L) {
                dyncall_ver <- paste(
                    major = ver_spl[1L],
                    minor = ver_spl[2L],
                    patch = ver_spl[3L],
                    sep = "."
                )
            } else {
                dyncall_ver <- paste(
                    major = "0",
                    minor = ver_spl[1L],
                    patch = ver_spl[2L],
                    sep = "."
                )
            }

            # Delete the folder if version mismatches
            if (grepl("^\\d+\\.\\d+", VERSION)) VERSION <- paste0(VERSION, ".0")
            if (numeric_version(dyncall_ver) != numeric_version(VERSION)) {
                unlink(dyncall_dir, recursive = TRUE, force = TRUE)
            }
        # Unknown version pattern
        } else {
            # Delete the folder
            unlink(dyncall_dir, recursive = TRUE, force = TRUE)
        }
    }

    # Download the corresponding version of source
    if (!dir.exists(dyncall_dir)) {
        name <- sprintf("dyncall-%s", VERSION)
        zip <- sprintf("%s.zip", name)
        on.exit(unlink(zip), add = TRUE)
        status <- download.file(
            sprintf("https://dyncall.org/r%s/%s", VERSION, zip),
            zip,
            quiet = TRUE
        )
        if (!identical(status, 0L)) {
            stop("Failed to download dyncall release archive: ", zip, call. = FALSE)
        }
        unzip(zip, exdir = "src")
        if (!file.rename(file.path("src", name), dyncall_dir)) {
            stop("Failed to move extracted dyncall release into ", dyncall_dir, call. = FALSE)
        }
    }

    if (!file.exists(dyncall_version_header)) {
        stop("dyncall release did not create ", dyncall_version_header, call. = FALSE)
    }
}
