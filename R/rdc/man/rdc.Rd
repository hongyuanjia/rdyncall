\name{rdc}
\alias{rdcLoad}
\alias{rdcFree}
\alias{rdcFind}
\alias{rdcCall}
\alias{rdcPath}
\alias{rdcUnpath}
\alias{rdcShowPath}
\alias{rdcUnpack1}
\alias{rdcDataPtr}
\title{invoke dynamic calls to foreign code}
\description{  
Invoke foreign function calls with support for loading modules and resolving symbols.
}
\usage{
libhandle <- rdcLoad(libpath)
rdcFree(libhandle)
funcptr <- rdcFind(libhandle, symbol)
result  <- rdcCall(funcptr, signature, ...)
rdcPath(addpath)
rdcUnpath(delpath)
rdcShowPath()
rdcUnpack1(object, offset, sigchar)
rdcDataPtr(object, offset = 0)
}

\arguments{
  \item{libpath}{a file path to dynamic linked library(DLL).}
  \item{libhandle}{an external pointer representing an operating-system specific handle to an opened DLL.}
  \item{symbol}{a character string, specifying a function name symbol in a DLL.}
  \item{funcptr}{an external pointer representing a pointer to function resolved by a symbol}
  \item{signature}{a character string specifying the argument and return type of a function call, see Details below for more information.}
  \item{addpath,delpath}{a directory path from where dynamic linked libraries should be loaded.}
  \item{object}{An atomic object (scalar, vector, matrix or array).}
  \item{offset}{An integer specifying an offset from the start of the linear data memory in bytes.}
}

\details{
The rdc package provides tools to establish flexible function calls to low-level precompiled code.
It is more flexible than \code{\link{.C}} and has the same type-unsafety dangers.
One can make arbitrary C (and C++ member-) function calls.
The language binding was designed to help write glue code to low-level C libraries in R (if the target library function is compatible with
the supported typeset and calling convention).
It makes use of signature strings to specify 
the function prototyp to call. 
to providing a thin binding layer between the core
dyncall library and the R programming language.

The loading and unloading of code modules (*.DLL files on windows, *.dylib files on darwin and *.so files on other *nix flavour OSs)
is done using rdcLoad, similar to \code{\link{dyn.load}}. While \code{\link{dyn.load}} loads a DLL to the R run-time process,
rdcLoad returns the module handle as an external pointer.

Symbol lookup is done using \code{rdcFind} and returns an external pointer pointing to the foreign function.

The \code{rdcCall} function does invoke the function call.
It requires the \code{signature} character string argument, which consists of a series of type codes (given as ordinary characters) to
specify the argument types and the expected return type of the foreign function call which are separated by an ')' character.

\deqn{sigchar_{arg_0} sigchar_{arg_1} \ldots ')' sigchar_{return}}{<sigchar-arg0> <sigchar-arg1> \ldots ')' <sigchar-return>}

A signature character encodes the C type at the given argument position or return-type.

\tabular{cll}{
Signature char \tab C type           \tab accepted R data types\cr
\sQuote{B}     \tab \code{bool}      \tab coerced to logical vector, first item\cr
\sQuote{c}     \tab \code{char}      \tab not yet implemented\cr
\sQuote{s}     \tab \code{short}     \tab not yet implemented\cr
\sQuote{i}     \tab \code{int}       \tab coerced to integer vector, first item\cr
\sQuote{l}     \tab \code{long}      \tab not yet implemented\cr
\sQuote{f}     \tab \code{float}     \tab coerced to numeric, first item casted to float\cr
\sQuote{d}     \tab \code{double}    \tab coerced to numeric, first item\cr
\sQuote{L}     \tab \code{long long} \tab coerced to numeric, first item casted to long long\cr
\sQuote{p}     \tab \code{void*}     \tab external pointer or coerced to string vector, first item\cr
\sQuote{S}     \tab \code{char*}     \tab coerced to string vector, first item\cr
\sQuote{v}     \tab \code{void}      \tab no return type\cr
}

The order of the arguments is left-to-right according to the C prototyp function declaration. E.g.

e.g. the signature string of the function \samp{double foobar(int a, long long b, float c);} is \code{"iLf)d"}.

}
\examples{

# load platform-specific standard C DLL
 
clibname <- "libc"
if (.Platform$OS.type == "windows") clibname <- "msvcrt"
if (.Platform$OS.type == "darwin") clibname <- "libc.dylib"

clib <- rdcLoad(clibname)

# call sqrt function

sqrt.fp <- rdcFind(clib,"sqrt")
print( rdcCall(sqrt.fp, "d)d", 144) )

}
\references{
  Adler, D., Philipp, T. (2008) \emph{Dyncall Library}. 
  \url{http://dyncall.org}
}
\author {
  Daniel Adler \email{dadler@uni-goettingen}
}
\examples {
  # bla

}
\keyword{programming::interface}

