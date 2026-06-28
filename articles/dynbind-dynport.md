# dynbind and DynPort bindings

Direct
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
calls are useful for one-off experiments. Larger bindings usually need
names, wrappers, constants, types, and repeatable loading. That is where
[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
and
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
fit.

Use this article when you already know several function signatures and
want to move beyond address-by-address calls. It shows when to keep a
small binding in an environment with
[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md),
and when to put binding metadata in a DynPort file so
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
can generate and load an R package.

The three layers have different jobs:

| Layer                                                                      | Input                                          | Output                       | Best use                             |
|:---------------------------------------------------------------------------|:-----------------------------------------------|:-----------------------------|:-------------------------------------|
| [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md) | a function pointer and one call signature      | one foreign call             | probes and one-off calls             |
| [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md) | library candidates and hand-written signatures | R wrappers in an environment | small, explicit bindings             |
| [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md) | a DCF `.dynport` file                          | a generated R package        | repeatable bindings from metadata    |
| [porter](https://github.com/hongyuanjia/porter)                            | C headers                                      | a `.dynport` file            | generating metadata outside rdyncall |

[porter](https://github.com/hongyuanjia/porter) is not required at run
time by rdyncall. It is the tool used to generate DynPort files from
headers before
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
loads those files.

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

`rdyncall` intentionally does not bundle a broad catalog of old DynPort
files. The supported in-package example is SDL3. For other libraries,
generate a fresh DCF file for the headers and library version you want
to bind.

For other C libraries, generate a `.dynport` file with
[porter](https://github.com/hongyuanjia/porter) and pass it to
`dynport(portfile = ...)`. A regeneration script for SDL3 follows this
shape once the SDL3 header directory is known:

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
- Use [porter](https://github.com/hongyuanjia/porter) when the metadata
  should come from C headers rather than from hand-written signatures.

All three layers use the same underlying signatures, so start by getting
the C declarations and signatures correct.

## Next steps

- Use
  [signatures](https://hongyuanjia.github.io/rdyncall/articles/signatures.md)
  before writing library signatures or DynPort `Function` entries.
- Use [Creating DynPort files with
  porter](https://hongyuanjia.github.io/rdyncall/articles/creating-dynports.md)
  for the header-to-DynPort workflow, including the SDL3 example that
  produces the bundled DynPort file.
- Use [Non-GUI
  demos](https://hongyuanjia.github.io/rdyncall/articles/non-gui-demos.md)
  for examples that run without opening windows.
- Use
  [troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.md)
  when generated packages fail to find a library, resolve a symbol, or
  load into the current session.
