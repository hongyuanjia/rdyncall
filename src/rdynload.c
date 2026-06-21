/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rdynload.c
 ** Description: R bindings to dynload
 **/

#include <Rinternals.h>
#include <R_ext/RS.h>
#include "dynload.h"
#include <string.h>

SEXP C_dynpath(SEXP libh);

#if defined(__APPLE__)
#define RDYNCALL_DARWIN_LIBSYSTEM_PATH "/usr/lib/libSystem.B.dylib"
#define RDYNCALL_DARWIN_SYSTEM_DIR "/usr/lib/system/"
#define RDYNCALL_DARWIN_LIB_PREFIX "lib"
#define RDYNCALL_DARWIN_LIBSYSTEM_PREFIX "libsystem_"
#define RDYNCALL_DARWIN_DYLIB_SUFFIX ".dylib"
#endif

#if defined(__APPLE__)
static const char* C_last_path_component(const char* path)
{
  const char* slash = path ? strrchr(path, '/') : NULL;
  return slash ? slash + 1 : path;
}

static int C_darwin_fill_system_path(char* out, size_t out_size, const char* prefix, const char* alias, size_t alias_len)
{
  const size_t dir_len = strlen(RDYNCALL_DARWIN_SYSTEM_DIR);
  const size_t prefix_len = strlen(prefix);
  const size_t suffix_len = strlen(RDYNCALL_DARWIN_DYLIB_SUFFIX);
  const size_t len = dir_len + prefix_len + alias_len + suffix_len;

  if(len >= out_size)
    return 0;

  memcpy(out, RDYNCALL_DARWIN_SYSTEM_DIR, dir_len);
  memcpy(out + dir_len, prefix, prefix_len);
  memcpy(out + dir_len + prefix_len, alias, alias_len);
  memcpy(out + dir_len + prefix_len + alias_len, RDYNCALL_DARWIN_DYLIB_SUFFIX, suffix_len + 1);
  return 1;
}

static DLSyms* C_darwin_try_system_syms(const char* prefix, const char* alias, size_t alias_len)
{
  char candidate[1024];
  DLSyms* pSyms;

  if(!C_darwin_fill_system_path(candidate, sizeof(candidate), prefix, alias, alias_len))
    return NULL;

  pSyms = dlSymsInit(candidate);
  if(pSyms && dlSymsCount(pSyms) > 0)
    return pSyms;

  dlSymsCleanup(pSyms);
  return NULL;
}

static DLSyms* C_darwin_libsystem_alias_syms(SEXP libh, SEXP resolved_path)
{
  SEXP requested_path;
  const char* resolved;
  const char* requested;
  const char* leaf;
  const char* alias;
  size_t leaf_len;
  size_t alias_len;
  DLSyms* pSyms;

  if(TYPEOF(resolved_path) != STRSXP || XLENGTH(resolved_path) < 1 || STRING_ELT(resolved_path, 0) == NA_STRING)
    return NULL;

  resolved = CHAR(STRING_ELT(resolved_path, 0));
  if(strcmp(resolved, RDYNCALL_DARWIN_LIBSYSTEM_PATH) != 0)
    return NULL;

  requested_path = Rf_getAttrib(libh, Rf_install("path"));
  if(TYPEOF(requested_path) != STRSXP || XLENGTH(requested_path) < 1 || STRING_ELT(requested_path, 0) == NA_STRING)
    return NULL;

  requested = CHAR(STRING_ELT(requested_path, 0));
  leaf = C_last_path_component(requested);
  if(!leaf || strncmp(leaf, RDYNCALL_DARWIN_LIB_PREFIX, strlen(RDYNCALL_DARWIN_LIB_PREFIX)) != 0)
    return NULL;

  leaf_len = strlen(leaf);
  if(leaf_len <= strlen(RDYNCALL_DARWIN_LIB_PREFIX) + strlen(RDYNCALL_DARWIN_DYLIB_SUFFIX) ||
     strcmp(leaf + leaf_len - strlen(RDYNCALL_DARWIN_DYLIB_SUFFIX), RDYNCALL_DARWIN_DYLIB_SUFFIX) != 0)
    return NULL;

  alias = leaf + strlen(RDYNCALL_DARWIN_LIB_PREFIX);
  alias_len = leaf_len - strlen(RDYNCALL_DARWIN_LIB_PREFIX) - strlen(RDYNCALL_DARWIN_DYLIB_SUFFIX);
  if(alias_len == 0)
    return NULL;

  pSyms = C_darwin_try_system_syms(RDYNCALL_DARWIN_LIBSYSTEM_PREFIX, alias, alias_len);
  if(pSyms)
    return pSyms;

  return C_darwin_try_system_syms(RDYNCALL_DARWIN_LIB_PREFIX, alias, alias_len);
}
#endif

static DLSyms* C_dlSymsInitFromHandle(SEXP libh)
{
  SEXP path;
  DLSyms* pSyms = NULL;

  path = PROTECT(C_dynpath(libh));

#if defined(__APPLE__)
  pSyms = C_darwin_libsystem_alias_syms(libh, path);
#endif

  if(!pSyms)
    pSyms = dlSymsInit(CHAR(STRING_ELT(path, 0)));

  UNPROTECT(1);
  return pSyms;
}

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
  int size;
  /* should work for most cases */
  static char buf[1024];
  void* libHandle;
  SEXP ans;

  ans = PROTECT(Rf_allocVector(STRSXP, 1));

  libHandle = R_ExternalPtrAddr(libh);
  size = dlGetLibraryPath(libHandle, buf, 1024);
  if (size >= 1) {
    if (size <= 1024) {
      SET_STRING_ELT(ans, 0, Rf_mkCharCE(buf, CE_UTF8));
    } else {
      char * newbuf;
      newbuf = R_Calloc(size, char);
      size = dlGetLibraryPath(libHandle, newbuf, size);
      if (size <= 1) {
        SET_STRING_ELT(ans, 0, NA_STRING);
      } else {
        SET_STRING_ELT(ans, 0, Rf_mkCharCE(newbuf, CE_UTF8));
      }
      R_Free(newbuf);
    }
  } else {
    SET_STRING_ELT(ans, 0, NA_STRING);
  }

  UNPROTECT(1);
  return ans;
}

SEXP C_dyncount(SEXP libh)
{
  int count;
  SEXP ans;
  DLSyms* pSyms;

  pSyms = C_dlSymsInitFromHandle(libh);
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
  DLSyms* pSyms;

  pSyms = C_dlSymsInitFromHandle(libh);
  count = dlSymsCount(pSyms);

  ans = PROTECT(Rf_allocVector(STRSXP, count));
  for (i = 0; i < count; i++) {
    name = dlSymsName(pSyms, i);
    SET_STRING_ELT(ans, i, name ? Rf_mkChar(name) : NA_STRING);
  }
  dlSymsCleanup(pSyms);

  UNPROTECT(1);
  return ans;
}
