VERSION <- commandArgs(TRUE)

# Download dyncall source code
if (VERSION == "latest") {
    hg <- Sys.which("hg")
    if (hg == "") {
        stop("Mercurial not found. Please install Mercurial first.")
    }

    if (!file.exists(sprintf("src/dyncall/configure"))) {
        system2(hg, c("clone", "https://dyncall.org/pub/dyncall/dyncall", "src/dyncall"))
    } else {
        system2(hg, "pull")
    }
} else {
    # Use https
    if (getRversion() < "3.3.0") setInternet2()

    if (!file.exists(sprintf("src/dyncall/configure"))) {
        name <- sprintf("dyncall-%s", VERSION)
        zip <- sprintf("%s.zip", name)
        download.file(sprintf("https://dyncall.org/r%s/%s", VERSION, zip), zip, quiet = TRUE)
        unzip(zip, exdir = "src")
        file.rename(file.path("src", name), file.path("src", "dyncall"))
        unlink(zip)
    }
}
