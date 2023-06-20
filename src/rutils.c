/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rutils.c
 ** Description: misc utility functions to work with low-level data structures in R
 **/

// uses: DATAPTR macro
#define USE_RINTERNALS
#include <Rinternals.h>
#include <stddef.h>

SEXP C_isnullptr(SEXP x)
{
  return ScalarLogical( ( R_ExternalPtrAddr(x) == NULL ) ? TRUE : FALSE );
}

SEXP C_asexternalptr(SEXP x)
{
  if (isVector(x)) {
    return R_MakeExternalPtr( DATAPTR(x), R_NilValue, x );
  }
  error("expected a vector type");
  return R_NilValue; /* dummy */
}

SEXP C_offsetptr(SEXP x, SEXP offset)
{
  if ( LENGTH(offset) == 0 ) error("offset is missing");
  ptrdiff_t offsetval = INTEGER(offset)[0];
  unsigned char* ptr = 0;
  if (isVector(x)) {
    ptr = (unsigned char*) DATAPTR(x);
  } else if (TYPEOF(x) == EXTPTRSXP ) {
    ptr = (unsigned char*) R_ExternalPtrAddr(x);
  } else  {
    error("unsupported type");
  }
  return R_MakeExternalPtr( ptr + offsetval , R_NilValue, x );
}

