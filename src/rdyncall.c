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
  SEXP        aggr_args;
  SEXP        aggr_return_layout;
  DCaggr*     aggr_return = NULL;
  int         ptrcnt;
  int         argpos;
  int         aggrpos;
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
    int mode = DC_CALL_C_DEFAULT;
    switch(ch)
    {
      case DC_SIGCHAR_CC_STDCALL:
        mode = DC_CALL_C_X86_WIN32_STD; break;
      case DC_SIGCHAR_CC_FASTCALL_GNU:
        mode = DC_CALL_C_X86_WIN32_FAST_GNU; break;
      case DC_SIGCHAR_CC_FASTCALL_MS:
        mode = DC_CALL_C_X86_WIN32_FAST_MS; break;
      default:
        Rf_error("Unknown calling convention prefix hint signature character '%c'", ch );
        /* dummy */ return R_NilValue;
    }
    dcMode(pvm, mode);
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

      if ( type_id != NILSXP && type_id != EXTPTRSXP && LENGTH(arg) == 0 ) {
        Rf_error("Argument type mismatch at position %d: expected length greater zero.", argpos);
        /* dummy */ return R_NilValue;
      }
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
          SEXP structName = Rf_getAttrib(arg, Rf_install("struct"));
          if (structName == R_NilValue) {
            Rf_error("typed pointer needed here");
            return R_NilValue; /* Dummy */
          }
          e = sig-1;
          l = e - b;
          n = CHAR(STRING_ELT(structName,0));
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
        switch(ch) {
          case DC_SIGCHAR_VOID:
            switch(type_id)
            {
              case NILSXP:    ptrValue = (DCpointer) 0; break;
              case STRSXP:    ptrValue = (DCpointer) CHAR(STRING_ELT(arg,0)); break;
              case LGLSXP:    ptrValue = (DCpointer) LOGICAL(arg); break;
              case INTSXP:    ptrValue = (DCpointer) INTEGER(arg); break;
              case REALSXP:   ptrValue = (DCpointer) REAL(arg); break;
              case CPLXSXP:   ptrValue = (DCpointer) COMPLEX(arg); break;
              case RAWSXP:    ptrValue = (DCpointer) RAW(arg); break;
              case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
              default:        Rf_error("Argument type mismatch at position %d: expected pointer convertable value", argpos);
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_CHAR:
          case DC_SIGCHAR_UCHAR:
            switch(type_id)
            {
              case NILSXP:    ptrValue = (DCpointer) 0; break;
              case STRSXP:
                if (ptrcnt == 1) {
                  ptrValue = (DCpointer) CHAR( STRING_ELT(arg,0) );
                } else {
                  Rf_error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos);
                  return R_NilValue; /* dummy */
                }
                break;
              case RAWSXP:
                if (ptrcnt == 1) {
                  ptrValue = RAW(arg);
                } else {
                  Rf_error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos);
                  return R_NilValue; /* dummy */
                }
                break;
              case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
              default:
                Rf_error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos);
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_USHORT:
          case DC_SIGCHAR_SHORT:
              Rf_error("Signature '*[sS]' not implemented");
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_UINT:
          case DC_SIGCHAR_INT:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case INTSXP:  ptrValue = (DCpointer) INTEGER(arg); break;
              default:      Rf_error("Argument type mismatch at position %d: expected 'pointer to C integer' convertable value", argpos);
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_ULONG:
          case DC_SIGCHAR_LONG:
              Rf_error("Signature '*[jJ]' not implemented");
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_ULONGLONG:
          case DC_SIGCHAR_LONGLONG:
              Rf_error("Signature '*[lJ]' not implemented");
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_FLOAT:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case RAWSXP:
                if ( strcmp( CHAR(STRING_ELT(Rf_getAttrib(arg, Rf_install("class")),0)),"floatraw") == 0 ) {
                  ptrValue = (DCpointer) RAW(arg);
                } else {
                  Rf_error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos);
                  return R_NilValue; /* dummy */
                }
                break;
              default:      Rf_error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos);
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_DOUBLE:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case REALSXP: ptrValue = (DCpointer) REAL(arg); break;
              default:      Rf_error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos);
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_POINTER:
          case DC_SIGCHAR_STRING:
            switch(type_id)
            {
              case EXTPTRSXP:
                ptrValue = R_ExternalPtrAddr( arg ); break;
              default: Rf_error("low-level typed pointer on pointer not implemented");
                return R_NilValue; /* dummy */
            }
            break;
          default:
            Rf_error("low-level typed pointer on C char pointer not implemented");
            return R_NilValue; /* dummy */
        }
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

  switch(*sig++) {
    case DC_SIGCHAR_BOOL:      ans = Rf_ScalarLogical( ( dcCallBool(pvm, addr) == DC_FALSE ) ? FALSE : TRUE ); break;

    case DC_SIGCHAR_CHAR:      ans = Rf_ScalarInteger( (int) dcCallChar(pvm, addr)  ); break;
    case DC_SIGCHAR_UCHAR:     ans = Rf_ScalarInteger( (int) ( (unsigned char) dcCallChar(pvm, addr ) ) ); break;

    case DC_SIGCHAR_SHORT:     ans = Rf_ScalarInteger( (int) dcCallShort(pvm,addr) ); break;
    case DC_SIGCHAR_USHORT:    ans = Rf_ScalarInteger( (int) ( (unsigned short) dcCallShort(pvm,addr) ) ); break;

    case DC_SIGCHAR_INT:       ans = Rf_ScalarInteger( dcCallInt(pvm,addr) ); break;
    case DC_SIGCHAR_UINT:      ans = Rf_ScalarReal( (double) (unsigned int) dcCallInt(pvm, addr) ); break;

    case DC_SIGCHAR_LONG:      ans = Rf_ScalarReal( (double) dcCallLong(pvm, addr) ); break;
    case DC_SIGCHAR_ULONG:     ans = Rf_ScalarReal( (double) ( (unsigned long) dcCallLong(pvm, addr) ) ); break;

    case DC_SIGCHAR_LONGLONG:  ans = Rf_ScalarReal( (double) dcCallLongLong(pvm, addr) ); break;
    case DC_SIGCHAR_ULONGLONG: ans = Rf_ScalarReal( (double) dcCallLongLong(pvm, addr) ); break;

    case DC_SIGCHAR_FLOAT:     ans = Rf_ScalarReal( (double) dcCallFloat(pvm,addr) ); break;
    case DC_SIGCHAR_DOUBLE:    ans = Rf_ScalarReal( dcCallDouble(pvm,addr) ); break;
    case DC_SIGCHAR_POINTER:   ans = R_MakeExternalPtr( dcCallPointer(pvm,addr), R_NilValue, R_NilValue ); break;
    case DC_SIGCHAR_STRING:    ans = Rf_mkString( dcCallPointer(pvm, addr) ); break;
    case DC_SIGCHAR_VOID:      dcCallVoid(pvm,addr); ans = R_NilValue; break;
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
      dcCallAggr(pvm, addr, aggr_return, RAW(ans));
    } break;
    case '*':
    {
      ptrcnt = 1;
      while (*sig == '*') { ptrcnt++; sig++; }
      switch(*sig) {
        case '<': {
          /* struct/union pointers */
          PROTECT(ans = R_MakeExternalPtr( dcCallPointer(pvm, addr), R_NilValue, R_NilValue ) );
          ans_protected = 1;
          char buf[128];
          const char* begin = ++sig;
          const char* end   = strchr(sig, '>');
          size_t n = end - begin;
          strncpy(buf, begin, n);
          buf[n] = '\0';
          rdyncall_set_struct_attrib(ans, buf);
        } break;
        case 'C':
        case 'c': {
          PROTECT(ans = Rf_mkString( dcCallPointer(pvm, addr) ) );
          ans_protected = 1;
        } break;
        case 'v': {
          PROTECT(ans = R_MakeExternalPtr( dcCallPointer(pvm, addr), R_NilValue, R_NilValue ) );
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
