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
            handle <- dynload(paste("lib", name, ".dylib", sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            # ref: https://developer.apple.com/forums/thread/692383
            # ref: https://developer.apple.com/forums/thread/655588
            #
            # Start from macOS 11.1, a dynamic linker shared cache is used
            # and there are no common .dylib files under '/usr/lib'.
            #
            # All the commonly-used dynamic libraries are pre-linked together
            # into a single shared file called 'libSystem.dylib'.
            #
            # Here have to try the full path
            #
            # Also, for C libraries, it seems that using
            # '/usr/lib/system/libsystem_*' works for 'dlSymsName'
            handle <- dynload(paste("/usr/lib/system/libsystem_", name, ".dylib", sep = ""), ...)
            if (!is.null(handle)) {
                return(handle)
            }
            dynload(paste("/usr/lib/lib", name, ".dylib", sep = ""), ...)
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
