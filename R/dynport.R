# Project: rdyncall
# File: R/dynports.R
# Description: repository for multi-platform bindings to binary components.
# Author: Daniel Adler <dadler@uni-goettingen.de>

dynport <- function(portname, portfile = NULL, repo = system.file("dynports", package = "rdyncall")) {
    # literate portname string
    portname <- as.character(substitute(portname))
    if (missing(portfile)) {
        # search for portfile
        portfile <- file.path(repo, paste(portname, ".R", sep = ""))
        if (!file.exists(portfile)) portfile <- file.path(repo, paste(portname, ".json", sep = ""))
        if (!file.exists(portfile)) stop("dynport '", portname, "' not found.")
    }
    loadDynportNamespace(portname, portfile)
}

loadDynportNamespace <- function(name, portfile, do.attach = TRUE) {
    name <- as.character(name)
    portfile <- as.character(portfile)
    if (do.attach) {
        envname <- paste("dynport", name, sep = ":")
        if (envname %in% search()) {
            return()
        }
        env <- new.env()
        sys.source(portfile, envir = env)

        # directly use base::attach will cause a CRAN check NOTE
        getExportedValue(.BaseNamespaceEnv, "attach")(env, name = envname)
    } else {
        env <- new.env()
        sys.source(portfile, envir = env)
        return(env)
    }
}
