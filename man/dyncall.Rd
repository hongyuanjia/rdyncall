\name{dyncall}
\alias{dyncall}
\alias{dyncall}
\alias{dyncall.default}
\alias{dyncall.cdecl}
\alias{dyncall.stdcall}
\alias{dyncall.thiscall}
\alias{dyncall.thiscall.msvc}
\alias{dyncall.thiscall.gcc}
\alias{dyncall.fastcall.msvc}
\alias{dyncall.fastcall.gcc}
\alias{signature}
\alias{call signature}
\alias{type signature}
\title{Foreign Function Interface with support for almost all C types}
\description{  
Functions to call pre-compiled code with support for most C argument and return types. 
}
\usage{
dyncall( address, signature, ... , callmode = "default" )
dyncall.default      ( address, signature, ... )
dyncall.cdecl        ( address, signature, ... )
dyncall.stdcall      ( address, signature, ... )
dyncall.thiscall     ( address, signature, ... )
dyncall.thiscall.msvc( address, signature, ... )
dyncall.thiscall.gcc ( address, signature, ... )
dyncall.fastcall.msvc( address, signature, ... )
dyncall.fastcall.gcc ( address, signature, ... )
}
\arguments{
  \item{address}{external pointer to foreign function.}
  \item{signature}{character string specifying the \emph{call signature} that describes the foreign function type. See details.}
  \item{callmode}{character string specifying the \emph{calling convention}. This argument has no effect on most platforms, but on Microsoft Windows 32-Bit Intel/x86 platforms. See details.}
  \item{...}{arguments to be passed to the foreign function. Arguments are converted from R to C values according to the \emph{call signature}. See details.}
}
\details{
\code{dyncall} offers a flexible Foreign Function Interface (FFI) for
the C language with support for calls to arbitrary pre-compiled 
C function types at run-time. Almost all C fundamental 
argument- and return types are supported including  extended support for
pointers. No limitations is given for arity as well.
In addition, on the Microsoft Windows 32-Bit Intel/x86 platform, it supports multiple calling conventions to
interoperate with System DLLs.
Foreign C function types are specified via plain text \emph{type signatures}. 
The foreign C function type of the target function is known to the FFI
in advance, before preparation of the foreign call via plain text
\emph{type signature} information.
This has several advantages: R arguments do not need to match exactly. 
Although R lacks some fundamental C value types, they are supported via
coercion at this interface (e.g. C \code{float} and 64-bit integer).
Arity and argument type checks help make this interface type-safe
to a certain degree and encourage end-users to use interface from
the interpreter prompt for rapid application development.

The foreign function to be called is specified by \code{address}, which is an external pointer that is obtained from \code{\link{dynsym}} or \code{\link{getNativeSymbolInfo}}. 

\code{signature} is a character string that specifies the formal argument-and-return types of the 
foreign function using a \emph{call signature} string. It should match the function type of the foreign function given by \code{address},
otherwise this can lead to a \strong{fatal R process crash}.

The calling convention is specified \emph{explicitly} via function \code{dyncall}
using the \code{callmode} argument or \emph{implicitly} by using \code{.dyncall.*} 
functions. See details below.

Arguments passed via \code{...} are converted to C according to \code{signature} ; see below for details.

Given that the \code{signature} matches the foreign function type, the FFI provides a certain level of type-safety to users, when
exposing foreign functions via call wrappers such as done in \code{\link{dynbind}} and \code{\link{dynport}}.
Several basic argument type-safety checks are done during preparation of the foreign function call: 
The arity of formals and actual arguments must match and they must be compatible as well.
Otherwise, the foreign function call is aborted with an error before risking a fatal system crash.
}
\value{  
Functions return the received C return value converted to an R value. See section \sQuote{Call Signature} below for details.
}
\section{Type Signature}{
Type signatures are used by almost all other signature formats (call, library, structure and union signature) and also by the low-level (un)-\code{\link{packing}} functions.

The following table gives a list of valid type signatures for all supported C types. 

\tabular{clll}{
\strong{Type Signature}                \tab \strong{C type}            \tab \strong{valid R argument types}          \tab \strong{R return type}\cr
'\code{B}'                             \tab bool                       \tab raw,logical,integer,double               \tab logical\cr
'\code{c}'                             \tab char                       \tab raw,logical,integer,double               \tab integer\cr
'\code{C}'                             \tab unsigned char              \tab raw,logical,integer,double               \tab integer\cr
'\code{s}'                             \tab short                      \tab raw,logical,integer,double               \tab integer\cr
'\code{S}'                             \tab unsigned short             \tab raw,logical,integer,double               \tab integer\cr
'\code{i}'                             \tab int                        \tab raw,logical,integer,double               \tab integer\cr
'\code{I}'                             \tab unsigned int               \tab raw,logical,integer,double               \tab double\cr
'\code{j}'                             \tab long                       \tab raw,logical,integer,double               \tab double\cr
'\code{J}'                             \tab unsigned long              \tab raw,logical,integer,double               \tab double\cr
'\code{l}'                             \tab long long                  \tab raw,logical,integer,double               \tab double\cr
'\code{L}'                             \tab unsigned long long         \tab raw,logical,integer,double               \tab double\cr
'\code{f}'                             \tab float                      \tab raw,logical,integer,double               \tab double\cr
'\code{d}'                             \tab double                     \tab raw,logical,integer,double               \tab double\cr
'\code{p}'                             \tab \emph{C pointer}           \tab \emph{any vector},externalptr,NULL       \tab externalptr\cr
'\code{Z}'                             \tab char*                      \tab character,NULL                           \tab character or NULL\cr
'\code{x}'                             \tab SEXP                       \tab \emph{any}                               \tab \emph{any}\cr
'\code{v}'                             \tab void                       \tab \emph{invalid}                           \tab NULL\cr
'\code{*}' \ldots                      \tab \emph{C type}* (pointer)   \tab \emph{any vector},externalptr,NULL       \tab externalptr\cr
"\code{*<}" \emph{typename} '\code{>}' \tab \emph{typename}* (pointer) \tab raw,externalptr                          \tab externalptr\cr
}

The last two rows of the table the above refer to \emph{typed pointer} signatures.
If they appear as a return type signature, the external pointer returned is 
a S3 \code{struct} object. See \code{\link{cdata}} for details.  

}
\section{Call Signatures}{
Call Signatures are used by \code{\link{dyncall}} and \code{\link{ccallback}} to describe foreign C function types.
The general form of a call signature is as following:

\tabular{lll}{
(\emph{argument-type})* \tab \code{')'} \tab \emph{return-type} \cr
}

The calling sequence given by the \bold{argument types signature} is specified in direct \emph{left-to-right} order of the formal argument types defined in C.
The type signatures are put in sequence without any white space in between.
A closing bracket character '\code{)}' marks the end of argument types, followed by a
single \bold{return type signature}. 

Derived pointer types can be specified as untyped pointers via \code{'p'}
or via prefix \code{'*'} following the underlying base type (e.g. \code{'*d'} for \code{double *})
which is more type-safe. For example, this can prevent users from passing a \code{numeric} R atomic as \code{int*} if using \code{'*i'} instead of \code{'p'}.

Dervied pointer types to aggregate \code{union} or \code{struct} types are
supported in combination with the framework for handling foreign data types. 
See \code{\link{cdata}} for details. Once a C type is registered,
the signature \code{*<}\emph{typename}\code{>} can be used to refer to a pointer to an aggregate C object \emph{type}\code{*}.
If typed pointers to aggregate objects are used as a return type and the corresponding type information exists, the returned value can be printed and accessed symbolically.

Here are some examples of C function prototypes and corresponding call signatures:

\tabular{rll}{
                    \tab \emph{C Function Prototype}               \tab \emph{Call Signature} \cr
\code{double}       \tab \code{sqrt(double);}                      \tab \code{"d)d"}    \cr
\code{double}       \tab \code{dnorm(double,double,double,int);}   \tab \code{"dddi)d"} \cr
\code{void}         \tab \code{R_isort(int*,int);}                 \tab \code{"pi)v"}   or \code{"*ii)v"} \cr
\code{void}         \tab \code{revsort(double*,int*,int);}         \tab \code{"ppi)v"}  or \code{"*d*ii)v"}\cr
\code{int}          \tab \code{SDL_PollEvents(SDL_Event *);}       \tab \code{"p)i"}    or \code{"*<SDL_Event>)i"} \cr
\code{SDL_Surface*} \tab \code{SDL_SetVideoMode(int,int,int,int);} \tab \code{"iiii)p"} or \code{"iiii)*<SDL_Surface>"} \cr
}

}

\section{Calling convention}{
Calling Conventions specify \sQuote{how} sub-routine calls are performed, and, \sQuote{how} arguments and results are passed, 
on machine-level. They differ significantly among families of CPU Architectures 
as well as OS and Compiler implementations.

On most platforms, a single \code{"default"} C Calling Convention is used.
As an exception, on the Microsoft Windows 32-Bit Intel/x86 platform several calling conventions are common.
Most of the C libraries still use a \code{"default"} C ( also known as \code{"cdecl"} )
calling convention, but when working with Microsoft System APIs and DLLs, the \code{"stdcall"}
calling convention must be used. 

It follows a description of supported Win32 Calling Conventions:

\describe{
\item{\code{"cdecl"}}{Dummy alias to \emph{default}}
\item{\code{"stdcall"}}{C functions with \emph{stdcall} calling convention. Useful for all Microsoft Windows System Libraries (e.g. KERNEL32.DLL, USER32.DLL, OPENGL32.DLL ...). Third-party libraries usually prefer the default C \emph{cdecl} calling convention. }
\item{\code{"fastcall.msvc"}}{C functions with \emph{fastcall} calling convention compiled with Microsoft Visual C++ Compiler. Very rare usage.}
\item{\code{"fastcall.gcc"}}{C functions with \emph{fastcall} calling convention compiled with GNU C Compiler. Very rare usage.}
\item{\code{"thiscall"}}{C++ member functions.}
\item{\code{"thiscall.gcc"}}{C++ member functions compiled with GNU C Compiler.}
\item{\code{"thiscall.msvc"}}{C++ member functions compiled with Microsoft Visual C++ Compiler.}
}

As of the current version of this package and for practical reasons, the \code{callmode} argument does not have an effect on almost
all platforms, except that if R is running on Microsoft Windows 32-Bit Intel/x86 platform, \code{dyncall} uses the specified calling convention.
For example, when loading OpenGL across platforms, \code{"stdcall"} should be used instead of \code{"default"}, 
because on Windows, OpenGL is a System DLL. This is very exceptional, as in most other cases, \code{"default"} (or \code{"cdecl"}, the alias) need to be used
for normal C shared libraries on Windows.

At this stage of development, support for C++ calls should be considered experimental.
Support for Fortran is planed but not yet implemented in dyncall.
}
\section{Portability}{
The implementation is based on the \emph{dyncall} library (part of the DynCall project).

The following processor architectures are supported: X86 32- and 64-bit, ARM v4t-v7 oabi/eabi (aapcs) and armhf including support for Thumb ISA, PowerPC 32-bit, MIPS 32- and 64-Bit, SPARC 32- and 64-bit; The library
has been built and tested to work on various OSs: Linux, Mac OS X, Windows 32/64-bit, BSDs, Haiku, Nexenta/Open Solaris, Solaris, Minix and Plan9,
as well as embedded platforms such as Linux/ARM (OpenMoko, Beagleboard, Gumstix, Efika MX, Raspberry Pi), Nintendo DS (ARM), Sony Playstation Portable (MIPS 32-bit/eabi) and iOS (ARM - armv6 mode ok, armv7 unstable).
In the context of R, dyncall has currently no support for PowerPC 64-Bit.
}
\note{
The target address, calling convention and call signature \strong{MUST} match foreign function type, otherwise the invocation could lead to a \strong{fatal R process crash}.
}
\examples{
\donttest{
mathlib <- dynfind(c("msvcrt","m","m.so.6"))
x <- dynsym(mathlib,"sqrt")
dyncall(x, "d)d", 144L)
}
}
\references{
  Adler, D. (2012) \dQuote{Foreign Library Interface}, \emph{The R Journal}, \bold{4(1)}, 30--40, June 2012.
  \url{https://journal.r-project.org/articles/RJ-2012-004/}
  
  Adler, D., Philipp, T. (2008) \emph{DynCall Project}. 
  \url{https://dyncall.org}
}
\seealso{
\code{\link{dynsym}} and \code{\link[base]{getNativeSymbolInfo}} for resolving symbols,
\code{\link{dynbind}} for binding several foreign functions via thin call wrappers,
\code{\link[base]{.C}} for the traditional FFI to C.
}
\keyword{programming}
\keyword{interface}
