# Changelog

## rdyncall 0.10.0

- Restore package compilation on current R toolchains
  ([\#19](https://github.com/hongyuanjia/rdyncall/issues/19)).
- Update the bundled dyncall source and stop tracking generated static
  libraries ([\#19](https://github.com/hongyuanjia/rdyncall/issues/19)).
- Replace deprecated/internal R C API usage with public accessors where
  possible ([\#19](https://github.com/hongyuanjia/rdyncall/issues/19)).
- Support
  [`dynlist()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
  for macOS dyld shared cache libraries
  ([\#20](https://github.com/hongyuanjia/rdyncall/issues/20)).
- Generate real on-disk R packages from DCF DynPort files via
  [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
  ([\#28](https://github.com/hongyuanjia/rdyncall/issues/28)).
- Improve generated DynPort packages with argument-preserving wrappers,
  variadic function metadata, generated help pages and a cleanup helper
  for the managed DynPort library
  ([\#52](https://github.com/hongyuanjia/rdyncall/issues/52)).
- Keep DynPort parsing isolated from already attached generated packages
  so rebuilding or rerunning a generated package in the same R session
  remains repeatable
  ([\#55](https://github.com/hongyuanjia/rdyncall/issues/55)).
- Support `Constant` and `Variadic` fields in DCF DynPort files,
  including binding variadic entries through
  [`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  ([\#53](https://github.com/hongyuanjia/rdyncall/issues/53)).
- Add
  [`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  for calling C variadic functions with explicit call-site vararg
  signatures
  ([\#35](https://github.com/hongyuanjia/rdyncall/issues/35)).
- Allow
  [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
  to accept direct library paths and existing external pointer handles
  in addition to short library names
  ([\#29](https://github.com/hongyuanjia/rdyncall/issues/29)).
- Improve
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
  discovery for libraries installed by common package managers,
  including Homebrew, MacPorts, Linuxbrew and Scoop
  ([\#31](https://github.com/hongyuanjia/rdyncall/issues/31)).
- Improve
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
  discovery of the current R runtime library and avoid treating
  same-named directories as direct
  [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
  library paths
  ([\#39](https://github.com/hongyuanjia/rdyncall/issues/39)).
- Add
  [`dynfind_explain()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
  diagnostics for shared-library discovery and expand Windows library
  discovery coverage
  ([\#48](https://github.com/hongyuanjia/rdyncall/issues/48)).
- Return nested aggregate fields from `$` as raw-backed `struct` objects
  so they can be reused for field access and aggregate by-value calls
  ([\#33](https://github.com/hongyuanjia/rdyncall/issues/33)).
- Fix
  [`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
  and
  [`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
  field parsing when whitespace follows the type signature
  ([\#21](https://github.com/hongyuanjia/rdyncall/issues/21)).
- Store aggregate field names in the explicit `typeinfo$fields$name`
  column ([\#21](https://github.com/hongyuanjia/rdyncall/issues/21)).
- Add dedicated print methods for `typeinfo`, `struct`, `ctype`,
  `dynbind.report` and `floatraw` objects
  ([\#41](https://github.com/hongyuanjia/rdyncall/issues/41)).
- Add
  [`callback_status()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md),
  [`callback_is_active()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
  and
  [`callback_last_error()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
  for inspecting rdyncall callback invocation and error state
  ([\#49](https://github.com/hongyuanjia/rdyncall/issues/49)).
- Add by-value aggregate argument and return support to
  [`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
  for the implemented x86_64 and ARM64 dyncallback backends
  ([\#50](https://github.com/hongyuanjia/rdyncall/issues/50)).
- Add `struct` and `union` bitfield layout, access, DynPort parsing, and
  by-value aggregate support
  ([\#26](https://github.com/hongyuanjia/rdyncall/issues/26)).
- Add the `rdyncall.callvm.size` option to configure CallVM argument
  stack size at package load
  ([\#22](https://github.com/hongyuanjia/rdyncall/issues/22)).
- Add by-value aggregate argument and return support to
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  for registered `struct` and `union` types on supported dyncall
  backends, including ARM64 aggregate ABI handling
  ([\#23](https://github.com/hongyuanjia/rdyncall/issues/23)).
- Support fixed-size array fields in `struct` and `union` type
  signatures via the `type[N]` suffix
  ([\#26](https://github.com/hongyuanjia/rdyncall/issues/26)).
- Add `@packed`, `@pack(n)` and `@align(n)` layout directives for
  [`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md),
  [`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
  and DynPort aggregate definitions
  ([\#26](https://github.com/hongyuanjia/rdyncall/issues/26)).
- Refresh roxygen-generated documentation and package metadata for
  renewed development
  ([\#19](https://github.com/hongyuanjia/rdyncall/issues/19)).
- Generate `NAMESPACE` from roxygen2 metadata instead of maintaining it
  by hand ([\#40](https://github.com/hongyuanjia/rdyncall/issues/40)).
- Modernize GitHub Actions checks across Linux, macOS, and Windows, with
  an optional R-hub workflow for extended platform checks
  ([\#19](https://github.com/hongyuanjia/rdyncall/issues/19)).

## rdyncall 0.9

- Update: use the latest dyncall version.
- Improve dynamic library search for Windows.
- Update package refactoring per CRAN requirements.

## rdyncall 0.8

- Reimplement simplified version of
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
- Add dynport: pcap.
- Minor documentation update for SDL installation on Solaris/OpenCSW.
- Fix ARMv7 Thumb-2 ISA and SPARC-v7/v9, x86_64-x64 and mips-o32 ABIs.

## rdyncall 0.7.5

CRAN release: 2012-09-12

- Add support for new ARM ABI `armhf` (ARM hardfloat), tested on
  Raspberry Pi (armv6) and Efika MX Smartbook (armv7).
- Accept `NULL` for typed pointer arguments.
- Add support for `*v` (`void*`) return type signature in
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
- Add support for `**c` and external pointers to support
  `strptrarray()`.
- Change dynport containers from R namespaces to environment objects to
  remove `.Internal` calls and `::` operators on dynports; dynports are
  unloaded via `detach(dynport:<PORTNAME>)`.
- Improve finalizer management of callbacks.
- Add backward compatibility with R 2.10 for legacy Mac OS X
  10.4/PowerPC R port.
- Add dynports: csound, GLUT, glfw, EGL, glpk.
- Add demos: glpk, gles (partial work).

## rdyncall 0.7.4

- Update dyncall support for SPARC 32/64 and SunPro with fixes for SPARC
  64-bit.
- Add dynport SDL_net.
- Add public helper function `offsetPtr()`.
- Fix R 2.14 namespace handling and missing `lazyData` field in Env.

## rdyncall 0.7.3

- Fix Fedora/x64 by adding search path `lib64` folder for
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
- Add support for Sun make; DynCall uses `Makefile.embedded`.
- Add SPARC and SPARC64 support using GCC tool-chain.
- Add support for amd64 using Solaris tool-chain.
- Add vignette “foreign library interface”.
- Fix Solaris/x64 by adding search path `amd64` folder for
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
- Fix examples for libm using `m.so.6` besides `m` on Unix, needed by
  Debian 6 sid unstable.

## rdyncall 0.7.2

- Add win64/mingw64 support.

## rdyncall 0.7.1

- Minor `Makevars` fix for parallel builds.

## rdyncall 0.7.0

- First upload to CRAN.
