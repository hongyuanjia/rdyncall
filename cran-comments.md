## CRAN archive status

This is a restored submission of `rdyncall`, which was orphaned and archived
on CRAN on 2014-09-20 because vignette locations were not updated for R 3.1.0.

The package no longer ships CRAN vignettes. The old Foreign Library Interface
vignette material is kept only as excluded legacy source material under
`tools/legacy-vignettes/`.

Maintenance is taken over by Hongyuan Jia. The CRAN repository database still
records the archived package as `Maintainer: ORPHANED`, so the incoming check
reports the expected maintainer conflict for this restored submission.

## License

The package uses `MIT + file LICENSE`. Historical rdyncall license notices and
vendored DynCall license notices are preserved in `inst/COPYRIGHTS`.

## R CMD check results

0 errors | 1 warning | 2 notes

The remaining warning is local-tooling related:

* `checkbashisms` is not installed on the local macOS check machine.

The remaining notes are:

* CRAN incoming flags this as a new submission of an archived package, reports
  the archived `Maintainer: ORPHANED` metadata conflict, and reports the
  archived package status.
* HTML validation was skipped because the local `tidy` executable is not new
  enough for R's HTML check.

URL checks pass with `urlchecker::url_check()`.

## External checks

macbuilder `r-release-macosx-arm64` passed with status OK:

* errors: no
* warnings: no
* notes: no

## Reverse dependencies

There are currently no downstream dependencies for this package:

* strong reverse dependencies: 0
* most reverse dependencies: 0
* all reverse dependencies: 0
