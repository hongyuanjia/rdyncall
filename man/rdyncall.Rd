\name{rdyncall}
\docType{package}
\alias{rdyncall}
\alias{rdyncall-package}
\title{Improved Foreign Function Interface (FFI) and Dynamic Bindings to C Libraries (e.g. OpenGL) }
\description{The package provides a cross-platform framework for dynamic binding of
  C libraries using a flexible Foreign Function Interface (FFI).
  The FFI supports almost all fundamental C types, multiple calling conventions,
  symbolic access to foreign C struct/union data types and wrapping of R functions
  as C callback function pointers.
  Dynamic bindings to shared C libraries are data-driven by cross-platform binding specification
  using a compact plain text format ; an initial repository of bindings to a couple of
  common C libraries (OpenGL, SDL, Expat, glew, CUDA, OpenCL, ODE, R) comes with the package.
  The package includes a variety of technology demos and OS-specific notes for installation of shared libraries.
}
\details{
\pkg{rdyncall} offers a stack of interoperability technologies for working
with foreign compiled languages using cross-platform portable abstraction
methods.

For R application development, the package facilitates direct access from R
to the C Application Programming Interface (API) of common libraries.
This enables a new style of development: R applications can use
low-level services of portable C libraries.
System-level code can be implemented in R without leaving the language.
C APIs can be explored from within the R interpreter.
Moving the R code from one platform to the other does not involve
recompilation.
Ofcourse, the run-time libraries need to be installed using a standard
procedure of the target Operating-System Distribution.
See \link{rdyncall-demos} for details on this.

For R core development and research, the package provides an improved Foreign
Function Interface (FFI) that can be used to call arbitrary
foreign precompiled C code without the need for additional
compilation of wrapper code. The back-end library is extendable with new
calling conventions (such as Fortran,Pascal,COM,etc.. - which has not been
the focus as of this release, but might be supported officially in the near
futurue).
Basic type-safety checks for argument passing and framework support for
working with foreign C data types such as pointers, arrays, structs and
wrapping of R functions into first-level C callback function pointers
round up this framework.
}
\section{Overview}{
\itemize{
\item Flexible FFI with support for almost all C types, type-safety checks and multiple calling conventions. See \code{\link{dyncall}}.
\item Loading of shared libraries with \emph{automatic unload management} and using direct access to OS linker. See \code{\link{dynload}}.
\item Cross-platform naming and loading of shared libraries. See \code{\link{dynfind}}.
\item Binding C library functions via thin call wrappers. See \code{\link{dynbind}}.
\item Handling of foreign C pointer, array and struct/union data types. See \code{\link{packing}} and \code{\link{struct}}.
\item Dynamic wrapping of R functions as C function pointers to be used in C callbacks. See \code{\link{new.callback}}.
\item Dynamic bindings to standard and common C libraries and APIs (functions, variables, macro constants, enums, struct and union types). See \code{\link{dynport}}.
}
}
\section{Getting Started}{
Several demos ranging from simple FFI calls to the C standard math library up to more complex 3D OpenGL/SDL Applications are available.
See \code{demos(package="rdyncall")} for an overview.
Some demos require shared C libraries to be installed in the system. Please read \link{rdyncall-demos} for details.
}
\section{Supported Platforms}{
The low-level implementation is mainly based on libraries from the DynCall
Project (\url{https://dyncall.org}). The library suite is distributed
as part of the package source tree.

The dyncall and dyncallback libraries implement generic low-level services
with the help of a small amount of hand-written assembly code and
careful modeling of the target machine's calling sequence
for each platform to support.

As of version 0.6, the following processor architectures are supported:

\itemize{
\item Intel i386 32-bit and AMD 64-bit Platforms
\item ARM 32-bit (OABI, EABI and ARMHF ABI with support for Thumb)
\item PowerPC 32-bit (support for callbacks not implemented for Linux/BSD)
\item MIPS 32- and 64-bit (support for callbacks not yet implemented)
\item SPARC 32- and 64-bit (support for callbacks not yet implemented)
}

The DynCall libraries are tested on Linux, Mac OS X, Windows, BSD derivates
and more exotic platforms such as game consoles and Plan9.
Please see the details on portability for \link{dyncall}, \link{dyncallback} and \link{dynload}
and the official DynCall manual for full details of the back-end.
The R Package has been tested on several major R platforms.
The following gives a list of comments on platforms about the status of this package.

\tabular{l}{
\cr
Linux Debian 4/ppc32 , R-2.4.0 : ok, but no callbacks. \cr
Linux Debian 5/arm   , R-2.7.0 : ok, SDL not tested. \cr
Linux Debian 6/x86   , R-2.12.2: ok. \cr
Linux Debian 6/x64   , R-2.12.2: ok. \cr
Linux Ubuntu 10/armv7, R-2.14  : ok. \cr
Linux Fedora 14/x86            : ok. \cr
Linux Ubuntu 12/i386 , R-2.15.1: ok. \cr
Mac OS X 10.4/ppc    , R-2.10.0: ok. \cr
Mac OS X 10.6/x86    , R-2.12.2: ok. \cr
Mac OS X 10.6/x64    , R-2.12.2: ok. \cr
Mac OS X 10.7/x64    , R-2.15.1: ok. \cr
NetBSD 5.0/x86                 : ok.  \cr
NetBSD 5.1/x64                 : ok.  \cr
OpenBSD 4.8/x64      , R-2.7.0 : SDL failed. \cr
Windows XP/x86       , R-2.12.2: ok. \cr
Windows  7/x86       , R-2.12.2: ok. \cr
Windows  7/x64       , R-2.12.2: ok, use correct 64-bit SDL DLL, SDL extension not tested - see \link{rdyncall-demos}) \cr
FreeBSD 8.2/x86                : build ok, no tests made for X11. \cr
}
}
\references{
  Adler, D. (2012) \dQuote{Foreign Library Interface}, \emph{The R Journal}, \bold{4(1)}, 30--40, June 2012.
  \url{https://journal.r-project.org/articles/RJ-2012-004/}

  Adler, D., Philipp, T. (2008) \emph{DynCall Project}.
  \url{https://dyncall.org}
}
\examples{
\dontrun{
# multimedia example
# load dynports for OpenGL, Simple DirectMedia library
# globals:
surface <- NULL
# init SDL and OpenGL
init <- function()
{
  dynport(SDL)
  dynport(GL)
  if ( SDL_Init(SDL_INIT_VIDEO) != 0 ) stop("SDL_Init failed")
  surface <<- SDL_SetVideoMode(320,240,32,SDL_DOUBLEBUF+SDL_OPENGL)
  cat("surface dimension:", surface$w, "x",surface$h,sep="")
}
# draw blue screen
updateSurface <- function(t)
{
  glClearColor(0,0,t \%\% 1,0)
  glClear(GL_COLOR_BUFFER_BIT+GL_DEPTH_BUFFER_BIT)
  SDL_GL_SwapBuffers()
}
# wait till close
mainloop <- function()
{
  quit <- FALSE
  evt <- new.struct(SDL_Event)
  base <- SDL_GetTicks() / 1000
  t <- 0
  while(!quit) {
    updateSurface(t)
    while(SDL_PollEvent(evt)) {
      if ( evt$type == SDL_QUIT ) quit <- TRUE
    }
    now <- SDL_GetTicks() / 1000
    t <- now - base
  }
}
init()
mainloop()
}
}
\keyword{programming}
\keyword{interface}

