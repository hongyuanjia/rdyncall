\name{rdyncall-demos}
\alias{rdyncall-demos}
\title{rdyncall demos: shared library notes}
\description{
The demos of the \pkg{rdyncall} package (see
\code{demo(package = "rdyncall")}) exercise direct calls, callbacks, generated
DynPort packages and a few real shared libraries.

Some demos only use the R runtime or the platform C runtime. Others require
external shared libraries to be installed and discoverable by \code{\link{dynfind}}.
}
\section{Current demos}{
\tabular{lll}{
\strong{Demo} \tab \strong{Required external library} \tab \strong{Notes} \cr
\code{sqrt} \tab C math library \tab Usually provided by the operating system \cr
\code{factorial} \tab none \tab Calls an R callback through a C function pointer \cr
\code{callbacks} \tab none \tab Callback examples \cr
\code{qsort} \tab C runtime \tab Uses the platform \code{qsort()} \cr
\code{stdio} \tab C runtime \tab Uses platform standard I/O functions \cr
\code{R_ShowMessage} \tab R shared library \tab Uses the loaded R runtime \cr
\code{glpk} \tab GLPK \tab Solves a small linear program \cr
\code{libxml2} \tab libxml2 \tab Parses a small XML document \cr
\code{SDL} \tab SDL3 \tab Opens an SDL3 window for the snake demo \cr
\code{SDL_audio} \tab SDL3 \tab Opens an SDL3 audio/window demo \cr
\code{SDL_raster} \tab SDL3 and OpenGL \tab Opens an SDL3/OpenGL raster demo \cr
\code{raylib} \tab raylib \tab Opens a raylib window; can use \code{RAYLIB_LIB} \cr
}
}
\section{Library discovery}{
Place shared libraries in a standard system location or update the platform
library search path so that \code{\link{dynfind}} can locate them. On Windows
this usually means \code{PATH}; on Unix-like systems it can mean the dynamic
linker search path or a package-manager library directory.

Several demos also honor explicit environment variables:
\itemize{
  \item \code{SDL3_LIB}: path to an SDL3 shared library.
  \item \code{OPENGL_LIB}: path to an OpenGL shared library.
  \item \code{RAYLIB_LIB}: path to a raylib shared library.
  \item \code{RDYNCALL_RAYLIB_CACHE}: cache directory used by the raylib demo
    when it downloads a release asset.
}
}
\section{Installation hints}{
Install the development/runtime package names used by your operating system or
package manager. Common examples are:
\tabular{ll}{
\strong{Platform} \tab \strong{Examples} \cr
macOS with Homebrew \tab \code{brew install glpk libxml2 sdl3 raylib} \cr
Debian/Ubuntu \tab \code{apt install libglpk40 libxml2 libsdl3-0 libgl1 libglu1-mesa} \cr
Fedora \tab \code{dnf install glpk libxml2 SDL3 mesa-libGL mesa-libGLU} \cr
Windows \tab Install matching DLLs with MSYS2, Scoop, vcpkg or another package manager and put them on \code{PATH} \cr
}

The raylib demo can use a locally installed raylib through \code{RAYLIB_LIB}.
If \code{RAYLIB_LIB} is not set, it attempts to obtain a matching release asset
from the raylib GitHub releases and cache it locally.
}
\seealso{
\code{\link{dynfind}}, \code{\link{dynbind}}, \code{\link{dynport}}
}
