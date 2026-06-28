# rdyncall 0.10.0

- Restore package compilation on current R toolchains (#19).
- Update the bundled dyncall source and stop tracking generated static libraries (#19).
- Replace deprecated/internal R C API usage with public accessors where possible (#19).
- Support `dynlist()` for macOS dyld shared cache libraries (#20).
- Generate real on-disk R packages from DCF DynPort files via `dynport()` (#28).
- Improve generated DynPort packages with argument-preserving wrappers,
  variadic function metadata, generated help pages and a cleanup helper for
  the managed DynPort library (#52).
- Keep DynPort parsing isolated from already attached generated packages so
  rebuilding or rerunning a generated package in the same R session remains
  repeatable (#55).
- Support `Constant` and `Variadic` fields in DCF DynPort files, including
  binding variadic entries through `dyncall_variadic()` (#53).
- Add `dyncall_variadic()` for calling C variadic functions with explicit
  call-site vararg signatures (#35).
- Allow `dynbind()` to accept direct library paths and existing external
  pointer handles in addition to short library names (#29).
- Improve `dynfind()` discovery for libraries installed by common package
  managers, including Homebrew, MacPorts, Linuxbrew and Scoop (#31).
- Improve `dynfind()` discovery of the current R runtime library and avoid
  treating same-named directories as direct `dynbind()` library paths (#39).
- Add `dynfind_explain()` diagnostics for shared-library discovery and expand
  Windows library discovery coverage (#48).
- Return nested aggregate fields from `$` as raw-backed `struct` objects so
  they can be reused for field access and aggregate by-value calls (#33).
- Fix `cstruct()` and `cunion()` field parsing when whitespace follows the type signature (#21).
- Store aggregate field names in the explicit `typeinfo$fields$name` column (#21).
- Fix DynPort union size calculation when known storage fields appear alongside
  opaque members, allowing `SDL_Event` values to be allocated from the generated
  SDL3 binding (#56).
- Add dedicated print methods for `typeinfo`, `struct`, `ctype`,
  `dynbind.report` and `floatraw` objects (#41).
- Add `callback_status()`, `callback_is_active()` and `callback_last_error()`
  for inspecting rdyncall callback invocation and error state (#49).
- Add by-value aggregate argument and return support to `ccallback()` for the
  implemented x86_64 and ARM64 dyncallback backends (#50).
- Add `struct` and `union` bitfield layout, access, DynPort parsing, and by-value aggregate support (#26).
- Add the `rdyncall.callvm.size` option to configure CallVM argument stack size at package load (#22).
- Add by-value aggregate argument and return support to `dyncall()` for registered `struct` and `union` types on supported dyncall backends, including ARM64 aggregate ABI handling (#23).
- Harden low-level argument validation for typed pointer signatures, packing
  helpers and pointer offsets (#59).
- Support fixed-size array fields in `struct` and `union` type signatures via the `type[N]` suffix (#26).
- Add `@packed`, `@pack(n)` and `@align(n)` layout directives for `cstruct()`, `cunion()` and DynPort aggregate definitions (#26).
- Refresh roxygen-generated documentation and package metadata for renewed development (#19).
- Generate `NAMESPACE` from roxygen2 metadata instead of maintaining it by hand (#40).
- Modernize GitHub Actions checks across Linux, macOS, and Windows, with an optional R-hub workflow for extended platform checks (#19).

# rdyncall 0.9

- Update: use the latest dyncall version.
- Improve dynamic library search for Windows.
- Update package refactoring per CRAN requirements.

# rdyncall 0.8

- Reimplement simplified version of `dynfind()`.
- Add dynport: pcap.
- Minor documentation update for SDL installation on Solaris/OpenCSW.
- Fix ARMv7 Thumb-2 ISA and SPARC-v7/v9, x86_64-x64 and mips-o32 ABIs.

# rdyncall 0.7.5

- Add support for new ARM ABI `armhf` (ARM hardfloat), tested on Raspberry Pi (armv6) and Efika MX Smartbook (armv7).
- Accept `NULL` for typed pointer arguments.
- Add support for `*v` (`void*`) return type signature in `dyncall()`.
- Add support for `**c` and external pointers to support `strptrarray()`.
- Change dynport containers from R namespaces to environment objects to remove `.Internal` calls and `::` operators on dynports; dynports are unloaded via `detach(dynport:<PORTNAME>)`.
- Improve finalizer management of callbacks.
- Add backward compatibility with R 2.10 for legacy Mac OS X 10.4/PowerPC R port.
- Add dynports: csound, GLUT, glfw, EGL, glpk.
- Add demos: glpk, gles (partial work).

# rdyncall 0.7.4

- Update dyncall support for SPARC 32/64 and SunPro with fixes for SPARC 64-bit.
- Add dynport SDL_net.
- Add public helper function `offsetPtr()`.
- Fix R 2.14 namespace handling and missing `lazyData` field in Env.

# rdyncall 0.7.3

- Fix Fedora/x64 by adding search path `lib64` folder for `dynfind()`.
- Add support for Sun make; DynCall uses `Makefile.embedded`.
- Add SPARC and SPARC64 support using GCC tool-chain.
- Add support for amd64 using Solaris tool-chain.
- Add vignette "foreign library interface".
- Fix Solaris/x64 by adding search path `amd64` folder for `dynfind()`.
- Fix examples for libm using `m.so.6` besides `m` on Unix, needed by Debian 6 sid unstable.

# rdyncall 0.7.2

- Add win64/mingw64 support.

# rdyncall 0.7.1

- Minor `Makevars` fix for parallel builds.

# rdyncall 0.7.0

- First upload to CRAN.
