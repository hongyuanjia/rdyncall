
# rdyncall <img src="man/figures/logo.svg" alt="rdyncall logo" align="right" height="138" />

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

The pkgdown articles are the main documentation path:

- Start with [Getting
  started](https://hongyuanjia.github.io/rdyncall/articles/rdyncall.html)
  and [Signatures for C
  calls](https://hongyuanjia.github.io/rdyncall/articles/signatures.html).
- Continue with [Structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.html)
  and [Callbacks from C to
  R](https://hongyuanjia.github.io/rdyncall/articles/callbacks.html).
- Build larger bindings with [dynbind and DynPort
  bindings](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.html),
  [Creating DynPort
  files](https://hongyuanjia.github.io/rdyncall/articles/creating-dynports.html),
  and [SDL3 non-GUI
  probing](https://hongyuanjia.github.io/rdyncall/articles/sdl3-non-gui.html).
- Use
  [Troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.html)
  and [FFI safety
  boundaries](https://hongyuanjia.github.io/rdyncall/articles/ffi-safety.html)
  before binding ownership-sensitive, callback-heavy, or
  platform-specific APIs.

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

## Generated Bindings

`rdyncall` can model ordinary C `struct` and `union` layouts and
supports several layout features needed by real C APIs:

- fixed-size array fields, written as `type[N]`, such as `C[4]`;
- integer bitfields, written in the field-name list, such as `flags:3`;
- packed and aligned layouts via `@packed`, `@pack(n)` and `@align(n)`;
- nested aggregate fields and by-value aggregate calls on supported
  DynCall backends.

For callbacks, `ccallback()` supports aggregate by-value arguments and
returns on the implemented x86_64 and ARM64 dyncallback backends.

## DynPort Bindings

`dynport()` is the package-level mechanism for binding a C API from a
data file. The current implementation supports DCF `.dynport` files and
generates ordinary on-disk R packages whose namespace is populated from
the DynPort metadata.

The package ships one maintained DynPort example,
`inst/dynports/SDL3.dynport`, generated from SDL3 headers with
[`porter`](https://github.com/hongyuanjia/porter). See the
generated-binding articles for how to create DynPort metadata for a C
library, load it with `dynport()`, and run a non-GUI SDL3 smoke test.

To generate an unprefixed SDL3 binding package and open a minimal SDL3
window, pass an explicit package name and call the generated wrappers
through `SDL3::`:

``` r
library(rdyncall)

dynport(SDL3, package = "SDL3", rebuild = TRUE, quiet = FALSE)

window <- NULL
renderer <- NULL
on.exit({
  if (!is.null(renderer) && !is.nullptr(renderer)) {
    SDL3::SDL_DestroyRenderer(renderer)
  }
  if (!is.null(window) && !is.nullptr(window)) {
    SDL3::SDL_DestroyWindow(window)
  }
  SDL3::SDL_Quit()
}, add = TRUE)

if (!SDL3::SDL_Init(SDL3::SDL_INIT_VIDEO)) {
  stop("SDL_Init failed: ", SDL3::SDL_GetError(), call. = FALSE)
}

window <- SDL3::SDL_CreateWindow("rdyncall SDL3 minimal window", 640L, 360L, 0)
renderer <- SDL3::SDL_CreateRenderer(window, "software")

SDL3::SDL_SetRenderDrawColor(renderer, 24L, 28L, 36L, 255L)
SDL3::SDL_RenderClear(renderer)
SDL3::SDL_SetRenderDrawColor(renderer, 255L, 255L, 255L, 255L)
SDL3::SDL_RenderDebugText(renderer, 40, 40, "Hello from rdyncall!")
SDL3::SDL_RenderPresent(renderer)

until <- Sys.time() + 2
while (Sys.time() < until) {
  SDL3::SDL_PumpEvents()
  SDL3::SDL_Delay(16L)
}
```

<img src="man/figures/sdl3-demo.svg" alt="Terminal recording of an SDL3 DynPort package opening a window from rdyncall" width="100%" />

For a compact 3D example, raylib can be bound directly with `dynbind()`
and aggregate by-value arguments:

``` r
library(rdyncall)
source(system.file("demo-support", "raylib.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

cstruct("Color{CCCC}r g b a;")
cstruct("Vector3{fff}x y z;")
cstruct("Camera3D{ffffffffffi}position_x position_y position_z target_x target_y target_z up_x up_y up_z fovy projection;")

ray <- new.env(parent = globalenv())
dynbind(
  find_raylib(),
  paste(
    "InitWindow(iiZ)v",
    "CloseWindow()v",
    "BeginDrawing()v",
    "EndDrawing()v",
    "ClearBackground(<Color>)v",
    "BeginMode3D(<Camera3D>)v",
    "EndMode3D()v",
    "DrawCube(<Vector3>fff<Color>)v",
    "DrawCubeWires(<Vector3>fff<Color>)v",
    "DrawGrid(if)v",
    sep = ";"
  ),
  envir = ray
)
```

The recording source in `tools/asciicast/raylib-3d.R` opens a raylib
window, draws an orbiting camera view of a cube and grid, and closes it
cleanly.

<img src="man/figures/raylib-3d-demo.svg" alt="Terminal recording of a raylib 3D cube example driven through rdyncall" width="100%" />

## Demos

<a href="https://hongyuanjia.github.io/rdyncall/articles/gui-demos.html">
<img src="https://github.com/hongyuanjia/rdyncall/releases/download/docs-media/rdyncall-sdl3-snake-poster.png" alt="rdyncall SDL3 Snake demo" width="720">
</a>

Run `demo(package = "rdyncall")` to list installed demos. The package
includes small examples for direct FFI calls, callbacks, `qsort`,
`stdio`, GLPK, libxml2, SDL3 and raylib.

Some demos require system shared libraries or open GUI windows.
Automated checks should prefer non-GUI examples or explicit probe modes
rather than entering an event loop.

See the [Non-GUI
demos](https://hongyuanjia.github.io/rdyncall/articles/non-gui-demos.html)
article for XML parsing, C sorting, GLPK optimization, and stdio
examples. The [GUI
demos](https://hongyuanjia.github.io/rdyncall/articles/gui-demos.html)
article shows SDL3 and raylib examples with media placeholders for
locally captured screenshots or videos.

## Safety

This is a low-level FFI. A wrong function address, call signature,
calling convention, pointer lifetime or struct layout can crash the R
process. Keep the C declaration beside the R signature when writing
bindings, and hold an R reference to callback objects for as long as
foreign code may call them. Read the [FFI safety
boundaries](https://hongyuanjia.github.io/rdyncall/articles/ffi-safety.html)
article before binding APIs that allocate memory, store pointers,
register callbacks, or run event loops.

## Project Status

This repository is the active maintenance branch for modern R. Recent
work has restored compilation on current toolchains, refreshed the
bundled DynCall source, modernized CI, added variadic calls, improved
dynamic library discovery, and expanded aggregate layout support.

## References

- Adler, D. (2012). “Foreign Library Interface”. *The R Journal*, 4(1),
  30-40. <https://journal.r-project.org/articles/RJ-2012-004/>
- DynCall Project: <https://dyncall.org>
