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
  if (TYPEOF(x) != EXTPTRSXP) {
    return ScalarLogical(FALSE);
  }
  return ScalarLogical( ( R_ExternalPtrAddr(x) == NULL ) ? TRUE : FALSE );
}

SEXP C_asexternalptr(SEXP x)
{
  if (isVector(x)) {
    void* ptr = NULL;
    switch(TYPEOF(x)) {
      case INTSXP:  ptr = INTEGER(x); break;
      case REALSXP: ptr = REAL(x); break;
      case LGLSXP:  ptr = LOGICAL(x); break;
      case CPLXSXP: ptr = COMPLEX(x); break;
      case STRSXP:  ptr = STRING_PTR(x); break;
      case RAWSXP:  ptr = RAW(x); break;
      case VECSXP:  ptr = VECTOR_PTR(x); break;
      default: error("unsupported vector type");
    }
    return R_MakeExternalPtr( ptr, R_NilValue, x );
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
    switch(TYPEOF(x)) {
      case INTSXP:  ptr = (unsigned char*) INTEGER(x); break;
      case REALSXP: ptr = (unsigned char*) REAL(x); break;
      case LGLSXP:  ptr = (unsigned char*) LOGICAL(x); break;
      case CPLXSXP: ptr = (unsigned char*) COMPLEX(x); break;
      case STRSXP:  ptr = (unsigned char*) STRING_PTR(x); break;
      case RAWSXP:  ptr = (unsigned char*) RAW(x); break;
      case VECSXP:  ptr = (unsigned char*) VECTOR_PTR(x); break;
      default: error("unsupported vector type");
    }
  } else if (TYPEOF(x) == EXTPTRSXP ) {
    ptr = (unsigned char*) R_ExternalPtrAddr(x);
  } else  {
    error("unsupported type");
  }
  return R_MakeExternalPtr( ptr + offsetval , R_NilValue, x );
}
