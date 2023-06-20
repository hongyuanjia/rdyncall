\name{callback}
\alias{new.callback}
\alias{callback}
\alias{dyncallback}
\title{Dynamic wrapping of R functions as C callbacks}
\description{  
Function to wrap R functions as C function pointers. 
}
\usage{
new.callback( signature, fun, envir = new.env() )
}
\arguments{
  \item{signature}{character string specifying the \link[=signature]{call signature} of the C function callback type.}
  \item{fun}{R function to be wrapped as a C function pointer.}
  \item{envir}{the environment in which to evaluate the call to \code{fun}. }
}
\details{
Callbacks are user-defined functions that are registered in a foreign library and that are executed at a later time from within that library.
Examples include user-interface event handlers that are registered in GUI toolkits, and, comparison functions for custom data types to be passed to generic sort algorithm.

The function \code{new.callback} wraps an R function \code{fun} as a C function pointer and returns an external pointer. The foreign C function type of the wrapped 
R function is specified by a \link{call signature} given by \code{signature}.

When the C function pointer is called, a global callback handler (implemented in C) is executed first, that dynamically creates an R call expression to \code{fun}
using the arguments, passed from C and converted to R, according to the \emph{argument types signature} within the \link{call signature} specified. See
\code{\link{dyncall}} for details on the format.
Finally, the handler evaluates the R call expression within the environment given by \code{envir}.
On return, the R return value of \code{fun} is coerced to the C value, according to the return type signature specified in \code{signature}.
If an error occurs during the evaluation, the callback will be disabled for further invocations. (This behaviour might change in the future.)

}
\value{
\code{new.callback} returns an external pointer to a synthetically generated C function.
}

\section{Portability}{
The implementation is based on the \emph{dyncallback} library (part of the DynCall project).

The following processor architectures are supported: X86, X64, ARM (including Thumb) and partial stable support for PowerPC 32-bit; The library
has been built and tested to work on various OSs: Linux, Mac OS X, Windows 32/64-bit, BSDs, Haiku, Nexenta/Open Solaris, Minix and Plan9,
as well as embedded platforms such as Linux/ARM (OpenMoko, Beagleboard, Gumstix, Efika MX, Raspberry Pi), Nintendo DS (ARM), Sony Playstation Portable (MIPS 32-bit/eabi) and iOS (ARM - armv6 mode ok, armv7 unstable).
Special notes for PowerPC 32-Bit: Callbacks for System V (Linux/BSD) are unstable in this release; MacOS X/Darwin works fine.
In the context of R, dyncallback has currently no support for callbacks on MIPS, SPARC and PowerPC 64-Bit.
Using dyncallback to implement non-default calling conventions is not supported yet. (e.g. Window Procedures on Win32/X86).
}
\note{
The call signature \strong{MUST} match the foreign C callback function type, otherwise an activated callback call from C can lead to a \strong{fatal R process crash}.

A small amount of memory is allocated with each wrapper. 
A finalizer function that frees the allocated memory is registered at the external pointer.
If the external callback function pointer is registered in a C library, a reference should also be held in R as long as the callback can be activated from a foreign C run-time context, 
otherwise the garbage collector might call the finalizer and the next invocation of the callback could lead to a \strong{fatal R process crash} as well.
}

\references{
  Adler, D. (2012) \dQuote{Foreign Library Interface}, \emph{The R Journal}, \bold{4(1)}, 30--40, June 2012.
  \url{https://journal.r-project.org/articles/RJ-2012-004/}
  
  Adler, D., Philipp, T. (2008) \emph{DynCall Project}. 
  \url{https://dyncall.org}
}
\seealso{
See \code{\link{signature}} for details on call signatures,
\code{\link{reg.finalizer}} for details on finalizers.
}
\examples{
\donttest{
# Create a function, wrap it to a callback and call it via dyncall:
f <- function(x,y) x+y
cb <- new.callback("ii)i", f)
r <- dyncall(cb, "ii)i", 20, 3)

# Sort vectors directly via 'qsort' C library function using an R callback:
dynbind(c("msvcrt","c","c.so.6"), "qsort(piip)v;")
cb <- new.callback("pp)i",function(px,py){  
  x <- .unpack(px, 0, "d")
  y <- .unpack(py, 0, "d")
  if (x >  y) return(1) else if (x == y) return(0) else return(-1)
})
x <- rnorm(100)
qsort(x,length(x),8,cb)
}
}
\keyword{programming}
\keyword{interface}
