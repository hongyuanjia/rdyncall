/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rdynload.c
 ** Description: R bindings to dynload
 **/

#include <Rinternals.h>
#include "dynload.h"

/** ---------------------------------------------------------------------------
 ** C-Function: dynload
 ** Description: load shared library and return lib handle
 ** R-Calling Convention: .Call
 **
 **/

SEXP C_dynload(SEXP libpath_x)
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
 ** C-Function: dynunload
 ** Description: unload shared library
 ** R-Calling Convention: .Call
 **
 **/

SEXP C_dynunload(SEXP libobj_x)
{
  void* libHandle;

  if (TYPEOF(libobj_x) != EXTPTRSXP) error("first argument is not of type external ptr.");

  libHandle = R_ExternalPtrAddr(libobj_x);

  if (!libHandle) error("not a lib handle");

  dlFreeLibrary( libHandle );

  return R_NilValue;
}

/** ---------------------------------------------------------------------------
 ** C-Function: dynsym
 ** Description: resolve symbol
 ** R-Calling Convention: .Call
 **
 **/

SEXP C_dynsym(SEXP libh, SEXP symname_x, SEXP protectlib)
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

SEXP C_dynpath(SEXP libh)
{
  static char buf[1024];
  void* libHandle;
  SEXP ans;

  libHandle = R_ExternalPtrAddr(libh);
  dlGetLibraryPath(libHandle, buf, 1024);
  ans = Rf_mkString(buf);
  return ans;
}

SEXP C_dyncount(SEXP libh)
{
  int count;
  SEXP ans;
  SEXP path;
  DLSyms* pSyms;

  path = C_dynpath(libh);
  pSyms = dlSymsInit(R_CHAR(STRING_ELT(path, 0)));
  count = dlSymsCount(pSyms);
  dlSymsCleanup(pSyms);

  ans = PROTECT(Rf_ScalarInteger(count));
  UNPROTECT(1);
  return ans;
}

SEXP C_dynlist(SEXP libh)
{
  int i;
  int count;
  const char* name;
  SEXP ans;
  SEXP path;
  DLSyms* pSyms;

  path = C_dynpath(libh);
  pSyms = dlSymsInit(CHAR(STRING_ELT(path, 0)));
  count = dlSymsCount(pSyms);

  ans = PROTECT(Rf_allocVector(STRSXP, count));
  for (i = 0; i < count; i++) {
    name = dlSymsName(pSyms, i);
    SET_STRING_ELT(ans, i, Rf_mkChar(name));
  }
  dlSymsCleanup(pSyms);

  UNPROTECT(1);
  return ans;
}
