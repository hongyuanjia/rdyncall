\name{dynfind}
\alias{dynfind}
\title{Portable searching and loading of shared libraries}
\description{Function to load shared libraries using a platform-portable interface.}
\usage{
dynfind(libnames, auto.unload=TRUE)
}
\arguments{
  \item{libnames}{vector of character strings specifying several short library names.}
  \item{auto.unload}{logical: if \code{TRUE} then a finalizer is registered that closes the library on garbage collection. See \code{\link{dynload}} for details.}
}
\details{
\code{dynfind} offers a platform-portable naming interface for loading a specific shared library.

The naming scheme and standard locations of shared libraries are OS-specific.
When loading a shared library dynamically at run-time across platforms via standard interfaces such as \code{\link{dynload}} or \code{\link{dyn.load}}, 
a platform-test is usually needed to specify the OS-dependant library file path.

This \emph{library name problem} is encountered via breaking up the library file path into several abstract components:

\tabular{cccc}{
  \emph{<location>} \tab \emph{<prefix>} \tab \emph{<libname>} \tab \emph{<suffix>} \cr
}

By permutation of values in each component and concatenation, a list of possible file paths can be derived.
\code{dynfind} goes through this list to try opening a library. On the first success, the search is stopped and the function returns.

Given that the three components \sQuote{location}, \sQuote{prefix} and \sQuote{suffix} are set up properly on a per OS basis,
the unique identification of a library is given by \sQuote{libname} - the short library name.

For some libraries, multiple \sQuote{short library name} are needed to make this mechanism work across all major platforms.
For example, to load the Standard C Library across major R platforms:

\preformatted{
lib <- dynfind(c("msvcrt","c","c.so.6"))
}

On Windows \code{MSVCRT.dll} would be loaded; \code{libc.dylib} on Mac OS X; \code{libc.so.6} on Linux and \code{libc.so} on BSD.

Here is a sample list of values for the three other components:

\itemize{
  \item \sQuote{location}: \dQuote{/usr/local/lib/}, \dQuote{/Windows/System32/}.
  \item \sQuote{prefix}: \dQuote{lib} (common),  \dQuote{} (empty - common on Windows).
  \item \sQuote{suffix}: \dQuote{.dll} (Windows), \dQuote{.so} (ELF), \dQuote{.dylib} (Mac OS X) and \dQuote{} (empty - useful for all platforms).
}

The vector of \sQuote{locations} is initialized by environment variables such as '\code{PATH}' on Windows and 
\code{LD_LIBRARY_PATH} on Unix-flavour systems in additional to some hardcoded locations:
\file{/opt/local/lib}, 
\file{/usr/local/lib}, 
\file{/usr/lib} and 
\file{/lib}.
(The set of hardcoded locations might expand and change within the next minor releases).

The file extension depends on the OS: '\code{.dll}' (Windows), '\code{.dylib}' (Mac OS X), '\code{.so}' (all others).

On Mac OS X, the search for a library includes the \sQuote{Frameworks} folders as well. This happens before the normal library search procedure and uses a slightly different naming pattern
in a separate search phase:

\tabular{c}{
\emph{<frameworksLocation>} \bold{Frameworks/} \emph{<libname>} \bold{.framework/} \emph{<libname>}
}

The \sQuote{frameworksLocation} is a vector of locations such as \code{/System/Library/} and \code{/Library/}.

\code{dynfind} loads a library via \code{\link{dynload}} passing over the parameter \code{auto.unload}.

}
\value{
\code{dynfind} returns an external pointer (library handle), if search was successful.
Otherwise, if no library is located, a \code{NULL} is returned.
}
\seealso{
See \code{\link{dynload}} for details on the loader interface to the OS-specific dynamic linker.
}
\keyword{programming}
\keyword{interface}

