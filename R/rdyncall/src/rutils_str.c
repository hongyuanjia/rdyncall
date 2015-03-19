/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rutils_str.c
 ** Description: Support functions for handling C string data types.
 **/

#define USE_RINTERNALS
#include <Rdefines.h>
#include <Rinternals.h>
#include <R_ext/RS.h>

/* String utils */

SEXP r_ptr2str(SEXP extptr)
{
  void* addr = R_ExternalPtrAddr(extptr);
  if (addr == NULL) {
    return R_NilValue;
  }
  return mkString(addr);
}

SEXP r_strptr(SEXP x)
{
  return R_MakeExternalPtr( (void*) CHAR(STRING_ELT(x, 0)), R_NilValue, x );
}

void do_free(SEXP x)
{
  void* addr = R_ExternalPtrAddr(x);
  R_Free(addr);
}

SEXP r_strarrayptr(SEXP s)
{
  int i;
  int n;
  const char ** ptrs;

  n = LENGTH(s);

  // allocate array
  ptrs = R_Calloc(n, const char*);

  // copy cstring pointers into array
  for( i=0 ; i<n ; ++i ) ptrs[i] = CHAR( STRING_ELT(s, i) );

  // create external pointer pointing to array
  SEXP x = PROTECT( R_MakeExternalPtr( ptrs, R_NilValue, s ) );
  R_RegisterCFinalizerEx( x, do_free, TRUE );
  UNPROTECT(1);
  return x;
}
