# rdyncall 0.9.0.9000

- Restore package compilation on current R toolchains.
- Update the bundled dyncall source and stop tracking generated static libraries.
- Replace deprecated/internal R C API usage with public accessors where possible.
- Support `dynlist()` for macOS dyld shared cache libraries.
- Fix `cstruct()` and `cunion()` field parsing when whitespace follows the type signature.
- Store aggregate field names in the explicit `typeinfo$fields$name` column.
- Add the `rdyncall.callvm.size` option to configure CallVM argument stack size at package load.
- Refresh roxygen-generated documentation and package metadata for renewed development.
- Modernize GitHub Actions checks across Linux, macOS, and Windows, with an optional R-hub workflow for extended platform checks.

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
