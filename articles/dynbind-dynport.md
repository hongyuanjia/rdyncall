# dynbind and DynPort bindings

Direct
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
calls are useful for one-off experiments. Larger bindings usually need
names, wrappers, constants, types, and repeatable loading. That is where
[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
and
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
fit.

## Bind a small function set

[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
takes a library name or handle and a library signature. It installs thin
R wrappers in an environment.

``` r
math_names <- c("msvcrt", "m", "m.so.6")
math <- new.env(parent = globalenv())
info <- dynbind(
    math_names,
    paste(
        "sqrt(d)d",
        "cos(d)d",
        "sin(d)d",
        sep = ";"
    ),
    envir = math
)

c(
    sqrt = math$sqrt(49),
    cos = math$cos(0),
    sin = math$sin(pi / 2)
)
#> sqrt  cos  sin 
#>    7    1    1
```

The generated wrapper still calls the resolved C function through
rdyncall. The wrapper just hides the address and signature from the
user-facing call.

## Inspect unresolved symbols

The return value reports the library handle and unresolved symbols. This
makes it possible to fail early when a platform lacks a function you
require.

``` r
str(info$unresolved.symbols)
#>  chr(0)
```

For exploratory bindings, unresolved optional symbols can be reported to
the user. For required bindings, fail before exposing partially working
wrappers.

## Library discovery

Character library names that look like file paths are loaded directly.
Other character values are resolved with
[`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).

``` r
libc_names <- c("msvcrt", "c", "c.so.6")
libc_handle <- dynfind(libc_names)
is.nullptr(libc_handle)
#> [1] FALSE
```

Use a vector of candidate names for cross-platform bindings. For
example, Windows may use `msvcrt`, while Unix-like systems commonly
expose C runtime symbols through `c` or `c.so.6`.

## From bindings to generated packages

[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
reads a DCF `.dynport` file and generates a real R package in an
rdyncall-managed library. The generated package namespace is populated
from the metadata in the DynPort file.

The default DynPort library is:

``` r
dynport_lib()
#> [1] "/home/runner/.cache/R/rdyncall/dynports/R-4.6.1"
```

Generated package names use the option
`rdyncall.dynport.package.prefix`, whose default value is `"dyn."`, plus
the `Package` field in the DynPort file.

## DynPort file shape

A minimal DynPort file records the package name, library candidates,
function bindings, and optionally constants and aggregate types.

``` text
Package: SDL3
Version: 3.4.10
Library:
    SDL3
    SDL3-0
    SDL3-3
Function:
    SDL_GetPlatform()Z;
```

The package ships one current-format DynPort file:
`inst/dynports/SDL3.dynport`. It is generated from SDL3 headers with
[porter](https://github.com/hongyuanjia/porter) and kept in the package
as a realistic, non-toy binding example.

For other C libraries, generate a `.dynport` file with porter and pass
it to `dynport(portfile = ...)`. A regeneration script for SDL3 follows
this shape once the SDL3 header directory is known:

``` r
library(porter)

sdl3_header <- "/path/to/include/SDL3/SDL.h"
sdl3_include <- dirname(dirname(sdl3_header))

header <- tempfile(fileext = ".h")
writeLines("#include <SDL3/SDL.h>", header)

sdl3 <- port(header,
    limit = dirname(sdl3_header),
    cflags = paste0("-I", sdl3_include)
)
sdl3 <- port_set(sdl3,
    Package = "SDL3",
    Version = "3.4.10",
    Library = c("SDL3", "SDL3-0", "SDL3-3")
)

port_write(sdl3, "inst/dynports/SDL3.dynport")
```

## A non-GUI SDL3 probe

When `RDYNCALL_ARTICLE_EXTERNAL=true` and SDL3 is available, this
article builds and loads a generated package from the bundled DynPort,
then calls a non-GUI platform query. The chunk does not open a window or
enter an event loop.

``` r
sdl3_names <- c("SDL3", "SDL3-0", "SDL3-3")
```

During normal local rendering, `RDYNCALL_ARTICLE_EXTERNAL` can stay
unset or `false`; the SDL3 code is shown but skipped. The pkgdown
workflow sets it to `true`, installs SDL3 system libraries, and
therefore executes this non-GUI probe in CI.

``` r
Sys.setenv(RDYNCALL_ARTICLE_EXTERNAL = "true")
```

``` r
portfile <- system.file("dynports", "SDL3.dynport",
                        package = "rdyncall", mustWork = TRUE)
lib <- tempfile("rdyncall-dynport-lib")

generated <- dynport(portfile = portfile, package = "dyn.SDL3Article",
                     lib = lib, rebuild = TRUE, quiet = TRUE)
generated
#> [1] "dyn.SDL3Article"

getExportedValue(generated, "SDL_GetPlatform")()
#> [1] "Linux"
```

If SDL3 is not installed, the code remains visible in the article but is
skipped unless external article execution is explicitly requested.

## When to choose each layer

- Use
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  for a single function address or a small experiment.
- Use
  [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
  when you know a small set of functions and want ordinary R wrappers in
  one environment.
- Use
  [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
  when the binding metadata should live in a data file and load as a
  generated R package.

All three layers use the same underlying signatures, so start by getting
the C declarations and signatures correct.
