/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rpackage.c
 ** Description: R package registry
 **/

#include <Rinternals.h>
#include <R_ext/Rdynload.h>

/** ---------------------------------------------------------------------------
 ** Package contents:
 */

/* rdyncall.c */
SEXP C_new_callvm(SEXP callmode, SEXP size);
SEXP C_free_callvm(SEXP callvm);
SEXP C_dyncall(SEXP args); /* .External() with args = callvm, address, signature, args */

/* rdynload.c */
SEXP C_dynload(SEXP libpath);
SEXP C_dynsym(SEXP libobj, SEXP symname, SEXP protectlib);
SEXP C_dynunload(SEXP libobj);

/* rpack.c */
SEXP C_pack(SEXP ptr, SEXP offset, SEXP sig, SEXP value);
SEXP C_unpack(SEXP ptr, SEXP offset, SEXP sig);

/* rcallback.c */
SEXP C_new_callback(SEXP sig, SEXP fun, SEXP rho, SEXP mode);

/* rutils.c */
SEXP C_asextptr(SEXP v);
SEXP C_isnullptr(SEXP x);
SEXP C_offsetPtr(SEXP x, SEXP offset);

/* rutils_str.c */
SEXP C_ptr2str(SEXP ptr);
SEXP C_strarrayptr(SEXP ptr);
SEXP C_strptr(SEXP x);

/* rutils_float.c */
SEXP C_as_floatraw(SEXP real);
SEXP C_floatraw2numeric(SEXP floatraw);

/** ---------------------------------------------------------------------------
 ** R Interface .External registry
 */

R_ExternalMethodDef externalMethods[] =
{
  /* --- rdyncall.c -------------------------------------------------------- */
  {"C_dyncall",     (DL_FUNC) &C_dyncall,      -1},
  /* --- end (sentinel) ---------------------------------------------------- */
  {NULL,NULL,0}
};

/** ---------------------------------------------------------------------------
 ** R Interface .Call registry
 */

R_CallMethodDef callMethods[] =
{
  /* --- rdyncall.c -------------------------------------------------------- */
  {"C_new_callvm"               , (DL_FUNC) &C_new_callvm       , 2},
  {"C_free_callvm"              , (DL_FUNC) &C_free_callvm      , 1},
  /* --- rdynload.c -------------------------------------------------------- */
  {"C_dynload"                  , (DL_FUNC) &C_dynload          , 1},
  {"C_dynsym"                   , (DL_FUNC) &C_dynsym           , 3},
  {"C_dynunload"                , (DL_FUNC) &C_dynunload        , 1},
  /* --- rcallback.c ------------------------------------------------------- */
  {"C_new_callback"             , (DL_FUNC) &C_new_callback     , 3},
  /* --- rpack.c ----------------------------------------------------------- */
  {"C_pack"                     , (DL_FUNC) &C_pack             , 4},
  {"C_unpack"                   , (DL_FUNC) &C_unpack           , 3},
  /* --- rutils.c ---------------------------------------------------------- */
  {"C_asextptr"                 , (DL_FUNC) &C_asextptr         , 1},
  {"C_isnullptr"                , (DL_FUNC) &C_isnullptr        , 1},
  {"C_offsetPtr"                , (DL_FUNC) &C_offsetPtr        , 2},
  /* --- rutils_str.c ------------------------------------------------------ */
  {"C_ptr2str"                  , (DL_FUNC) &C_ptr2str          , 1},
  {"C_strarrayptr"              , (DL_FUNC) &C_strarrayptr      , 1},
  {"C_strptr"                   , (DL_FUNC) &C_strptr           , 1},
  /* --- rutils_float.c ---------------------------------------------------- */
  {"C_as_floatraw"              , (DL_FUNC) &C_as_floatraw      , 1},
  {"C_floatraw2numeric"         , (DL_FUNC) &C_floatraw2numeric , 1},
  /* --- end (sentinel) ---------------------------------------------------- */
  {NULL,NULL, 0}
};

/** ---------------------------------------------------------------------------
 ** R Library entry:
 */

void R_init_rdyncall(DllInfo *info)
{
  R_registerRoutines(info, NULL, callMethods, NULL, externalMethods);
  R_useDynamicSymbols(info, FALSE);
}

void R_unload_rdyncall(DllInfo *info)
{
}
