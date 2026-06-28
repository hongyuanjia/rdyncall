/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rutils.c
 ** Description: misc utility functions to work with low-level data structures in R
 **/

#include <Rinternals.h>
#include <stddef.h>
#include <stdint.h>
#include <limits.h>

static ptrdiff_t R_vector_data_size(SEXP x)
{
  size_t element_size;

  switch (TYPEOF(x)) {
  case LGLSXP:  element_size = sizeof(Rboolean); break;
  case INTSXP:  element_size = sizeof(int); break;
  case REALSXP: element_size = sizeof(double); break;
  case CPLXSXP: element_size = sizeof(Rcomplex); break;
  case RAWSXP:  element_size = sizeof(Rbyte); break;
  default:
    error("unsupported vector type");
    return 0; /* dummy */
  }

  if (element_size > 0 && XLENGTH(x) > (R_xlen_t) (PTRDIFF_MAX / (ptrdiff_t) element_size)) {
    error("R object is too large for pointer offset arithmetic");
  }

  return (ptrdiff_t) XLENGTH(x) * (ptrdiff_t) element_size;
}

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

static ptrdiff_t C_validate_offset(SEXP offset)
{
  if (TYPEOF(offset) != INTSXP || XLENGTH(offset) < 1) {
    error("offset must be a non-missing non-negative integer scalar");
  }
  int value = INTEGER(offset)[0];
  if (value == NA_INTEGER || value < 0) {
    error("offset must be a non-missing non-negative integer scalar");
  }
  return (ptrdiff_t) value;
}

SEXP C_isnullptr(SEXP x)
{
  if (TYPEOF(x) != EXTPTRSXP) return ScalarLogical(FALSE);
  return ScalarLogical( ( R_ExternalPtrAddr(x) == NULL ) ? TRUE : FALSE );
}

SEXP C_asexternalptr(SEXP x)
{
  if (isVector(x)) {
    if (R_vector_data_size(x) == 0) error("x must have length greater zero");
    return R_MakeExternalPtr( R_vector_data_ptr(x), R_NilValue, x );
  }
  error("expected a vector type");
  return R_NilValue; /* dummy */
}

SEXP C_offsetptr(SEXP x, SEXP offset)
{
  ptrdiff_t offsetval = C_validate_offset(offset);
  unsigned char* ptr = 0;
  if (isVector(x)) {
    ptrdiff_t size = R_vector_data_size(x);
    if (size == 0) error("x must have length greater zero");
    if (offsetval > size) error("offset %td is out-of-bounds of the R object (max size %td)", offsetval, size);
    ptr = (unsigned char*) R_vector_data_ptr(x);
  } else if (TYPEOF(x) == EXTPTRSXP ) {
    ptr = (unsigned char*) R_ExternalPtrAddr(x);
    if (ptr == NULL) error("NULL address pointer");
  } else  {
    error("unsupported type");
  }
  return R_MakeExternalPtr( ptr + offsetval , R_NilValue, x );
}
