VERSION <- commandArgs(TRUE)
if (!length(VERSION)) VERSION <- "latest"

# Download dyncall source code
if (VERSION == "latest") {
    hg <- Sys.which("hg")
    if (hg == "") {
        stop("Mercurial not found. Please install Mercurial first.")
    }

    # Delete the folder if it is not the checkout source
    if (!dir.exists("src/dyncall/.hg")) {
        unlink("src/dyncall", recursive = TRUE, force = TRUE)
    }

    if (!file.exists("src/dyncall/dyncall/dyncall_version.h")) {
        system2(hg, c("clone", "https://dyncall.org/pub/dyncall/dyncall", "src/dyncall"))
    } else {
        system2(hg, "pull")
    }
} else {
    # Use https
    if (getRversion() < "3.3.0") setInternet2()

    # Delete the folder if it is the checkout source
    if (dir.exists("src/dyncall/.hg")) {
        unlink("src/dyncall", recursive = TRUE, force = TRUE)
    }

    # Version header is missing
    if (!file.exists("src/dyncall/dyncall/dyncall_version.h")) {
        # Delete the folder since the source is incomplete
        if (dir.exists("src/dyncall")) {
            unlink("src/dyncall", recursive = TRUE, force = TRUE)
        }
    } else {
        # Check if the version matches
        dyncall_ver_h <- readLines("src/dyncall/dyncall/dyncall_version.h")
        dyncall_ver <- regexec("^#define DYNCALL_VERSION\\s+0x(.*)", dyncall_ver_h)
        dyncall_ver <- unlist(regmatches(dyncall_ver_h, dyncall_ver))[2L]

        # c -> current version
        # This is the checkout source
        if (endsWith(dyncall_ver, "c")) {
            # Delete the folder
            unlink("src/dyncall", recursive = TRUE, force = TRUE)
        # f -> release version
        } else if (endsWith(dyncall_ver, "f")) {
            ver_spl <- strsplit(dyncall_ver, "")[[1L]]
            if (length(dyncall_ver) >= 4L) {
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
            if (numeric_version(dyncall_ver) != numeric_version(VERSION)) {
                unlink("src/dyncall", recursive = TRUE, force = TRUE)
            }
        # Unknown version pattern
        } else {
            # Delete the folder
            unlink("src/dyncall", recursive = TRUE, force = TRUE)
        }
    }

    # Download the corresponding version of source
    if (!dir.exists("src/dyncall")) {
        name <- sprintf("dyncall-%s", VERSION)
        zip <- sprintf("%s.zip", name)
        download.file(sprintf("https://dyncall.org/r%s/%s", VERSION, zip), zip, quiet = TRUE)
        unzip(zip, exdir = "src")
        file.rename(file.path("src", name), file.path("src", "dyncall"))
        unlink(zip)
    }
}
