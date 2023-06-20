dynfind1 <- if (.Platform$OS.type == "windows") {
    function(name, ...) {
        handle <- dynload(paste("lib", name, sep = ""), ...)
        if (!is.null(handle)) {
            return(handle)
        }
        dynload(name, ...)
    }
} else {
    if (Sys.info()[["sysname"]] == "Darwin") {
        function(name, ...) {
            handle <- dynload(paste(name, ".framework/", name, sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynload(paste("lib", name, ".dylib", sep = ""), ...)
        }
    } else {
        function(name, ...) {
            handle <- dynload(paste("lib", name, ".so", sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            handle <- dynload(paste("lib", name, sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynload(paste(name, sep = ""), ...) # needed by Solaris to lookup 'R'.
        }
    }
}

dynfind <- function(libnames, auto.unload = TRUE) {
    for (libname in libnames) {
        handle <- dynfind1(libname, auto.unload)
        if (!is.null(handle)) {
            return(handle)
        }
    }
}
