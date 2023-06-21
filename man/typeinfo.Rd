\name{typeinfo}
\alias{typeinfo}
\alias{get_typeinfo}
\alias{type information}
\title{S3 class for run-time type information of foreign C data types}
\description{S3 class for run-time type information of foreign C data types.}
\usage{
typeinfo(name, type = c("base","pointer","struct","union"),
    size = NA, align = NA, basetype = NA, fields = NA,
    signature = NA)
get_typeinfo(name, envir = parent.frame())
}
\arguments{
    \item{name}{character string specifying the type name.}
    \item{type}{character string specifying the type.}
    \item{size}{integer, size of type in bytes.}
    \item{align}{integer, alignment of type in bytes.}
    \item{basetype}{character string, base type of 'pointer' types.}
    \item{signature}{character string specifying the struct/union type \link{signature}.}
    \item{envir}{the environment to look for type object.}
    \item{fields}{data frame with type and offset information that specifies aggregate struct and union types.}
}
\details{
Type information objects are created at run-time to describe the concrete layout
of foreign C data types on the host machine. While \link{type signature}s give
an abstract information on e.g. the field types and names of aggregate structure
types, these objects store concrete memory size, alignment and layout
information about C data types.
}
\value{
    List object tagged as S3 class 'typeinfo' with the following named entries
    \item{type}{Type name.}
    \item{size}{Size in bytes.}
    \item{align}{Alignment in bytes.}
    \item{fields}{Data frame for field information with the following columns:
        \tabular{ll}{
            \code{type} \tab type name\cr
            \code{offset} \tab byte offset (starts counted from 0)\cr
        }
}
}
\seealso{
    \code{\link{cstruct}} for details on the framework for handling foreign C
    data types.
}
