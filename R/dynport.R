#' Dynamic R Bindings to standard and common C libraries
#'
#' @description
#' Function to bind APIs of standard and common C libraries to R via dynamically
#' created interface environment objects comprising R wrappers for C functions,
#' object-like macros, enums and data types.
#'
#' @details
#' `dynport()` offers a convenient method for binding entire C libraries to R.
#' This mechanism runs cross-platform and uses dynamic linkage but it implies
#' that the run-time library of a chosen binding need to be pre-installed in the
#' system.
#' Depending on the OS, the run-time libraries may be pre-installed or require
#' manual installation.
#' See [rdyncall-demos] for OS-specific installation notes for several C
#' libraries.
#'
#' The binding method is data-driven using platform-portable specifications
#' named _DynPort_ files.
#' _DynPort_ files are stored in a repository that is installed as part of the
#' package installation.
#' When `dynport()` processes a _DynPort_ file given by `portname`, an
#' environment object is created, populated with R wrapper and helper objects
#' that make up the interface to the C library, and attached to the search path
#' with the name `dynport:<PORTNAME>`.
#' Unloading of previously loaded dynport environments is achieved via
#' `detach(dynport:<PORTNAME>)`.
#'
#' Up to \pkg{rdyncall} version 0.7.4, R name space objects were used as
#' containers as described in the article _Foreign Library Interface_, thus
#' dynport \sQuote{packages} appeared as `"package:<PORTNAME>"` on the
#' search path.
#' The mechanism to create synthesized R packages at run-time required the use
#' of `.Internal` calls.
#' But since the use of internal R functions is not permitted for packages
#' distributed on CRAN we downgraded the package to use ordinary environment
#' objects starting with version 0.7.5 until a public interface for the creation
#' of R namespace objects is available.
#'
#' The following gives a list of currently available _DynPorts_:
#'
#' | **DynPort name/C library** | **Description**                                 |
#' |:---------------------------|:------------------------------------------------|
#' | `expat`                    | Expat XML Parser Library                        |
#' | `GL`                       | OpenGL 1.1 API                                  |
#' | `GLU`                      | OpenGL Utility Library                          |
#' | `GLUT`                     | OpenGL Utility Toolkit Library                  |
#' | `SDL`                      | Simple DirectMedia Layer Library                |
#' | `SDL_image`                | Loading of image files (png, jpeg, ...)         |
#' | `SDL_mixer`                | Loading/Playing of ogg/mp3/mod music files.     |
#' | `SDL_ttf`                  | Loading/Rendering of True Type Fonts.           |
#' | `SDL_net`                  | Networking library.                             |
#' | `glew`                     | OpenGL Extension Wrangler (includes OpenGL 3.0) |
#' | `glfw`                     | OpenGL Windowing/Setup Library                  |
#' | `gl3`                      | strict OpenGL 3 (untested)                      |
#' | `R`                        | R shared library                                |
#' | `ode`                      | Open Dynamics (Physics-) Engine (untested)      |
#' | `cuda`                     | NVIDIA Cuda (untested)                          |
#' | `csound`                   | Sound programming language and library          |
#' | `opencl`                   | OpenCL (untested)                               |
#' | `stdio`                    | C Standard Library I/O Functions                |
#' | `glpk`                     | GNU Linear Programming Kit                      |
#' | `EGL`                      | Embedded Systems Graphics Library               |
#'
#' As of the current implementation _DynPort_ files are R scripts that perform
#' up to three tasks:
#'
#' - Functions (and pointer-to-function variables) are mapped via [dynbind()]
#'   and a description of the C library using a _library signatures_.
#' - Symbolic names are assigned to its values for object-like macro defines and
#'   C enum types.
#' - Run-time type-information objects for aggregate C data types (struct and
#'   union) are registered via [cstruct()] and [cunion()].
#'
#' The file path to the _DynPort_ file is derived from `portname` per default.
#' This would refer to `"<repo>/<portname>.R"` where `repo` usually refers to
#' the initial _DynPort_ repository located at the sub-folder `"dynports/"` of
#' the package.
#' If `portfile` is given, then this value is taken as file path (usually for
#' testing purpose).
#'
#' A tool suite, comprising AWK (was boost wave), GCC Preprocessor, GCC-XML and
#' XSLT, was used to generate the available _DynPort_ files automatically
#' by extracting type information from C library header files.
#'
#' In a future release, the DynPort format will be changed to
#' a language-neutral text file document.
#' For the interested reader:
#' A first prototype is currently available in an FFI extension to the Lua
#' programming language (see `luadyncall` subversion sub-tree).
#' A third revision (including function types in call signatures, bitfields,
#' arrays, etc..) is currently in development.
#'
#' @param portname the name of a dynport, given as a literal or character
#'        string.
#'
#' @param portfile `NULL` or character string giving a script file to parse.
#'
#' @param repo character string giving the path to the root of the `dynport`
#'        repository.
#'
#' @references
#'
#' Adler, D. (2012) \dQuote{Foreign Library Interface}, _The R Journal_,
#'   **4(1)**, 30--40, June 2012.
#'   \url{https://journal.r-project.org/articles/RJ-2012-004/}
#'
#' Adler, D., Philipp, T. (2008) _DynCall Project_.
#'   \url{https://dyncall.org}
#'
#' Clark, J. (1998). expat - XML Parser Toolkit.
#'   \url{https://expat.sourceforge.net}
#'
#' Ikits, M. and Magallon, M. (2002).  The OpenGL Extension Wrangler Library.
#'   \url{https://glew.sourceforge.net}
#'
#' Latinga, S. (1998). The Simple DirectMedia Layer Library.
#'   \url{http://www.libsdl.org}
#'
#' Segal, M. and Akeley, K. (1992). The OpenGL Graphics System. A Specification,
#' Version 1.0. \url{http://www.opengl.org}
#'
#' Smith, R. (2001). Open Dynamics Engine. \url{http://www.ode.org}
#'
#' @examples
#' \dontrun{
#' # Using SDL and OpenGL in R
#' dynport(SDL)
#' dynport(GL)
#' # Initialize Video Sub-system
#' SDL_Init(SDL_INIT_VIDEO)
#' # Initialize Screen with OpenGL Context and Double Buffering
#' SDL_SetVideoMode(320, 256, 32, SDL_OPENGL+SDL_DOUBLEBUF)
#' # Clear Color and Clear Screen
#' glClearColor(0, 0, 1, 0) # blue
#' glClear(GL_COLOR_BUFFER_BIT)
#' # Flip Double-Buffer
#' SDL_GL_SwapBuffers()
#' }
#' @aliases loadDynportNamespace
#' @keywords programming interface
#' @author Daniel Adler <dadler@uni-goettingen.de>
#' @export
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
