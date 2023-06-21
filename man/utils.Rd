\name{utils}
\alias{is.nullptr}
\alias{as.externalptr}
\alias{is.externalptr}
\alias{floatraw}
\alias{as.floatraw}
\alias{floatraw2numeric}
\alias{ptr2str}
\alias{strarrayptr}
\alias{strptr}
\alias{offset_ptr}

\title{Utility functions for working with foreign C data types}
\description{Functions for low-level operations on C pointers as well as helper
    functions and objects to handle C \code{float} arrays and strings.}

\usage{
is.nullptr(x)

as.externalptr(x)
is.externalptr(x)

floatraw(n)
as.floatraw(x)
floatraw2numeric(x)

ptr2str(x)
strarrayptr(x)
strptr(x)

offset_ptr(x, offset)
}
\arguments{
    \item{x}{an R object.}
    \item{n}{number of elements to allocate.}
    \item{offset}{a offset given in bytes.}
}
\details{

    \code{is.nullptr} tests if the external pointer given by \code{x} represents
    a C \code{NULL} pointer.

    \code{as.externalptr} returns an external pointer to the data area of atomic
    vector given by \code{x}. The external pointer holds an additional reference
    to the \code{x} R object to prevent it from garbage collection.

    \code{is.externalptr} tests if the object given by \code{x} is an external
    pointer.

    \code{floatraw} creates an array with a capacity to store \code{n}
    single-precision C \code{float} values. The array is implemented via a
    \code{\link[base]{raw}} vector.

    \code{as.floatraw} coerces a numeric vector into a single-precision C
    \code{float} vector. Values given by \code{x} are converted to C \code{float}
    values and stored in the R raw vector via \code{pack}. This function is
    useful when calling foreign functions that expect a C \code{float} pointer
    via \code{\link{dyncall}}.

    \code{floatraw2numeric} coerces a C \code{float} (raw) vector to a numeric
    vector.

    \code{ptr2str}, \code{strarrayptr}, \code{strptr} are currently
    experimental.

    \code{offset_ptr} creates a new external pointer pointing to \code{x} plus
    the byte \code{offset}. If \code{x} is given as an external pointer, the
    address is increased by the \code{offset}, or, if \code{x} is given as a
    atomic vector, the address of the data (pointing to offset zero) is taken as
    basis and increased by the \code{offset}. The returned external pointer is
    protected (as offered by the C function \code{R_MakeExternalPtr}) by the
    external pointer \code{x}.
}
\value{
    A logical value is returned by \code{is.nullptr} and \code{is.externalptr}.
    \code{as.externalptr} and \code{offset_ptr} returns an external pointer
    value. \code{floatraw} and \code{as.floatraw} return an atomic vector of
    type \code{raw} tagged with class \code{'floatraw'}. \code{floatraw2numeric}
    returns a \code{numeric} atomic vector.
}
\examples{
is.nullptr(NULL)

one <- as.externalptr(1)
is.externalptr(one)

floatraw(1)

floats <- as.floatraw(1:10)
all.equal(floatraw2numeric(floats), 1:10)
}
\keyword{programming}
\keyword{interface}
