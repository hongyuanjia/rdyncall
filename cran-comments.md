## Resubmission

This maintenance release addresses the CRAN Debian check failure reported for
`rdyncall` 0.10.0, where package code run during checks attempted to write
compiled fixture object files into the read-only installed package library.

The compiled tinytest fixtures now copy their C sources to the R session
temporary directory before invoking `R CMD SHLIB`, so generated object and
shared-library files are written only under `tempdir()`.

The GitHub Actions `R-CMD-check` matrix was also adjusted so old R jobs install
only hard dependencies. `Rtinycc` remains an optional `Suggests` dependency and
is not required for the CRAN check fix.

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
