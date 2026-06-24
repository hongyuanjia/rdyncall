# Improved Foreign Function Interface and Dynamic Bindings to C Libraries

`rdyncall` provides a low-level Foreign Function Interface (FFI) for
loading shared C libraries, resolving symbols, calling C functions from
R by signature, working with C `struct` and `union` data, and exposing R
functions as C callback pointers.

## Details

The package is intended for developers who know the C API they want to
call and need an exploratory or dynamic binding layer from R without
writing a compiled wrapper for every function.

Shared libraries can be opened directly with
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
or located by short names with
[`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
Function addresses are resolved with
[`dynsym()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
and called with
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
using compact type signatures.
[`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
supports C functions declared with `...` when the call-site vararg
signature is supplied explicitly.

C aggregate data can be described with
[`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
and
[`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
and accessed through raw-backed
[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
objects. The aggregate layout support includes ordinary struct and union
fields, fixed-size array fields, integer bitfields, packed layouts,
manual alignment directives and by-value aggregate calls on supported
DynCall backends. Aggregate by-value callback arguments and returns are
currently unsupported.

R functions can be wrapped as C function pointers with
[`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md).
Keep an R reference to callback objects for as long as foreign code may
call them.

[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
builds and loads generated R packages from DCF `.dynport` binding
specifications. The package ships an SDL3 DynPort generated from current
headers with porter; other libraries can be bound by generating and
loading additional `.dynport` files.

## Overview

- Load libraries and inspect symbols with
  [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md),
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md),
  [`dynsym()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
  and
  [`dynlist()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md).

- Call C functions with
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  and
  [`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).

- Create batches of thin wrappers with
  [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md).

- Describe and access C aggregates with
  [`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md),
  [`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
  and
  [`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md).

- Read and write low-level values with
  [`pack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)
  and
  [`unpack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md).

- Wrap R functions as C callbacks with
  [`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md).

- Generate packages from DCF DynPort specifications with
  [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md).

## Getting Started

Several demos range from simple FFI calls to C standard library
functions to callback, GLPK, libxml2, SDL3 and raylib examples. See
`demo(package = "rdyncall")` for an overview. Some demos require shared
C libraries to be installed on the system or open GUI windows.

## Safety

This is a low-level FFI. A wrong function address, call signature,
calling convention, pointer lifetime or struct layout can crash the R
process. Keep the C declaration beside the R signature when writing
bindings.

## References

Adler, D. (2012) "Foreign Library Interface", *The R Journal*, **4(1)**
, 30–40, June 2012.
<https://journal.r-project.org/articles/RJ-2012-004/>

Adler, D., Philipp, T. (2008) *DynCall Project*. <https://dyncall.org>

## See also

Useful links:

- <https://github.com/hongyuanjia/rdyncall>

- <https://dyncall.org>

- Report bugs at <https://github.com/hongyuanjia/rdyncall/issues>

## Author

**Maintainer**: Hongyuan Jia <hongyuanjia@cqust.edu.cn> \[copyright
holder\]

Authors:

- Daniel Adler <dadler@uni-goettingen.de> \[copyright holder\]

## Examples

``` r
# \donttest{
mathlib <- dynfind(c("msvcrt", "m", "m.so.6"))
sqrt_addr <- dynsym(mathlib, "sqrt")
dyncall(sqrt_addr, "d)d", 144)
#> [1] 12

cb <- ccallback("ii)i", function(x, y) x + y)
dyncall(cb, "ii)i", 20L, 3L)
#> [1] 23
# }
```
