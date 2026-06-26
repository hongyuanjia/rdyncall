# Dynamic R Bindings to standard and common C libraries

Functions to turn DCF DynPort files into generated R packages that
provide wrappers for C functions, object-like macros, enums and data
types.

## Usage

``` r
dynport(
  portname,
  portfile = NULL,
  repo = system.file("dynports", package = "rdyncall"),
  package = NULL,
  lib = dynport_lib(),
  rebuild = FALSE,
  load = TRUE,
  quiet = FALSE
)

dynport_install_package(
  portname,
  portfile = NULL,
  repo = system.file("dynports", package = "rdyncall"),
  package = NULL,
  lib = dynport_lib(),
  rebuild = FALSE,
  load = FALSE,
  quiet = FALSE
)

dynport_load_into(portfile, envir)

dynport_lib(create = TRUE, add = FALSE)

dynport_clear_lib(lib = dynport_lib(create = FALSE), unload = TRUE)
```

## Arguments

- portname:

  the name of a dynport, given as a literal or character string.

- portfile:

  `NULL` or character string giving a DCF `.dynport` file to parse.

- repo:

  character string giving the path to the root of the `dynport`
  repository.

- package:

  `NULL` or character string giving the generated R package name. When
  `NULL`, the `Package` field from the DynPort file is prefixed by
  option `rdyncall.dynport.package.prefix`.

- lib:

  character string giving the R library path where the generated package
  is installed. Defaults to `dynport_lib()`.

- rebuild:

  logical. If `TRUE`, reinstall an existing generated package when the
  DynPort file contents have changed.

- load:

  logical. If `TRUE`, load and attach the generated package in the
  current R session after installation.

- quiet:

  logical. If `TRUE`, suppress installation and loading output where
  possible.

- envir:

  environment to populate from a DynPort file.

- create:

  logical. If `TRUE`, create the default DynPort package library when it
  does not exist.

- add:

  logical. If `TRUE`, prepend the DynPort package library to
  [`.libPaths()`](https://rdrr.io/r/base/libPaths.html).

- unload:

  logical. If `TRUE`, unload generated DynPort packages from the current
  session before removing them from `lib`.

## Value

`dynport()` invisibly returns the generated package name.
`dynport_install_package()` invisibly returns the installed package path
with the generated package name stored in attribute `"package"`.
`dynport_load_into()` invisibly returns `envir`. `dynport_lib()` returns
the DynPort package library path. `dynport_clear_lib()` invisibly
returns the paths it removed.

## Details

`dynport()` offers a convenient method for binding entire C libraries to
R. This mechanism runs cross-platform and uses dynamic linkage but it
implies that the run-time library of a chosen binding need to be
pre-installed in the system. Depending on the OS, the run-time libraries
may be pre-installed or require manual installation. See
[rdyncall-demos](https://hongyuanjia.github.io/rdyncall/reference/rdyncall-demos.md)
for OS-specific installation notes for several C libraries.

The binding method is data-driven using platform-portable specifications
named *DynPort* files. The current implementation supports DCF (Debian
Control File) `.dynport` files.

When `dynport()` processes a *DynPort* file, it generates and installs a
real R package whose namespace is populated at load time from the
DynPort metadata. By default, generated package names use the prefix
given by option `rdyncall.dynport.package.prefix`, which defaults to
`"dyn."`. For example, a DynPort with `Package: SDL3` is installed as
`dyn.SDL3` unless a package name is explicitly supplied.

The package ships the following current-format DCF *DynPort*:

|                            |                            |
|----------------------------|----------------------------|
| **DynPort name/C library** | **Description**            |
| `SDL3`                     | Simple DirectMedia Layer 3 |

The DCF format records the following binding metadata:

- Functions (and pointer-to-function variables) are mapped via
  [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
  and a description of the C library using a *library signatures*.

- Symbolic names are assigned to its values for object-like macro
  defines and C enum types.

- Run-time type-information objects for aggregate C data types (struct
  and union) are registered via
  [`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
  and
  [`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md).

The file path to the *DynPort* file is derived from `portname` per
default. This would refer to `"<repo>/<portname>.dynport"` where `repo`
defaults to the package's `"dynports/"` sub-folder. If `portfile` is
given, then this value is taken as file path.

The bundled SDL3 DynPort is generated from SDL3 headers with porter. For
other libraries, generate a DCF `.dynport` file externally and pass it
with `portfile`.

## References

Adler, D. (2012) “Foreign Library Interface”, *The R Journal*, **4(1)**,
30–40, June 2012. <https://journal.r-project.org/articles/RJ-2012-004/>

Adler, D., Philipp, T. (2008) *DynCall Project*. <https://dyncall.org>

Latinga, S. (1998). The Simple DirectMedia Layer Library.
<https://www.libsdl.org/>

## Author

Daniel Adler <dadler@uni-goettingen.de>

## Examples

``` r
if (FALSE) { # \dontrun{
dynport(SDL3)
dyn.SDL3::SDL_GetPlatform()
} # }
```
