\name{struct}
\alias{struct}
\alias{new.struct}
\alias{as.struct}
\alias{parseStructInfos}
\alias{parseUnionInfos}
\alias{$.struct}
\alias{print.struct}
\alias{$<-.struct}
\title{Allocation and handling of foreign C aggregate data types}
\description{Functions for allocation, access and registration of foreign C \code{struct} and \code{union} data type.}
\usage{
new.struct(type)
as.struct(x, type)
parseStructInfos(sigs, envir=parent.frame())
parseUnionInfos(sigs, envir=parent.frame())
\S3method{$}{struct}(x, index)
\S3method{$}{struct}(x, index) <- value
\S3method{print}{struct}(x, indent=0, \ldots)
}
\arguments{
  \item{x}{external pointer or atomic raw vector of S3 class 'struct'.}
  \item{type}{S3 \link{TypeInfo} Object or character string that names the structure type.}
  \item{sigs}{character string that specifies several C struct/union type \link{signature}s.}
  \item{envir}{the environment to install S3 type information object(s).} 
  \item{index}{character string specifying the field name.}
  \item{indent}{indentation level for pretty printing structures.}
  \item{value}{value to be converted according to struct/union field type given by field index.}
  \item{...}{additional arguments to be passed to \code{\link[base]{print}} method.}
}
\details{
References to foreign C data objects are represented by objects of class 'struct'.

Two reference types are supported:

\itemize{
  \item \emph{External pointers} returned by \code{\link{.dyncall}} using a call signature with a \emph{typed pointer} return type signature 
  and pointers extracted as a result of \code{\link{.unpack}} and S3 \code{struct} \code{$}-operators.
  \item \emph{Internal objects}, memory-managed by R, are allocated by \code{new.struct}:
An atomic \code{raw} storage object is returned, initialized with length equal to the byte size of the
foreign C data type.
}
 
In order to access and manipulate the data fields of foreign C aggregate data objects, the \dQuote{$} and \dQuote{$<-} S3 operator methods
can be used.

S3 objects of class \code{struct} have an attribute \code{struct} set to the name of a \code{\link{TypeInfo}} object, which provides the 
run-time type information of a particular foreign C type.

The run-time type information for foreign C \code{struct} and \code{union} types need to be registered once via 
\code{parseStructInfos} and \code{parseUnionInfos} functions.
The C data types are specified by \code{sigs}, a signature character string. The formats for both types are described next:

\strong{Structure type signatures} describe the layout of aggregate \code{struct} C data types.
Type Signatures are used within the \sQuote{field-types}. \sQuote{field-names} consists of space separated identifier names and
should match the number of fields.

\tabular{c}{
\emph{struct-name} '\code{\{}' \emph{field-types} '\code{\}}' \emph{field-names} '\code{;}' \cr
}

Here is an example of a C \code{struct} type:

\preformatted{
struct Rect \{ 
  signed short x, y; 
  unsigned short w, h;
\};
}

The corresponding structure type signature is:

\preformatted{"Rect\{ssSS\}x y w h;"}

\strong{Union type signatures} describe the components of the \code{union} C data type.
Type signatures are used within the \sQuote{field-types}. \sQuote{field-names} consists of space separated identifier names and
should match the number of fields.

\tabular{c}{
\emph{union-name} '\code{|}' \emph{field-types} '\code{\}}' \emph{field-names} '\code{;}' \cr
}

Here is an example of a C \code{union} type,

\preformatted{
union Value \{ 
  int anInt; 
  float aFloat; 
  struct LongValue aStruct
\};
} 

The corresponding union type signature is:

\code{"Value|if<LongValue>}anInt aFloat aStruct;"}

\code{as.struct} can be used to \emph{cast} a foreign C data reference to a different type. 
When using an external pointer reference, this can lead quickly to a \strong{fatal R process crash} - like in C.
}
\seealso{
\code{\link{.dyncall}} for type signatures and \code{\link{TypeInfo}} for details on run-time type information S3 objects.
}
\examples{
# Specify the following foreign type:
# struct Rect {
#   short x, y;
#   unsigned short w, h;
# }
parseStructInfos("Rect{ssSS}x y w h;")
r <- new.struct(Rect)
print(r)
r$x <- 40
r$y <- 60
r$w <- 10
r$h <- 15
print(r)
str(r)
}
\keyword{programming}
\keyword{interface}
