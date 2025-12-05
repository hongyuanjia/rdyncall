\name{dynbind}
\alias{dynbind}
\title{Binding C library functions via thin call wrappers}
\description{Function to bind several foreign functions of a C library via installation of thin R call wrappers.}
\usage{
dynbind(libnames, signature, envir = parent.frame(), callmode = "default",
        pattern = NULL, replace = NULL, funcptr = FALSE)
}
\arguments{
  \item{libnames}{vector of character strings giving short library names of the shared library to be loaded. See \code{\link{dynfind}} for details.}
  \item{signature}{character string specifying the \emph{library signature} that determines the set of foreign function names and types. See details.}
  \item{envir}{the environment to use for installation of call wrappers.}
  \item{callmode}{character string specifying the calling convention, see details.}
  \item{pattern}{NULL or regular expression character string applied to symbolic names.}
  \item{replace}{NULL or replacement character string applied to \code{pattern} part of symbolic names.}
  \item{funcptr}{logical, that indicates whether foreign objects refer to functions (\code{FALSE}, default) or to function pointer variables (\code{TRUE} rarely needed).}
}
\details{
\code{dynbind} makes a set of C functions available to R through installation of
thin call wrappers. The set of functions, including the symbolic name and
function type, is specified by \code{signature} ; a character string that
encodes a library signature:

The \strong{library signature} is a compact plain-text format to specify a set
of function bindings. It consists of function names and corresponding
\link[=call signature]{call signatures}. Function bindings are separated by
\sQuote{;} (semicolon) ; white spaces (including tab and new line) are allowed
before and after semicolon.

\tabular{c}{
\emph{function-name} \code{(} \emph{call-signature} \code{;} \ldots \cr
}

Here is an example that specifies three function bindings to the OpenGL library:
\preformatted{"glAccum(If)v ; glClear(I)v ; glClearColor(ffff)v ;"}

Symbolic names are resolved using the library specified by \code{libnames} using
\code{\link{dynfind}} for loading. For each function, a thin call wrapper
function is created using the following template:

\preformatted{ function(...) .dyncall.<MODE> ( <TARGET>, <SIGNATURE>, ... ) }

\code{<MODE>} is replaced by \code{callmode} argument, see \code{\link{dyncall}}
    for details on calling conventions.
\code{<TARGET>} is replaced by the external pointer, resolved by the
    \sQuote{function-name}.
\code{<SIGNATURE>} is replaced by the call signature string contained in
    \code{signature}.

The call wrapper is installed in the environment given by \code{envir}.
The assignment name is obtained from the function signature.
If \code{pattern} and \code{replace} is given, a text replacement is applied to the
name before assignment, useful for basic C name space mangling such as
exchanging the prefix.

As a special case, \code{dynbind} supports binding of pointer-to-function variables, indicated by setting \code{funcptr} to \code{TRUE}, in which case \code{<TARGET>}
is replaced with the expression \code{unpack(<TARGET>,"p",0)} in order to dereference \code{<TARGET>} as a pointer-to-function variable at call-time.
}

\value{
The function returns a list with two fields:
\item{libhandle}{External pointer returned by \code{\link{dynload}}.}
\item{unresolved.symbols}{vector of character strings, the names of unresolved symbols.}

As a side effect, for each wrapper, \code{dynbind} assigns the \sQuote{function-name} to  the corresponding call wrapper function in the environment given by \code{envir}.

If no shared library is found, an error is reported.
}
\examples{
\donttest{
# Install two wrappers to functions of the R shared C library.
info <- dynbind("R","
R_ShowMessage(Z)v;
R_rsort(pi)v;
")
R_ShowMessage("hello")
}
}
\seealso{
\code{\link{dyncall}} for details on call signatures and calling conventions,
\code{\link{dynfind}} for details on short library names,
\code{\link{unpack}} for details on reading low-level memory (e.g. dereferencing of (function) pointer variables).
}
\keyword{programming}
\keyword{interface}

