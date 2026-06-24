# Portable searching and loading of shared libraries

Function to load shared libraries using a platform-portable interface.

## Usage

``` r
dynfind(libnames, auto.unload = TRUE)
```

## Arguments

- libnames:

  vector of character strings specifying several short library names.

- auto.unload:

  logical: if `TRUE` then a finalizer is registered that closes the
  library on garbage collection. See
  [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
  for details.

## Value

`dynfind()` returns an external pointer (library handle), if search was
successful. Otherwise, if no library is located, a `NULL` is returned.

## Details

`dynfind()` offers a platform-portable naming interface for loading a
specific shared library.

The naming scheme and standard locations of shared libraries are
OS-specific. When loading a shared library dynamically at run-time
across platforms via standard interfaces such as
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
or [`dyn.load()`](https://rdrr.io/r/base/dynload.html), a platform-test
is usually needed to specify the OS-dependant library file path.

This *library name problem* is encountered via breaking up the library
file path into several abstract components:

    <location> <prefix> <libname> <suffix>

By permutation of values in each component and concatenation, a list of
possible file paths can be derived. `dynfind()` goes through this list
to try opening a library. On the first success, the search is stopped
and the function returns.

Given that the three components `location`, `prefix` and `suffix` are
set up properly on a per OS basis, the unique identification of a
library is given by `libname` - the short library name.

For some libraries, multiple ‘short library name’ are needed to make
this mechanism work across all major platforms. For example, to load the
Standard C Library across major R platforms:

    lib <- dynfind(c("msvcrt", "c", "c.so.6"))

On Windows `MSVCRT.dll` would be loaded; `libc.dylib` on Mac OS X;
`libc.so.6` on Linux and `libc.so` on BSD.

Here is a sample list of values for the three other components:

- `location`::

  `/usr/local/lib/`, `C:/Windows/System32/`

- `prefix`::

  `lib` (common), empty - common on Windows

- `suffix`::

  `.dll` (Windows), `.so` (ELF), `.dylib` (macOS) and empty - useful for
  all platforms

The vector of `location`s is initialized by the dynamic linker search
rules, including environment variables such as `PATH` on Windows and
`LD_LIBRARY_PATH` on Unix-flavour systems. If the dynamic linker lookup
fails, `dynfind()` also checks library directories that belong to the
current R runtime, such as `R.home("lib")` and `R.home("bin")`, and
common package-manager library locations such as Homebrew
(`HOMEBREW_PREFIX`, `/opt/homebrew`, `/usr/local`), MacPorts
(`MACPORTS_PREFIX`, `/opt/local`), Linuxbrew
(`/home/linuxbrew/.linuxbrew`) and Scoop (`SCOOP`, `SCOOP_GLOBAL`,
`ProgramData/scoop`). (The set of hardcoded locations might expand and
change within the next minor releases).

The file extension depends on the OS: `.dll` (Windows), `.dylib`
(macOS), `.so` (all others).

On Mac OS X, the search for a library includes the ‘Frameworks’ folders
as well. This happens before the normal library search procedure and
uses a slightly different naming pattern in a separate search phase:

    <frameworksLocation> Frameworks/ <libname> .framework/ <libname>

The `frameworksLocation` is a vector of locations such as
`/System/Library/` and `/Library/`.

`dynfind()` loads a library via
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
passing over the parameter `auto.unload`.

## See also

See
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
for details on the loader interface to the OS-specific dynamic linker.
