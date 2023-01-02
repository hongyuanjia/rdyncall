/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rdynload.c
 ** Description: R bindings to dynload
 **/

#include <Rinternals.h>
#include "dynload.h"

/** ---------------------------------------------------------------------------
 ** C-Function: r_dynload
 ** Description: load shared library and return lib handle
 ** R-Calling Convention: .Call
 **
 **/

SEXP r_dynload(SEXP libpath_x)
{
  const char* libpath_S;
  void* libHandle;

  libpath_S = CHAR(STRING_ELT(libpath_x,0));
  libHandle = dlLoadLibrary(libpath_S);

  if (!libHandle)
    return R_NilValue;

  return R_MakeExternalPtr(libHandle, R_NilValue, R_NilValue);
}

/** ---------------------------------------------------------------------------
 ** C-Function: r_dynunload
 ** Description: unload shared library
 ** R-Calling Convention: .Call
 **
 **/

SEXP r_dynunload(SEXP libobj_x)
{
  void* libHandle;

  if (TYPEOF(libobj_x) != EXTPTRSXP) error("first argument is not of type external ptr.");

  libHandle = R_ExternalPtrAddr(libobj_x);

  if (!libHandle) error("not a lib handle");

  dlFreeLibrary( libHandle );

  return R_NilValue;
}

/** ---------------------------------------------------------------------------
 ** C-Function: r_dynsym
 ** Description: resolve symbol
 ** R-Calling Convention: .Call
 **
 **/

SEXP r_dynsym(SEXP libh, SEXP symname_x, SEXP protectlib)
{
  void* libHandle;
  const char* symbol;
  void* addr;
  SEXP protect;
  libHandle = R_ExternalPtrAddr(libh);
  symbol = CHAR(STRING_ELT(symname_x,0) );
  addr = dlFindSymbol( libHandle, symbol );
  protect = (LOGICAL(protectlib)[0]) ? libh : R_NilValue;
  return (addr) ? R_MakeExternalPtr(addr, R_NilValue, protect) : R_NilValue;
}
