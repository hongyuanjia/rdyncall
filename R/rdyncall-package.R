#' Improved Foreign Function Interface and Dynamic Bindings to C Libraries
#'
#' @description
#' `rdyncall` provides a low-level Foreign Function Interface (FFI) for loading
#' shared C libraries, resolving symbols, calling C functions from R by
#' signature, working with C `struct` and `union` data, and exposing R functions
#' as C callback pointers.
#'
#' @details
#'
#' The package is intended for developers who know the C API they want to call
#' and need an exploratory or dynamic binding layer from R without writing a
#' compiled wrapper for every function.
#'
#' Shared libraries can be opened directly with [dynload()] or located by short
#' names with [dynfind()]. Function addresses are resolved with [dynsym()] and
#' called with [dyncall()] using compact type signatures. [dyncall_variadic()]
#' supports C functions declared with `...` when the call-site vararg signature
#' is supplied explicitly.
#'
#' C aggregate data can be described with [cstruct()] and [cunion()] and accessed
#' through raw-backed [cdata()] objects. The aggregate layout support includes
#' ordinary struct and union fields, fixed-size array fields, integer bitfields,
#' packed layouts, manual alignment directives and by-value aggregate calls on
#' supported DynCall backends. Aggregate by-value callback arguments and returns
#' are currently unsupported.
#'
#' R functions can be wrapped as C function pointers with [ccallback()]. Keep an
#' R reference to callback objects for as long as foreign code may call them.
#'
#' [dynport()] builds and loads generated R packages from DCF `.dynport` binding
#' specifications. The source tree also carries older `inst/dynports/*.R`
#' resources from previous rdyncall releases as legacy binding material.
#'
#' # Overview
#'
#' - Load libraries and inspect symbols with [dynload()], [dynfind()],
#'   [dynsym()] and [dynlist()].
#' - Call C functions with [dyncall()] and [dyncall_variadic()].
#' - Create batches of thin wrappers with [dynbind()].
#' - Describe and access C aggregates with [cstruct()], [cunion()] and [cdata()].
#' - Read and write low-level values with [pack()] and [unpack()].
#' - Wrap R functions as C callbacks with [ccallback()].
#' - Generate packages from DCF DynPort specifications with [dynport()].
#'
#' # Getting Started
#'
#' Several demos range from simple FFI calls to C standard library functions to
#' callback, GLPK, libxml2, SDL3 and raylib examples. See
#' `demo(package = "rdyncall")` for an overview. Some demos require shared C
#' libraries to be installed on the system or open GUI windows.
#'
#' # Safety
#'
#' This is a low-level FFI. A wrong function address, call signature, calling
#' convention, pointer lifetime or struct layout can crash the R process. Keep
#' the C declaration beside the R signature when writing bindings.

#' @references
#' Adler, D. (2012) "Foreign Library Interface", *The R Journal*,
#'   **4(1)** , 30--40, June 2012.
#'   \url{https://journal.r-project.org/articles/RJ-2012-004/}
#'
#'  Adler, D., Philipp, T. (2008) *DynCall Project*.
#'    \url{https://dyncall.org}
#'
#' @examples
#' \donttest{
#' mathlib <- dynfind(c("msvcrt", "m", "m.so.6"))
#' sqrt_addr <- dynsym(mathlib, "sqrt")
#' dyncall(sqrt_addr, "d)d", 144)
#'
#' cb <- ccallback("ii)i", function(x, y) x + y)
#' dyncall(cb, "ii)i", 20L, 3L)
#' }
#' @useDynLib rdyncall
#' @keywords internal
"_PACKAGE"
