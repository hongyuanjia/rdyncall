# SDL3 non-GUI probing

SDL3 is a practical external-library target because it is cross-platform
and has both simple query functions and more complex GUI/event APIs.
This article stays on the safe side: it loads the bundled SDL3 DynPort
and calls only non-GUI query functions.

Use this article when you want to validate the generated SDL3 package in
pkgdown or CI without opening a window, initializing video, or entering
an event loop.

## External execution switch

Local article builds skip SDL3 calls by default. To force the probe,
set:

``` r
Sys.setenv(RDYNCALL_ARTICLE_EXTERNAL = "true")
```

The pkgdown workflow sets this variable and installs SDL3, so the
external chunks run in CI. If the variable is true but SDL3 cannot be
found, the helper fails early instead of silently skipping the probe.

``` r
sdl3_names <- c("SDL3", "SDL3-0", "SDL3-3")
article_library_available(sdl3_names)
#> [1] TRUE
```

## Generate and load the package

[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
reads the bundled DCF file, generates a small R package in a temporary
library, and loads that package into the current session.

``` r
portfile <- system.file("dynports", "SDL3.dynport",
                        package = "rdyncall", mustWork = TRUE)
lib <- tempfile("rdyncall-sdl3-lib")

generated <- dynport(portfile = portfile, package = "dyn.SDL3Probe",
                     lib = lib, rebuild = TRUE, quiet = TRUE)
generated
#> [1] "dyn.SDL3Probe"
```

The generated package name is explicit so repeated article builds do not
depend on a previously generated default package.

## Call non-GUI SDL3 functions

The following calls query process and platform information. They do not
open windows or run an event loop.

``` r
sdl3_platform <- getExportedValue(generated, "SDL_GetPlatform")()
sdl3_revision <- getExportedValue(generated, "SDL_GetRevision")()
sdl3_version <- getExportedValue(generated, "SDL_GetVersion")()
sdl3_cpus <- getExportedValue(generated, "SDL_GetNumLogicalCPUCores")()

list(
    platform = sdl3_platform,
    revision = sdl3_revision,
    version = sdl3_version,
    logical_cpus = sdl3_cpus
)
#> $platform
#> [1] "Linux"
#> 
#> $revision
#> [1] "SDL-release-3.4.10-0-g8e37db5e7"
#> 
#> $version
#> [1] 3004010
#> 
#> $logical_cpus
#> [1] 4
```

This is a useful smoke test for the full stack: DynPort metadata,
generated R package, library discovery, symbol resolution, signatures,
and one real foreign call.

## Why not open a window here?

Window creation and event loops are valuable demos, but they add
platform, display-server, and lifecycle concerns that do not belong in a
first generated binding smoke test. Keep those examples separate so CI
can validate the binding without GUI state.

## Next steps

- Use [Creating DynPort files with
  porter](https://hongyuanjia.github.io/rdyncall/articles/creating-dynports.md)
  to regenerate the bundled metadata from SDL3 headers or create a
  DynPort file for another library.
- Use [dynbind and DynPort
  bindings](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.md)
  to understand how generated packages relate to hand-written wrappers.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  before binding SDL3 APIs that store function pointers.
- Use [FFI
  safety](https://hongyuanjia.github.io/rdyncall/articles/ffi-safety.md)
  before moving from query functions to GUI, audio, or event-loop APIs.
