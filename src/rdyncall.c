/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rdyncall.c
 ** Description: R bindings to dyncall
 **/

#define R_NO_REMAP
#include <Rinternals.h>
#include "dyncall.h"
#include "dyncall_aggregate.h"
#include "rdyncall_signature.h"
#include <string.h>
#include <ctype.h>
#include <errno.h>
#include <math.h>
#if defined(_WIN32)
#include <windows.h>
#endif

/** ---------------------------------------------------------------------------
 ** Native error state helpers
 **/

static int rdyncall_errno_slot = 0;
#if defined(_WIN32)
static DWORD rdyncall_last_error_slot = 0;
#endif

typedef struct {
  int use_errno;
  int saved_errno;
#if defined(_WIN32)
  int use_last_error;
  DWORD saved_last_error;
#endif
} rdyncall_error_state;

/* Validate and coerce an R scalar before storing it in the private errno slot. */
static int rdyncall_as_errno_value(SEXP value_x)
{
  if (XLENGTH(value_x) != 1) {
    Rf_error("'value' must be a single numeric value");
    return 0;
  }
  int value = Rf_asInteger(value_x);
  if (value == NA_INTEGER) {
    Rf_error("'value' must not be NA");
    return 0;
  }
  return value;
}

#if defined(_WIN32)
/* Validate and coerce an R scalar before storing it in the private LastError slot. */
static DWORD rdyncall_as_last_error_value(SEXP value_x)
{
  if (XLENGTH(value_x) != 1) {
    Rf_error("'value' must be a single numeric value");
    return 0;
  }
  double value = Rf_asReal(value_x);
  if (!isfinite(value) || value < 0 || value > 4294967295.0 || value != floor(value)) {
    Rf_error("'value' must be a finite unsigned 32-bit integer");
    return 0;
  }
  return (DWORD) value;
}
#endif

/* Read one logical capture flag from the R-side two-element flag vector. */
static int rdyncall_error_flag(SEXP flags, int index, const char* name)
{
  if (TYPEOF(flags) != LGLSXP || XLENGTH(flags) < index + 1) {
    Rf_error("internal error: invalid error capture flags");
    return 0;
  }
  int value = LOGICAL(flags)[index];
  if (value == NA_LOGICAL) {
    Rf_error("internal error: '%s' capture flag is NA", name);
    return 0;
  }
  return value != 0;
}

/* Swap rdyncall's private error slots into the process slots before C runs. */
static void rdyncall_error_state_before(rdyncall_error_state* state, int use_errno, int use_last_error)
{
  state->use_errno = use_errno;
  state->saved_errno = errno;
  if (use_errno) {
    errno = rdyncall_errno_slot;
  }

#if defined(_WIN32)
  state->use_last_error = use_last_error;
  state->saved_last_error = GetLastError();
  if (use_last_error) {
    SetLastError(rdyncall_last_error_slot);
  }
#else
  if (use_last_error) {
    Rf_error("'use_last_error' is only supported on Windows");
  }
#endif
}

/* Capture native error slots immediately after C returns, then restore R's slots. */
static void rdyncall_error_state_after(rdyncall_error_state* state)
{
  if (state->use_errno) {
    rdyncall_errno_slot = errno;
    errno = state->saved_errno;
  }

#if defined(_WIN32)
  if (state->use_last_error) {
    rdyncall_last_error_slot = GetLastError();
    SetLastError(state->saved_last_error);
  }
#endif
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_callvm_new
 ** R-Interface: .Call
 **/

SEXP C_callvm_new(SEXP mode_x, SEXP size_x)
{
  /* default call mode is "cdecl" */
  int size_i = INTEGER(size_x)[0];

  const char* mode_S = CHAR( STRING_ELT( mode_x, 0 ) );

  int mode_i = DC_CALL_C_DEFAULT;
  if      (strcmp(mode_S,"default") == 0 || strcmp(mode_S,"cdecl") == 0) mode_i = DC_CALL_C_DEFAULT;
#if WIN32
  else if (strcmp(mode_S,"stdcall") == 0)       mode_i = DC_CALL_C_X86_WIN32_STD;
  else if (strcmp(mode_S,"thiscall") == 0)      mode_i = DC_CALL_C_X86_WIN32_THIS_GNU;
  else if (strcmp(mode_S,"thiscall.gcc") == 0)  mode_i = DC_CALL_C_X86_WIN32_THIS_GNU;
  else if (strcmp(mode_S,"thiscall.msvc") == 0) mode_i = DC_CALL_C_X86_WIN32_THIS_MS;
  else if (strcmp(mode_S,"fastcall") == 0)      mode_i = DC_CALL_C_X86_WIN32_FAST_GNU;
  else if (strcmp(mode_S,"fastcall.msvc") == 0) mode_i = DC_CALL_C_X86_WIN32_FAST_MS;
  else if (strcmp(mode_S,"fastcall.gcc") == 0)  mode_i = DC_CALL_C_X86_WIN32_FAST_GNU;
#else
  else if (strcmp(mode_S,"stdcall") == 0 ||
           strcmp(mode_S,"thiscall") == 0 ||
           strcmp(mode_S,"thiscall.gcc") == 0 ||
           strcmp(mode_S,"thiscall.msvc") == 0 ||
           strcmp(mode_S,"fastcall") == 0 ||
           strcmp(mode_S,"fastcall.msvc") == 0 ||
           strcmp(mode_S,"fastcall.gcc") == 0)  mode_i = DC_CALL_C_DEFAULT;
#endif
  /* return NULL for invalid callmode */
  else { Rf_error("invalid 'callmode' found: '%s'", mode_S); return R_NilValue; }

  DCCallVM* pvm = dcNewCallVM(size_i);
  dcMode( pvm, mode_i );
  return R_MakeExternalPtr( pvm, R_NilValue, R_NilValue );
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_callvm_free
 ** R-Interface: .Call
 **/

SEXP C_callvm_free(SEXP callvm_x)
{
  DCCallVM* callvm_p = (DCCallVM*) R_ExternalPtrAddr( callvm_x );
  dcFree( callvm_p );
  return R_NilValue;
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_dyncall_get_errno
 ** R-Interface: .Call
 **/

SEXP C_dyncall_get_errno(void)
{
  return Rf_ScalarInteger(rdyncall_errno_slot);
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_dyncall_set_errno
 ** R-Interface: .Call
 **/

SEXP C_dyncall_set_errno(SEXP value_x)
{
  int old = rdyncall_errno_slot;
  rdyncall_errno_slot = rdyncall_as_errno_value(value_x);
  return Rf_ScalarInteger(old);
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_dyncall_get_last_error
 ** R-Interface: .Call
 **/

SEXP C_dyncall_get_last_error(void)
{
#if defined(_WIN32)
  return Rf_ScalarReal((double) rdyncall_last_error_slot);
#else
  Rf_error("'LastError' is only supported on Windows");
  return R_NilValue;
#endif
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_dyncall_set_last_error
 ** R-Interface: .Call
 **/

SEXP C_dyncall_set_last_error(SEXP value_x)
{
#if defined(_WIN32)
  DWORD old = rdyncall_last_error_slot;
  rdyncall_last_error_slot = rdyncall_as_last_error_value(value_x);
  return Rf_ScalarReal((double) old);
#else
  Rf_error("'LastError' is only supported on Windows");
  return R_NilValue;
#endif
}

/** ---------------------------------------------------------------------------
 ** Aggregate helpers
 **/

#define RDYNCALL_MAX_AGGRS 256

static SEXP rdyncall_get_list_element(SEXP list, const char *name)
{
  SEXP names = Rf_getAttrib(list, R_NamesSymbol);
  if (names == R_NilValue) return R_NilValue;
  for (R_xlen_t i = 0; i < XLENGTH(list); i++) {
    if (strcmp(CHAR(STRING_ELT(names, i)), name) == 0) {
      return VECTOR_ELT(list, i);
    }
  }
  return R_NilValue;
}

static int rdyncall_scalar_int(SEXP x, const char *name)
{
  if (TYPEOF(x) == INTSXP && XLENGTH(x) > 0) return INTEGER(x)[0];
  if (TYPEOF(x) == REALSXP && XLENGTH(x) > 0) return (int) REAL(x)[0];
  Rf_error("internal error: aggregate layout field '%s' is not an integer scalar", name);
  return 0;
}

static const char* rdyncall_layout_name(SEXP layout)
{
  SEXP name = rdyncall_get_list_element(layout, "name");
  if (TYPEOF(name) != STRSXP || XLENGTH(name) < 1) {
    Rf_error("internal error: aggregate layout is missing a name");
  }
  return CHAR(STRING_ELT(name, 0));
}

static int rdyncall_layout_size(SEXP layout)
{
  return rdyncall_scalar_int(rdyncall_get_list_element(layout, "size"), "size");
}

static int rdyncall_layout_align(SEXP layout)
{
  return rdyncall_scalar_int(rdyncall_get_list_element(layout, "align"), "align");
}

static void rdyncall_expect_struct_arg(SEXP arg, const char *type_name, int type_len, int size, int argpos)
{
  if (TYPEOF(arg) != RAWSXP) {
    Rf_error("Argument type mismatch at position %d: expected raw aggregate data", argpos);
  }
  if (XLENGTH(arg) < size) {
    Rf_error("Argument type mismatch at position %d: aggregate storage is smaller than the registered type size", argpos);
  }

  SEXP structName = Rf_getAttrib(arg, Rf_install("struct"));
  if (TYPEOF(structName) != STRSXP || XLENGTH(structName) < 1) {
    Rf_error("Argument type mismatch at position %d: expected a raw struct object", argpos);
  }
  const char *actual = CHAR(STRING_ELT(structName, 0));
  if ((int) strlen(actual) != type_len || strncmp(actual, type_name, type_len) != 0) {
    Rf_error("incompatible aggregate types");
  }
}

static DCsigchar rdyncall_aggregate_field_sigchar(const char *type)
{
  if (type[0] == '*') return DC_SIGCHAR_POINTER;
  switch(type[0]) {
    case DC_SIGCHAR_BOOL:
    case DC_SIGCHAR_CHAR:
    case DC_SIGCHAR_UCHAR:
    case DC_SIGCHAR_SHORT:
    case DC_SIGCHAR_USHORT:
    case DC_SIGCHAR_INT:
    case DC_SIGCHAR_UINT:
    case DC_SIGCHAR_LONG:
    case DC_SIGCHAR_ULONG:
    case DC_SIGCHAR_LONGLONG:
    case DC_SIGCHAR_ULONGLONG:
    case DC_SIGCHAR_FLOAT:
    case DC_SIGCHAR_DOUBLE:
    case DC_SIGCHAR_POINTER:
    case DC_SIGCHAR_STRING:
      return type[0];
    case DC_SIGCHAR_SEXP:
      return DC_SIGCHAR_POINTER;
    default:
      Rf_error("unsupported aggregate field type '%s'", type);
      return DC_SIGCHAR_VOID;
  }
}

static DCaggr* rdyncall_new_aggr(SEXP layout, DCaggr **aggrs, int *aggr_count)
{
  int size = rdyncall_layout_size(layout);
  int alignment = rdyncall_layout_align(layout);
  SEXP fields = rdyncall_get_list_element(layout, "fields");
  SEXP field_layouts = rdyncall_get_list_element(layout, "field_layouts");
  SEXP types = rdyncall_get_list_element(fields, "type");
  SEXP offsets = rdyncall_get_list_element(fields, "offset");
  SEXP array_lens = rdyncall_get_list_element(fields, "array_len");

  if (TYPEOF(fields) != VECSXP || TYPEOF(types) != STRSXP || TYPEOF(offsets) != INTSXP ||
      TYPEOF(field_layouts) != VECSXP) {
    Rf_error("internal error: invalid aggregate field layout");
  }

  R_xlen_t nfields = XLENGTH(types);
  if (XLENGTH(field_layouts) < nfields) {
    Rf_error("internal error: invalid nested aggregate field layout");
  }
  if (array_lens != R_NilValue && (TYPEOF(array_lens) != INTSXP || XLENGTH(array_lens) < nfields)) {
    Rf_error("internal error: invalid aggregate field array lengths");
  }
  if (*aggr_count >= RDYNCALL_MAX_AGGRS) {
    Rf_error("too many aggregate by-value descriptors");
  }

  DCaggr *ag = dcNewAggr((DCsize) nfields, (DCsize) size);
  aggrs[*aggr_count] = ag;
  *aggr_count += 1;

  for (R_xlen_t i = 0; i < nfields; i++) {
    const char *type = CHAR(STRING_ELT(types, i));
    int array_len = array_lens == R_NilValue ? 1 : INTEGER(array_lens)[i];
    if (array_len < 1) {
      Rf_error("internal error: invalid aggregate field array length");
    }
    if (type[0] == '<') {
      SEXP sub_layout = VECTOR_ELT(field_layouts, i);
      if (sub_layout == R_NilValue) {
        Rf_error("internal error: missing nested aggregate field layout");
      }
      DCaggr *sub_ag = rdyncall_new_aggr(sub_layout, aggrs, aggr_count);
      dcAggrField(ag, DC_SIGCHAR_AGGREGATE, INTEGER(offsets)[i], (DCsize) array_len, sub_ag);
    } else {
      dcAggrField(ag, rdyncall_aggregate_field_sigchar(type), INTEGER(offsets)[i], (DCsize) array_len);
    }
  }
  ag->alignment = (DCsize) alignment;
  dcCloseAggr(ag);
  return ag;
}

static void rdyncall_arg_aggr(DCCallVM *pvm, SEXP layout, SEXP arg, int argpos,
                              DCaggr **aggrs, int *aggr_count)
{
#if defined(DC__Feature_AggrByVal)
  DCaggr *ag = rdyncall_new_aggr(layout, aggrs, aggr_count);
  dcArgAggr(pvm, ag, RAW(arg));
#else
  (void)pvm;
  (void)layout;
  (void)arg;
  Rf_error("aggregate by-value argument at position %d is unsupported by this backend", argpos);
#endif
}

static DCaggr* rdyncall_return_aggr(DCCallVM *pvm, SEXP layout, DCaggr **aggrs, int *aggr_count)
{
#if defined(DC__Feature_AggrByVal)
  DCaggr *ag = rdyncall_new_aggr(layout, aggrs, aggr_count);
  dcBeginCallAggr(pvm, ag);
  return ag;
#else
  (void)pvm;
  (void)layout;
  (void)aggrs;
  (void)aggr_count;
  Rf_error("aggregate return values are unsupported by this backend");
  return NULL;
#endif
}

static void rdyncall_free_aggrs(DCaggr **aggrs, int aggr_count)
{
  for (int i = 0; i < aggr_count; i++) {
    dcFreeAggr(aggrs[i]);
  }
}

static void rdyncall_set_struct_attrib(SEXP x, const char *name)
{
  Rf_setAttrib(x, Rf_install("struct"), Rf_mkString(name));
  Rf_setAttrib(x, R_ClassSymbol, Rf_mkString("struct"));
}

static int rdyncall_has_class(SEXP x, const char *class_name)
{
  SEXP classes = Rf_getAttrib(x, R_ClassSymbol);
  if (TYPEOF(classes) != STRSXP) return 0;

  for (R_xlen_t i = 0; i < XLENGTH(classes); i++) {
    SEXP cls = STRING_ELT(classes, i);
    if (cls != NA_STRING && strcmp(CHAR(cls), class_name) == 0) return 1;
  }

  return 0;
}

static const char* rdyncall_struct_attr(SEXP x, int argpos)
{
  SEXP structName = Rf_getAttrib(x, Rf_install("struct"));
  if (TYPEOF(structName) != STRSXP || XLENGTH(structName) < 1 ||
      STRING_ELT(structName, 0) == NA_STRING) {
    Rf_error("Argument type mismatch at position %d: expected struct metadata on typed pointer argument", argpos);
  }

  return CHAR(STRING_ELT(structName, 0));
}

static void rdyncall_expect_nonempty_vector_arg(SEXP arg, int argpos)
{
  switch(TYPEOF(arg)) {
    case LGLSXP:
    case INTSXP:
    case REALSXP:
    case CPLXSXP:
    case RAWSXP:
    case STRSXP:
      if (XLENGTH(arg) == 0) {
        Rf_error("Argument type mismatch at position %d: expected length greater zero.", argpos);
      }
      break;
    default:
      break;
  }
}

static DCpointer rdyncall_lowlevel_pointer_arg(SEXP arg, char ch, int ptrcnt, int argpos)
{
  int type_id = TYPEOF(arg);

  if (type_id == NILSXP) return (DCpointer) 0;
  if (type_id == EXTPTRSXP) return R_ExternalPtrAddr(arg);
  if (ptrcnt > 1) {
    Rf_error("Argument type mismatch at position %d: expected NULL or external pointer for multi-level typed pointer", argpos);
  }

  rdyncall_expect_nonempty_vector_arg(arg, argpos);

  switch(ch) {
    case DC_SIGCHAR_VOID:
      switch(type_id)
      {
        case STRSXP:  return (DCpointer) CHAR(STRING_ELT(arg, 0));
        case LGLSXP:  return (DCpointer) LOGICAL(arg);
        case INTSXP:  return (DCpointer) INTEGER(arg);
        case REALSXP: return (DCpointer) REAL(arg);
        case CPLXSXP: return (DCpointer) COMPLEX(arg);
        case RAWSXP:  return (DCpointer) RAW(arg);
        default:
          Rf_error("Argument type mismatch at position %d: expected pointer convertable value", argpos);
      }
      break;
    case DC_SIGCHAR_CHAR:
    case DC_SIGCHAR_UCHAR:
      switch(type_id)
      {
        case STRSXP: return (DCpointer) CHAR(STRING_ELT(arg, 0));
        case RAWSXP: return (DCpointer) RAW(arg);
        default:
          Rf_error("Argument type mismatch at position %d: expected character, raw, external pointer, or NULL for C character pointer", argpos);
      }
      break;
    case DC_SIGCHAR_INT:
    case DC_SIGCHAR_UINT:
      if (type_id == INTSXP) return (DCpointer) INTEGER(arg);
      Rf_error("Argument type mismatch at position %d: expected integer, external pointer, or NULL for C integer pointer", argpos);
      break;
    case DC_SIGCHAR_DOUBLE:
      if (type_id == REALSXP) return (DCpointer) REAL(arg);
      Rf_error("Argument type mismatch at position %d: expected numeric, external pointer, or NULL for C double pointer", argpos);
      break;
    case DC_SIGCHAR_FLOAT:
      if (type_id == RAWSXP && rdyncall_has_class(arg, "floatraw")) return (DCpointer) RAW(arg);
      Rf_error("Argument type mismatch at position %d: expected floatraw, external pointer, or NULL for C float pointer", argpos);
      break;
    case DC_SIGCHAR_SHORT:
    case DC_SIGCHAR_USHORT:
    case DC_SIGCHAR_LONG:
    case DC_SIGCHAR_ULONG:
    case DC_SIGCHAR_LONGLONG:
    case DC_SIGCHAR_ULONGLONG:
    case DC_SIGCHAR_POINTER:
    case DC_SIGCHAR_STRING:
      Rf_error("Argument type mismatch at position %d: expected external pointer or NULL for this typed pointer signature", argpos);
      break;
    default:
      Rf_error("Unsupported typed pointer signature at position %d", argpos);
  }

  return (DCpointer) 0;
}

static int rdyncall_mode_from_signature_char(char ch)
{
  switch(ch)
  {
    case DC_SIGCHAR_CC_DEFAULT:
      return DC_CALL_C_DEFAULT;
    case DC_SIGCHAR_CC_ELLIPSIS:
      return DC_CALL_C_ELLIPSIS;
    case DC_SIGCHAR_CC_ELLIPSIS_VARARGS:
      return DC_CALL_C_ELLIPSIS_VARARGS;
    case DC_SIGCHAR_CC_STDCALL:
      return DC_CALL_C_X86_WIN32_STD;
    case DC_SIGCHAR_CC_FASTCALL_GNU:
      return DC_CALL_C_X86_WIN32_FAST_GNU;
    case DC_SIGCHAR_CC_FASTCALL_MS:
      return DC_CALL_C_X86_WIN32_FAST_MS;
    default:
      Rf_error("Unknown calling convention prefix hint signature character '%c'", ch);
      return DC_CALL_C_DEFAULT;
  }
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_dyncall
 ** R-Interface: .External
 **/

SEXP C_dyncall(SEXP args) /* callvm, address, signature, aggregate layouts, args ... */
{
  DCCallVM*   pvm;
  void*       addr;
  const char* signature;
  const char* sig;
  SEXP        arg;
  SEXP        aggr_layouts;
  SEXP        error_flags;
  SEXP        aggr_args;
  SEXP        aggr_return_layout;
  DCaggr*     aggr_return = NULL;
  int         ptrcnt;
  int         argpos;
  int         aggrpos;
  int         use_errno;
  int         use_last_error;
  DCaggr*     aggrs[RDYNCALL_MAX_AGGRS];
  int         aggr_count = 0;

  args = CDR(args);

  /* extract CallVM reference, address and signature */

  pvm  = (DCCallVM*) R_ExternalPtrAddr( CAR(args) ); args = CDR(args);

  switch(TYPEOF(CAR(args))) {
    case EXTPTRSXP:
      addr = R_ExternalPtrAddr( CAR(args) ); args = CDR(args);
      if (!addr) {
        Rf_error("Target address is null-pointer.");
        return R_NilValue; /* dummy */
      }
      break;
    default:
      Rf_error("Target address must be external pointer.");
      return R_NilValue; /* dummy */
  }
  signature = CHAR( STRING_ELT( CAR(args), 0 ) ); args = CDR(args);
  aggr_layouts = CAR(args); args = CDR(args);
  error_flags = CAR(args); args = CDR(args);
  use_errno = rdyncall_error_flag(error_flags, 0, "use_errno");
  use_last_error = rdyncall_error_flag(error_flags, 1, "use_last_error");
  aggr_args = rdyncall_get_list_element(aggr_layouts, "args");
  aggr_return_layout = rdyncall_get_list_element(aggr_layouts, "return");
  if (TYPEOF(aggr_args) != VECSXP) {
    Rf_error("internal error: invalid aggregate layout list");
    return R_NilValue;
  }
  sig = signature;

  if (!pvm) {
    Rf_error("Argument 'callvm' is null");
    /* dummy */ return R_NilValue;
  }
  if (!addr) {
    Rf_error("Argument 'addr' is null");
    /* dummy */ return R_NilValue;
  }
  /* reset CallVM to initial state */

  dcReset(pvm);
  ptrcnt = 0;
  argpos = 0;
  aggrpos = 0;

  /* function calling convention prefix '_' */
  if (*sig == DC_SIGCHAR_CC_PREFIX) {
    /* specify calling convention by signature prefix hint */
    ++sig;
    char ch = *sig++;
    dcMode(pvm, rdyncall_mode_from_signature_char(ch));
  }

  if (aggr_return_layout != R_NilValue) {
    aggr_return = rdyncall_return_aggr(pvm, aggr_return_layout, aggrs, &aggr_count);
  }

  /* load arguments */
  for(;;) {

    char ch = *sig++;

    if (ch == '\0') {
      Rf_error("Function-call signature '%s' is invalid - missing argument terminator character ')' and return type signature.", signature);
      /* dummy */ return R_NilValue;
    }
    /* argument terminator */
    if (ch == ')') break;

    if (ch == DC_SIGCHAR_CC_PREFIX) {
      char mode_ch = *sig++;
      if (mode_ch == '\0') {
        Rf_error("Function-call signature '%s' is invalid - missing calling convention mode character.", signature);
        return R_NilValue; /* dummy */
      }
      dcMode(pvm, rdyncall_mode_from_signature_char(mode_ch));
      ptrcnt = 0;
      continue;
    }

    /* end of arguments? */
    if (args == R_NilValue) {
      Rf_error("Not enough arguments for function-call signature '%s'.", signature);
      /* dummy */ return R_NilValue;
    }
    /* pointer counter */
    else if (ch == '*') { ptrcnt++; continue; }

    /* unpack next argument */
    arg = CAR(args); args = CDR(args);
    argpos++;

    int type_id = TYPEOF(arg);

    if (ptrcnt == 0) { /* base types */

      if (ch == '<') { /* aggregate by value */
        char const *b = sig;
        while( isalnum(*sig) || *sig == '_' ) sig++;
        if (*sig != '>') {
          Rf_error("Invalid signature '%s' - missing '>' marker for aggregate at argument %d.", signature, argpos);
          return R_NilValue; /* Dummy */
        }
        char const *e = sig;
        int l = e - b;
        sig++;

        if (aggrpos >= XLENGTH(aggr_args)) {
          Rf_error("internal error: missing aggregate layout for argument %d", argpos);
          return R_NilValue; /* Dummy */
        }
        SEXP layout = VECTOR_ELT(aggr_args, aggrpos++);
        rdyncall_expect_struct_arg(arg, b, l, rdyncall_layout_size(layout), argpos);
        if ((int) strlen(rdyncall_layout_name(layout)) != l || strncmp(rdyncall_layout_name(layout), b, l) != 0) {
          Rf_error("internal error: aggregate layout type does not match signature");
          return R_NilValue; /* Dummy */
        }
        rdyncall_arg_aggr(pvm, layout, arg, argpos, aggrs, &aggr_count);
        continue;
      }

      /* 'x' signature for passing language objects 'as-is' */
      if (ch == DC_SIGCHAR_SEXP) {
        dcArgPointer(pvm, (void*)arg);
        continue;
      }

      if (type_id != NILSXP && type_id != EXTPTRSXP) rdyncall_expect_nonempty_vector_arg(arg, argpos);
      switch(ch) {
        case DC_SIGCHAR_BOOL:
        {
          DCbool boolValue;
          switch(type_id)
          {
            case LGLSXP:  boolValue = ( LOGICAL(arg)[0] == 0   ) ? DC_FALSE : DC_TRUE; break;
            case INTSXP:  boolValue = ( INTEGER(arg)[0] == 0   ) ? DC_FALSE : DC_TRUE; break;
            case REALSXP: boolValue = ( REAL(arg)[0]    == 0.0 ) ? DC_FALSE : DC_TRUE; break;
            case RAWSXP:  boolValue = ( RAW(arg)[0]     == 0   ) ? DC_FALSE : DC_TRUE; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C bool convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgBool(pvm, boolValue );
        }
        break;
        case DC_SIGCHAR_CHAR:
        {
          char charValue;
          switch(type_id)
          {
            case LGLSXP:  charValue = (char) LOGICAL(arg)[0]; break;
            case INTSXP:  charValue = (char) INTEGER(arg)[0]; break;
            case REALSXP: charValue = (char) REAL(arg)[0];    break;
            case RAWSXP:  charValue = (char) RAW(arg)[0];     break;
            default:      Rf_error("Argument type mismatch at position %d: expected C char convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgChar(pvm, charValue);
        }
        break;
        case DC_SIGCHAR_UCHAR:
        {
          unsigned char charValue;
          switch(type_id)
          {
            case LGLSXP:  charValue = (unsigned char) LOGICAL(arg)[0]; break;
            case INTSXP:  charValue = (unsigned char) INTEGER(arg)[0];        break;
            case REALSXP: charValue = (unsigned char) REAL(arg)[0];    break;
            case RAWSXP:  charValue = (unsigned char) RAW(arg)[0];     break;
            default:      Rf_error("Argument type mismatch at position %d: expected C unsigned char convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgChar(pvm, *( (char*) &charValue ));
        }
        break;
        case DC_SIGCHAR_SHORT:
        {
          short shortValue;
          switch(type_id)
          {
            case LGLSXP:  shortValue = (short) LOGICAL(arg)[0]; break;
            case INTSXP:  shortValue = (short) INTEGER(arg)[0];        break;
            case REALSXP: shortValue = (short) REAL(arg)[0];    break;
            case RAWSXP:  shortValue = (short) RAW(arg)[0];     break;
            default:      Rf_error("Argument type mismatch at position %d: expected C short convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgShort(pvm, shortValue);
        }
        break;
        case DC_SIGCHAR_USHORT:
        {
          unsigned short shortValue;
          switch(type_id)
          {
            case LGLSXP:  shortValue = (unsigned short) LOGICAL(arg)[0]; break;
            case INTSXP:  shortValue = (unsigned short) INTEGER(arg)[0];        break;
            case REALSXP: shortValue = (unsigned short) REAL(arg)[0];    break;
            case RAWSXP:  shortValue = (unsigned short) RAW(arg)[0];     break;
            default:      Rf_error("Argument type mismatch at position %d: expected C unsigned short convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgShort(pvm, *( (short*) &shortValue ) );
        }
        break;
        case DC_SIGCHAR_LONG:
        {
          long longValue;
          switch(type_id)
          {
            case LGLSXP:  longValue = (long) LOGICAL(arg)[0]; break;
            case INTSXP:  longValue = (long) INTEGER(arg)[0]; break;
            case REALSXP: longValue = (long) REAL(arg)[0];    break;
            case RAWSXP:  longValue = (long) RAW(arg)[0];     break;
            default:      Rf_error("Argument type mismatch at position %d: expected C long convertable value", argpos);  /* dummy */ return R_NilValue;
          }
          dcArgLong(pvm, longValue);
        }
        break;
        case DC_SIGCHAR_ULONG:
        {
          unsigned long ulongValue;
          switch(type_id)
          {
            case LGLSXP:  ulongValue = (unsigned long) LOGICAL(arg)[0]; break;
            case INTSXP:  ulongValue = (unsigned long) INTEGER(arg)[0]; break;
            case REALSXP: ulongValue = (unsigned long) REAL(arg)[0]; break;
            case RAWSXP:  ulongValue = (unsigned long) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C unsigned long convertable value", argpos);  /* dummy */ return R_NilValue;
          }
          dcArgLong(pvm, (unsigned long) ulongValue);
        }
        break;
        case DC_SIGCHAR_INT:
        {
          int intValue;
          switch(type_id)
          {
            case LGLSXP:  intValue = (int) LOGICAL(arg)[0]; break;
            case INTSXP:  intValue = INTEGER(arg)[0]; break;
            case REALSXP: intValue = (int) REAL(arg)[0]; break;
            case RAWSXP:  intValue = (int) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C int convertable value", argpos); /*dummy*/ return R_NilValue;
          }
          dcArgInt(pvm, intValue);
        }
        break;
        case DC_SIGCHAR_UINT:
        {
          unsigned int intValue;
          switch(type_id)
          {
            case LGLSXP:  intValue = (unsigned int) LOGICAL(arg)[0]; break;
            case INTSXP:  intValue = (unsigned int) INTEGER(arg)[0]; break;
            case REALSXP: intValue = (unsigned int) REAL(arg)[0]; break;
            case RAWSXP:  intValue = (unsigned int) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C unsigned int convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgInt(pvm, * (int*) &intValue);
        }
        break;
        case DC_SIGCHAR_FLOAT:
        {
          float floatValue;
          switch(type_id)
          {
            case LGLSXP:  floatValue = (float) LOGICAL(arg)[0]; break;
            case INTSXP:  floatValue = (float) INTEGER(arg)[0]; break;
            case REALSXP: floatValue = (float) REAL(arg)[0]; break;
            case RAWSXP:  floatValue = (float) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C float convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgFloat( pvm, floatValue );
        }
        break;
        case DC_SIGCHAR_DOUBLE:
        {
          DCdouble doubleValue;
          switch(type_id)
          {
            case LGLSXP:  doubleValue = (double) LOGICAL(arg)[0]; break;
            case INTSXP:  doubleValue = (double) INTEGER(arg)[0]; break;
            case REALSXP: doubleValue = REAL(arg)[0]; break;
            case RAWSXP:  doubleValue = (double) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C double convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgDouble( pvm, doubleValue );
        }
        break;
        case DC_SIGCHAR_LONGLONG:
        {
          DClonglong longlongValue;
          switch(type_id)
          {
            case LGLSXP:  longlongValue = (DClonglong) LOGICAL(arg)[0]; break;
            case INTSXP:  longlongValue = (DClonglong) INTEGER(arg)[0]; break;
            case REALSXP: longlongValue = (DClonglong) REAL(arg)[0]; break;
            case RAWSXP:  longlongValue = (DClonglong) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C long long (int64_t) convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgLongLong( pvm, longlongValue );
        }
        break;
        case DC_SIGCHAR_ULONGLONG:
        {
          DCulonglong ulonglongValue;
          switch(type_id)
          {
            case LGLSXP:  ulonglongValue = (DCulonglong) LOGICAL(arg)[0]; break;
            case INTSXP:  ulonglongValue = (DCulonglong) INTEGER(arg)[0]; break;
            case REALSXP: ulonglongValue = (DCulonglong) REAL(arg)[0]; break;
            case RAWSXP:  ulonglongValue = (DCulonglong) RAW(arg)[0]; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C unsigned long long (uint64_t) convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgLongLong( pvm, *( (DClonglong*)&ulonglongValue ) );
        }
        break;
        case DC_SIGCHAR_POINTER:
        {
          DCpointer ptrValue;
          switch(type_id)
          {
            case NILSXP:    ptrValue = (DCpointer) 0; break;
            case CHARSXP:   ptrValue = (DCpointer) CHAR(arg); break;
            case SYMSXP:    ptrValue = (DCpointer) PRINTNAME(arg); break;
            case STRSXP:    ptrValue = (DCpointer) CHAR(STRING_ELT(arg,0)); break;
            case LGLSXP:    ptrValue = (DCpointer) LOGICAL(arg); break;
            case INTSXP:    ptrValue = (DCpointer) INTEGER(arg); break;
            case REALSXP:   ptrValue = (DCpointer) REAL(arg); break;
            case CPLXSXP:   ptrValue = (DCpointer) COMPLEX(arg); break;
            case RAWSXP:    ptrValue = (DCpointer) RAW(arg); break;
            case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
            // case ENVSXP:    ptrValue = (DCpointer) arg; break;
            default:      Rf_error("Argument type mismatch at position %d: expected C pointer convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgPointer(pvm, ptrValue);
        }
        break;
        case DC_SIGCHAR_STRING:
        {
          DCpointer cstringValue;
          switch(type_id)
          {
            case NILSXP:    cstringValue = (DCpointer) 0; break;
            case CHARSXP:   cstringValue = (DCpointer) CHAR(arg); break;
            case SYMSXP:    cstringValue = (DCpointer) PRINTNAME(arg); break;
            case STRSXP:    cstringValue = (DCpointer) CHAR( STRING_ELT(arg,0) ); break;
            case EXTPTRSXP: cstringValue = R_ExternalPtrAddr(arg); break;
            default:      Rf_error("Argument type mismatch at position %d: expected C string pointer convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgPointer(pvm, cstringValue);
        }
        break;
        default: Rf_error("Signature type mismatch at position %d: Unknown token '%c' at argument %d.", argpos, ch, argpos); /* dummy */ return R_NilValue;
      }
    } else { /* ptrcnt > 0 */
      DCpointer ptrValue;
      if (ch == '<') { /* typed high-level struct/union pointer */
        char const * e;
        char const * b;
        char const * n;
        int l;
        b = sig;
        while( isalnum(*sig) || *sig == '_' ) sig++;
        if (*sig != '>') {
          Rf_error("Invalid signature '%s' - missing '>' marker for structure at argument %d.", signature, argpos);
          return R_NilValue; /* Dummy */
        }
        sig++;
        /* check pointer type */
        if (type_id != NILSXP) {
          n = rdyncall_struct_attr(arg, argpos);
          e = sig-1;
          l = e - b;
          if ( (strlen(n) != l) || (strncmp(b,n,l) != 0) ) {
            Rf_error("incompatible pointer types");
            return R_NilValue; /* Dummy */
          }
        }
        switch(type_id) {
          case NILSXP:    ptrValue = (DCpointer) 0; break;
          case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
          case RAWSXP:    ptrValue = (DCpointer) RAW(arg); break;
          default:        Rf_error("internal error: typed-pointer can be external pointers or raw only.");
          return R_NilValue; /* Dummy */
        }
        dcArgPointer(pvm, ptrValue);
        ptrcnt = 0;
      } else { /* typed low-level pointers */
        ptrValue = rdyncall_lowlevel_pointer_arg(arg, ch, ptrcnt, argpos);
        dcArgPointer(pvm, ptrValue);
        ptrcnt = 0;
      }
    }
  }


  if (args != R_NilValue) {
    Rf_error ("Too many arguments for signature '%s'.", signature);
    return R_NilValue; /* dummy */
  }
  /* process return type, invoke call and return R value  */

  SEXP ans = R_NilValue;
  int ans_protected = 0;
  rdyncall_error_state error_state;

  switch(*sig++) {
    case DC_SIGCHAR_BOOL:
    {
      DCbool value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallBool(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarLogical((value == DC_FALSE) ? FALSE : TRUE);
    } break;

    case DC_SIGCHAR_CHAR:
    {
      DCchar value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallChar(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarInteger((int) value);
    } break;
    case DC_SIGCHAR_UCHAR:
    {
      DCchar value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallChar(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarInteger((int) ((unsigned char) value));
    } break;

    case DC_SIGCHAR_SHORT:
    {
      DCshort value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallShort(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarInteger((int) value);
    } break;
    case DC_SIGCHAR_USHORT:
    {
      DCshort value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallShort(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarInteger((int) ((unsigned short) value));
    } break;

    case DC_SIGCHAR_INT:
    {
      DCint value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallInt(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarInteger(value);
    } break;
    case DC_SIGCHAR_UINT:
    {
      DCint value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallInt(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) (unsigned int) value);
    } break;

    case DC_SIGCHAR_LONG:
    {
      DClong value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallLong(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) value);
    } break;
    case DC_SIGCHAR_ULONG:
    {
      DClong value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallLong(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) ((unsigned long) value));
    } break;

    case DC_SIGCHAR_LONGLONG:
    {
      DClonglong value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallLongLong(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) value);
    } break;
    case DC_SIGCHAR_ULONGLONG:
    {
      DClonglong value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallLongLong(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) value);
    } break;

    case DC_SIGCHAR_FLOAT:
    {
      DCfloat value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallFloat(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal((double) value);
    } break;
    case DC_SIGCHAR_DOUBLE:
    {
      DCdouble value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallDouble(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_ScalarReal(value);
    } break;
    case DC_SIGCHAR_POINTER:
    {
      DCpointer value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallPointer(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = R_MakeExternalPtr(value, R_NilValue, R_NilValue);
    } break;
    case DC_SIGCHAR_STRING:
    {
      DCpointer value;
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      value = dcCallPointer(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = Rf_mkString(value);
    } break;
    case DC_SIGCHAR_VOID:
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      dcCallVoid(pvm, addr);
      rdyncall_error_state_after(&error_state);
      ans = R_NilValue;
      break;
    case '<':
    {
      char const *b = sig;
      while (isalnum(*sig) || *sig == '_') sig++;
      if (*sig != '>') {
        Rf_error("Invalid signature '%s' - missing '>' marker for aggregate return.", signature);
        return R_NilValue;
      }
      char const *e = sig;
      int l = e - b;
      if (aggr_return_layout == R_NilValue || aggr_return == NULL) {
        Rf_error("internal error: missing aggregate return layout");
        return R_NilValue;
      }
      if ((int) strlen(rdyncall_layout_name(aggr_return_layout)) != l ||
          strncmp(rdyncall_layout_name(aggr_return_layout), b, l) != 0) {
        Rf_error("internal error: aggregate return layout type does not match signature");
        return R_NilValue;
      }
      PROTECT(ans = Rf_allocVector(RAWSXP, rdyncall_layout_size(aggr_return_layout)));
      ans_protected = 1;
      rdyncall_set_struct_attrib(ans, rdyncall_layout_name(aggr_return_layout));
      /* Capture immediately around the native call, before any later R work can touch errno. */
      rdyncall_error_state_before(&error_state, use_errno, use_last_error);
      dcCallAggr(pvm, addr, aggr_return, RAW(ans));
      rdyncall_error_state_after(&error_state);
    } break;
    case '*':
    {
      ptrcnt = 1;
      while (*sig == '*') { ptrcnt++; sig++; }
      switch(*sig) {
        case '<': {
          /* struct/union pointers */
          DCpointer value;
          char buf[128];
          const char* begin = sig + 1;
          const char* end   = strchr(begin, '>');
          if (end == NULL) {
            Rf_error("Invalid signature '%s' - missing '>' marker for aggregate pointer return.", signature);
            return R_NilValue;
          }
          size_t n = end - begin;
          if (n == 0 || n >= sizeof(buf)) {
            Rf_error("Invalid signature '%s' - aggregate pointer return type name is too long.", signature);
            return R_NilValue;
          }
          memcpy(buf, begin, n);
          buf[n] = '\0';
          sig = end + 1;
          rdyncall_error_state_before(&error_state, use_errno, use_last_error);
          value = dcCallPointer(pvm, addr);
          rdyncall_error_state_after(&error_state);
          PROTECT(ans = R_MakeExternalPtr(value, R_NilValue, R_NilValue));
          ans_protected = 1;
          rdyncall_set_struct_attrib(ans, buf);
        } break;
        case 'C':
        case 'c': {
          DCpointer value;
          rdyncall_error_state_before(&error_state, use_errno, use_last_error);
          value = dcCallPointer(pvm, addr);
          rdyncall_error_state_after(&error_state);
          PROTECT(ans = Rf_mkString(value));
          ans_protected = 1;
        } break;
        case 'v': {
          DCpointer value;
          rdyncall_error_state_before(&error_state, use_errno, use_last_error);
          value = dcCallPointer(pvm, addr);
          rdyncall_error_state_after(&error_state);
          PROTECT(ans = R_MakeExternalPtr(value, R_NilValue, R_NilValue));
          ans_protected = 1;
        } break;
        default: Rf_error("Unsupported return type signature"); return R_NilValue;
      }
    } break;
    default: Rf_error("Unknown return type specification for signature '%s'.", signature);
             return R_NilValue; /* dummy */
  }

  rdyncall_free_aggrs(aggrs, aggr_count);
  if (ans_protected) UNPROTECT(1);
  return ans;
}
