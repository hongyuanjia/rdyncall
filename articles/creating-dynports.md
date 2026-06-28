# Creating DynPort files with porter

`rdyncall` loads DynPort metadata; it does not parse C headers by
itself. [porter](https://github.com/hongyuanjia/porter) is the companion
tool used to turn C headers into DCF `.dynport` files that
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
can load.

Use this article when you want to create a DynPort file for a C library
that you use. SDL3 appears here only as a concrete example because
rdyncall ships one maintained SDL3 DynPort file.

## Workflow overview

The generation boundary is:

1.  Install or locate the C library headers and the runtime library.
2.  Write a small umbrella header that includes the public header you
    want to bind.
3.  Run [porter](https://github.com/hongyuanjia/porter) with the include
    paths and parse boundary for that library.
4.  Set DynPort metadata such as `Package`, `Version`, and `Library`.
5.  Write a DCF `.dynport` file and review the generated diff.
6.  Let rdyncall load that file with
    [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md).

Only step 6 happens at rdyncall runtime. Header parsing and metadata
generation are development-time steps.

## Choose the inputs

Before running [porter](https://github.com/hongyuanjia/porter), decide
these inputs for the library you want to bind:

| Input                      | Purpose                                                                                                             | Example for SDL3           |
|:---------------------------|:--------------------------------------------------------------------------------------------------------------------|:---------------------------|
| Umbrella header            | Keeps the parsed API surface explicit                                                                               | `#include <SDL3/SDL.h>`    |
| Include flags              | Lets the parser find library headers                                                                                | `-I/path/to/include`       |
| Parse boundary             | Avoids accidentally binding unrelated dependency headers                                                            | `/path/to/include/SDL3`    |
| DynPort package name       | Names the generated R package                                                                                       | `SDL3`                     |
| Runtime library candidates | Names that [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md) can resolve on target systems | `SDL3`, `SDL3-0`, `SDL3-3` |

Small umbrella headers usually make better DynPort files than asking the
parser to follow every header installed on the system.

## Generate a DynPort file

The exact include path depends on how the target library is installed.
This script shows the pattern with SDL3 as the example:

``` r
library(porter)

sdl3_header <- "/path/to/include/SDL3/SDL.h"
sdl3_include <- dirname(dirname(sdl3_header))

umbrella <- tempfile(fileext = ".h")
writeLines("#include <SDL3/SDL.h>", umbrella)

sdl3 <- port(
    umbrella,
    limit = dirname(sdl3_header),
    cflags = paste0("-I", sdl3_include)
)

sdl3 <- port_set(
    sdl3,
    Package = "SDL3",
    Version = "3.4.10",
    Library = c("SDL3", "SDL3-0", "SDL3-3")
)

port_write(sdl3, "inst/dynports/SDL3.dynport")
```

For another library, replace the header path, umbrella include,
`Package`, `Version`, and `Library` values with the values for that
library.

Keep generated output reviewed in git. A changed header,
[porter](https://github.com/hongyuanjia/porter) release, or upstream
library version can legitimately change function, constant, enum, and
aggregate metadata.

## Inspect an existing DynPort file

The installed rdyncall package contains one bundled DynPort file for
SDL3:

``` r
sdl3_portfile <- system.file("dynports", "SDL3.dynport",
                            package = "rdyncall", mustWork = TRUE)
basename(sdl3_portfile)
#> [1] "SDL3.dynport"
```

The file is plain text DCF metadata. The header shows the package
identity and library candidates:

``` r
head(readLines(sdl3_portfile), 12L)
#>  [1] "Package: SDL3"                          
#>  [2] "Version: 3.4.10"                        
#>  [3] "Library:"                               
#>  [4] "    SDL3"                               
#>  [5] "    SDL3-0"                             
#>  [6] "    SDL3-3"                             
#>  [7] "Constant:"                              
#>  [8] "    SDL_PLATFORM_APPLE=1"               
#>  [9] "    SDL_PLATFORM_MACOS=1"               
#> [10] "    SDL_MIN_UINT64=0"                   
#> [11] "    SDL_PRILL_PREFIX=\"ll\""            
#> [12] "    SDL_INVALID_UNICODE_CODEPOINT=65533"
```

The `Library` entries are candidates, not a guarantee that SDL3 is
installed on the current machine.
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
resolves them when loading the generated package.

## Validate on the rdyncall side

After generating a file, validate the rdyncall side separately from the
header-generation step:

``` r
portfile <- "inst/dynports/YourLibrary.dynport"
lib <- tempfile("rdyncall-dynport-lib")

generated <- dynport(portfile = portfile, package = "dyn.YourLibraryCheck",
                     lib = lib, rebuild = TRUE, quiet = TRUE)
generated
```

If the target library is installed, call a non-GUI scalar function
first. For SDL3, `SDL_GetPlatform()` is a good smoke test because it
does not open a window or start an event loop.

## What belongs where

| Concern                                | Home                                                                       |
|:---------------------------------------|:---------------------------------------------------------------------------|
| Header parsing and metadata generation | [porter](https://github.com/hongyuanjia/porter)                            |
| Reviewed DCF file                      | Your package or `inst/dynports/*.dynport`                                  |
| Loading generated packages             | [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md) |
| Real function calls                    | generated package wrappers                                                 |
| GUI demos and event loops              | separate demos or articles                                                 |

The rdyncall package intentionally keeps the bundled DynPort surface
small. SDL3 is the maintained example. Additional libraries should be
generated from their current headers rather than copied from historical
DynPort files.

## Next steps

- Use [dynbind and DynPort
  bindings](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.md)
  for the rdyncall loading layer.
- Use [Non-GUI
  demos](https://hongyuanjia.github.io/rdyncall/articles/non-gui-demos.md)
  for examples that can run without opening a window.
- Use
  [troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.md)
  when a generated DynPort package cannot find its library or reports
  unresolved symbols.
