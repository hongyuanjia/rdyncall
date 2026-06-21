/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rutils.c
 ** Description: misc utility functions to work with low-level data structures in R
 **/

#include <Rinternals.h>
#include <stddef.h>

static void* R_vector_data_ptr(SEXP x)
{
  switch (TYPEOF(x)) {
  case LGLSXP:  return LOGICAL(x);
  case INTSXP:  return INTEGER(x);
  case REALSXP: return REAL(x);
  case CPLXSXP: return COMPLEX(x);
  case RAWSXP:  return RAW(x);
  default:
    error("unsupported vector type");
    return NULL; /* dummy */
  }
}

SEXP C_isnullptr(SEXP x)
{
  if (TYPEOF(x) != EXTPTRSXP) return ScalarLogical(FALSE);
  return ScalarLogical( ( R_ExternalPtrAddr(x) == NULL ) ? TRUE : FALSE );
}

SEXP C_asexternalptr(SEXP x)
{
  if (isVector(x)) {
    return R_MakeExternalPtr( R_vector_data_ptr(x), R_NilValue, x );
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
    ptr = (unsigned char*) R_vector_data_ptr(x);
  } else if (TYPEOF(x) == EXTPTRSXP ) {
    ptr = (unsigned char*) R_ExternalPtrAddr(x);
  } else  {
    error("unsupported type");
  }
  return R_MakeExternalPtr( ptr + offsetval , R_NilValue, x );
}
