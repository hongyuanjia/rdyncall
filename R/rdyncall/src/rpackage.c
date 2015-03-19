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
SEXP r_new_callvm(SEXP callmode, SEXP size);
SEXP r_free_callvm(SEXP callvm);
SEXP r_dyncall(SEXP args); /* .External() with args = callvm, address, signature, args */

/* rdynload.c */
SEXP r_dynload(SEXP libpath);
SEXP r_dynsym(SEXP libobj, SEXP symname, SEXP protectlib);
SEXP r_dynunload(SEXP libobj);

/* rpack.c */
SEXP r_pack(SEXP ptr, SEXP offset, SEXP sig, SEXP value);
SEXP r_unpack(SEXP ptr, SEXP offset, SEXP sig);

/* rcallback.c */
SEXP r_new_callback(SEXP sig, SEXP fun, SEXP rho, SEXP mode);

/* rutils.c */
SEXP r_asextptr(SEXP v);
SEXP r_isnullptr(SEXP x);
SEXP r_offsetPtr(SEXP x, SEXP offset);

/* rutils_str.c */
SEXP r_ptr2str(SEXP ptr);
SEXP r_strarrayptr(SEXP ptr);
SEXP r_strptr(SEXP x);

/* rutils_float.c */
SEXP r_as_floatraw(SEXP real);
SEXP r_floatraw2numeric(SEXP floatraw);

/** ---------------------------------------------------------------------------
 ** R Interface .External registry
 */

R_ExternalMethodDef externalMethods[] =
{
  /* --- rdyncall.c -------------------------------------------------------- */
  {"dyncall",     (DL_FUNC) &r_dyncall,      -1},
  /* --- end (sentinel) ---------------------------------------------------- */
  {NULL,NULL,0}
};

/** ---------------------------------------------------------------------------
 ** R Interface .Call registry
 */

R_CallMethodDef callMethods[] =
{
  /* --- rdyncall.c -------------------------------------------------------- */
  {"new_callvm"                 , (DL_FUNC) &r_new_callvm       , 2},
  {"free_callvm"                , (DL_FUNC) &r_free_callvm      , 1},
  /* --- rdynload.c -------------------------------------------------------- */
  {"dynload"                    , (DL_FUNC) &r_dynload          , 1},
  {"dynsym"                     , (DL_FUNC) &r_dynsym           , 3},
  {"dynunload"                  , (DL_FUNC) &r_dynunload        , 1},
  /* --- rcallback.c ------------------------------------------------------- */
  {"new_callback"               , (DL_FUNC) &r_new_callback     , 3},
  /* --- rpack.c ----------------------------------------------------------- */
  {"pack"                       , (DL_FUNC) &r_pack             , 4},
  {"unpack"                     , (DL_FUNC) &r_unpack           , 3},
  /* --- rutils.c ---------------------------------------------------------- */
  {"asextptr"                   , (DL_FUNC) &r_asextptr         , 1},
  {"isnullptr"                  , (DL_FUNC) &r_isnullptr        , 1},
  {"offsetPtr"                  , (DL_FUNC) &r_offsetPtr        , 2},
  /* --- rutils_str.c ------------------------------------------------------ */
  {"r_ptr2str"                  , (DL_FUNC) &r_ptr2str          , 1},
  {"r_strarrayptr"              , (DL_FUNC) &r_strarrayptr      , 1},
  {"r_strptr"                   , (DL_FUNC) &r_strptr           , 1},
  /* --- rutils_float.c ---------------------------------------------------- */
  {"r_as_floatraw"              , (DL_FUNC) &r_as_floatraw      , 1},
  {"r_floatraw2numeric"         , (DL_FUNC) &r_floatraw2numeric , 1},
  /* --- end (sentinel) ---------------------------------------------------- */
  {NULL,NULL, 0}
};

/** ---------------------------------------------------------------------------
 ** R Library entry:
 */

void R_init_rdyncall(DllInfo *info)
{
  R_registerRoutines(info, NULL, callMethods, NULL, externalMethods);
}

void R_unload_rdyncall(DllInfo *info)
{
}
