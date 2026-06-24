
# rdyncall

<!-- badges: start -->

[![R-CMD-check](https://github.com/hongyuanjia/rdyncall/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/hongyuanjia/rdyncall/actions/workflows/R-CMD-check.yaml)
<!-- badges: end -->

`rdyncall` provides an R interface to the [DynCall](https://dyncall.org)
libraries. It is a low-level Foreign Function Interface (FFI) for
loading shared C libraries, resolving symbols, calling C functions from
R by signature, working with C `struct` and `union` data, and exposing R
functions as C callback pointers.

The package is intended for developers who already know the C API they
want to call and need an exploratory or dynamic binding layer from R
without writing a compiled wrapper for every function.

## Installation

``` r
remotes::install_github("hongyuanjia/rdyncall")
```

`rdyncall` was previously archived on CRAN. This repository contains the
active modernization work toward a maintainable package and current R
toolchains.

## Quick Start

Call a C function directly by loading a library, resolving a symbol, and
providing a call signature:

``` r
library(rdyncall)

mathlib <- dynfind(c("msvcrt", "m", "m.so.6"))
sqrt_addr <- dynsym(mathlib, "sqrt")

dyncall(sqrt_addr, "d)d", 144)
```

The signature `"d)d"` means one C `double` argument and a C `double`
return value. Signatures must match the target C function type.

R functions can also be wrapped as C callback pointers:

``` r
add <- ccallback("ii)i", function(x, y) x + y)
dyncall(add, "ii)i", 20L, 3L)
```

Foreign aggregate layouts are described once and then used through
raw-backed objects:

``` r
cstruct("Rect{ssSS}x y w h;")

rect <- cdata(Rect)
rect$x <- 40
rect$y <- 60
rect$w <- 10
rect$h <- 15

rect$w
```

## Learn rdyncall

The pkgdown articles are organized as a short learning path:

- [Getting
  started](https://hongyuanjia.github.io/rdyncall/articles/rdyncall.html)
  introduces the basic load-resolve-call workflow.
- [Signatures for C
  calls](https://hongyuanjia.github.io/rdyncall/articles/signatures.html)
  shows how to translate C declarations into rdyncall signatures.
- [Structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.html)
  covers raw buffers, aggregate layouts, bitfields, and packed/aligned
  data.
- [Callbacks from C to
  R](https://hongyuanjia.github.io/rdyncall/articles/callbacks.html)
  explains callback pointers and lifetime rules.
- [dynbind and DynPort
  bindings](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.html)
  shows how to move from one-off calls to generated binding packages.

## API Map

- `dynload()`, `dynunload()`, `dynsym()`, `dynpath()`, `dyncount()` and
  `dynlist()` load shared libraries and inspect symbols.
- `dynfind()` resolves common short library names across platforms and
  package manager locations.
- `dyncall()` and `dyncall_variadic()` call C functions using compact
  type signatures.
- `dynbind()` creates thin R wrappers for a group of C functions.
- `cstruct()`, `cunion()`, `cdata()` and `as.ctype()` describe and
  access C aggregate data.
- `pack()` and `unpack()` read and write low-level C values in raw
  vectors or memory referenced by external pointers.
- `ccallback()` turns an R function into a C function pointer.
- `dynport()` builds and loads generated R packages from DCF `.dynport`
  binding specifications.

## Structs, Unions and Memory

`rdyncall` can model ordinary C `struct` and `union` layouts and
supports several layout features needed by real C APIs:

- fixed-size array fields, written as `type[N]`, such as `C[4]`;
- integer bitfields, written in the field-name list, such as `flags:3`;
- packed and aligned layouts via `@packed`, `@pack(n)` and `@align(n)`;
- nested aggregate fields and by-value aggregate calls on supported
  DynCall backends.

Callback signatures currently do not support aggregate by-value
arguments or returns.

## DynPort Bindings

`dynport()` is the package-level mechanism for binding a C API from a
data file. The current implementation supports DCF `.dynport` files and
generates ordinary on-disk R packages whose namespace is populated from
the DynPort metadata.

The package ships one current-format DynPort,
`inst/dynports/SDL3.dynport`, generated from SDL3 headers with
[`porter`](https://github.com/hongyuanjia/porter):

``` r
dynport(SDL3)
dyn.SDL3::SDL_GetPlatform()
```

For other C libraries, generate a DCF `.dynport` file with porter or
another header-processing workflow and pass it to
`dynport(portfile = ...)`.

## Demos

Run `demo(package = "rdyncall")` to list installed demos. The package
includes small examples for direct FFI calls, callbacks, `qsort`,
`stdio`, GLPK, libxml2, SDL3 and raylib.

Some demos require system shared libraries or open GUI windows.
Automated checks should prefer non-GUI examples or explicit probe modes
rather than entering an event loop.

## Safety

This is a low-level FFI. A wrong function address, call signature,
calling convention, pointer lifetime or struct layout can crash the R
process. Keep the C declaration beside the R signature when writing
bindings, and hold an R reference to callback objects for as long as
foreign code may call them.

## Project Status

This repository is the active maintenance branch for modern R. Recent
work has restored compilation on current toolchains, refreshed the
bundled DynCall source, modernized CI, added variadic calls, improved
dynamic library discovery, and expanded aggregate layout support.

## References

- Adler, D. (2012). “Foreign Library Interface”. *The R Journal*, 4(1),
  30-40. <https://journal.r-project.org/articles/RJ-2012-004/>
- DynCall Project: <https://dyncall.org>
