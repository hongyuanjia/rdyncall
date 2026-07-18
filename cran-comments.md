## Submission

This maintenance release addresses the BDR `valgrind` additional issue reported
for `rdyncall` 0.10.1.

Explicit `dynunload()` calls could previously be followed by an
`auto.unload` finalizer attempting to unload the same dynamic library handle
again. `C_dynunload()` now clears the external pointer after a successful
`dlFreeLibrary()` call and treats already-cleared `rdyncall` library handles as
no-ops.

A manual `R-hub` check on the `valgrind` platform passed for this release.

## R CMD check results

GitHub Actions `R-CMD-check` passed on:

* macOS arm64 release
* macOS Intel release
* Windows release
* Windows oldrel-4
* Ubuntu devel
* Ubuntu release
* Ubuntu oldrel-1
* Ubuntu oldrel-4

Additional GitHub Actions checks passed:

* ARM64 aggregate
* Sanitizers
* pkgdown

## Reverse dependencies

There are currently no downstream dependencies for this package.
