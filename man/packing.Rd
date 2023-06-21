\name{packing}
\alias{pack}
\alias{packing}
\alias{unpack}
\title{Handling of foreign C fundamental data types}
\description{Functions to unpack/pack (read/write) foreign C data types from/to
    R atomic vectors and C data objects such as arrays and pointers to
    structures.
}
\usage{
pack(x, offset, sigchar, value)
unpack(x, offset, sigchar)
}
\arguments{
    \item{x}{atomic vector (logical, raw, integer or double) or external pointer.}
    \item{offset}{integer specifying \emph{byte offset} starting at 0.} 
    \item{sigchar}{character string specifying the C data type by a \link{type signature}.}
    \item{value}{R object value to be coerced and packed to a foreign C data type.} 
}
\details{
    The function \code{pack} converts an R \code{value} into a C data type
    specified by the \link{signature} \code{sigchar} and it writes the raw C
    foreign data value at byte position \code{offset} into the object \code{x}.
    The function \code{.unpack} extracts a C data type according to the
    \link{signature} \code{sigchar} at byte position \code{offset} from the
    object \code{x} and converts the C value to an R value and returns it.

    Byte \code{offset} calculations start at 0 relative to the first byte in an
    atomic vectors data area.

    If \code{x} is an atomic vector, a bound check is carried out before
    read/write access. Otherwise, if \code{x} is an external pointer, there is
    only a C NULL pointer check.
}
\value{
    \code{unpack} returns a read C data type coerced to an R value.
}
\seealso{
    \code{\link{dyncall}} for details on type signatures.
}
\examples{
# transfer double to array of floats and back, compare precision:
n <- 6
input <- rnorm(n)
buf <- raw(n*4)
for (i in 1:n) {
    pack(buf, 4 * (i - 1), "f", input[i])
}

output <- numeric(n)
for (i in 1:n) {
    output[i] <- unpack(buf, 4 * (i - 1), "f")
}
# difference between double and float
difference <- output - input
print(cbind(input, output, difference))
}
