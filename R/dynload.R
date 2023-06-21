# Package: rdyncall
# File: R/dyncall.R
# Description: R bindings for dynload library

dynload <- function(libname, auto.unload = TRUE) {
    libname <- as.character(libname)
    stopifnot(is.character(libname))

    libh <- .Call("C_dynload", libname, PACKAGE = "rdyncall")
    # append ".dll" if on Windows
    if (is.null(libh) && .Platform$OS.type == "windows" &&
        any(nodll <- !is.na(libname) & !grepl("\\.dll$", libname, ignore.case = TRUE))
    ) {
        libname[nodll] <- paste0(libname[nodll], ".dll")
        # try again
        libh <- .Call("C_dynload", libname, PACKAGE = "rdyncall")
    }

    if (!is.null(libh)) {
        attr(libh, "path") <- libname
        attr(libh, "auto.unload") <- auto.unload
        if (auto.unload) reg.finalizer(libh, dynunload)
    }
    libh
}

dynunload <- function(libhandle) {
    if (!is.externalptr(libhandle)) stop("libhandle argument must be of type 'externalptr'")
    .Call("C_dynunload", libhandle, PACKAGE = "rdyncall")
}

dynsym <- function(libhandle, symname, protect.lib = TRUE) {
    if (!is.externalptr(libhandle)) stop("libh argument must be of type 'externalptr'")
    .Call("C_dynsym", libhandle, as.character(symname), as.logical(protect.lib), PACKAGE = "rdyncall")
}
