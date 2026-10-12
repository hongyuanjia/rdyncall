/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rcallback.c
 ** Description: dyncall callback R backend
 **/

#include "Rinternals.h"
#include "Rdefines.h"
#include <R_ext/Memory.h>
#include "dyncall_callback.h"
#include "dyncall_aggregate.h"
#include "rdyncall_signature.h"
#include <string.h>

#define RDYNCALL_CALLBACK_MAX_AGGRS 256
#define RDYNCALL_CALLBACK_TAG "rdyncall.callback"

#if defined(DC__Feature_AggrByVal) && (defined(DC__Arch_AMD64) || defined(DC__Arch_ARM64))
#define RDYNCALL_HAS_CALLBACK_AGGR_BYVAL 1
#endif

typedef struct
{
  int         disabled;
  SEXP        signature_x;
  SEXP        fun;
  SEXP        rho;
  SEXP        state;
  SEXP        last_error;
  SEXP        aggr_typeinfos;
  int         nargs;
  int         naggrs;
  int         aggr_count;
  const char* signature; /* argument signature without call mode prefix */
  unsigned long invocations;
  unsigned long successful_invocations;
  unsigned long error_invocations;
  unsigned long disabled_invocations;
  const char* disable_reason;
  DCaggr**    callback_aggrs;
  DCaggr**    all_aggrs;
  void*       argument_scratch; /* Native drain storage; never allocate during fallback. */
  void*       zero_return; /* Preallocated: the failure path must not allocate in R. */
} R_Callback;

static SEXP rcallback_get_list_element(SEXP list, const char *name)
{
  if (TYPEOF(list) != VECSXP) return R_NilValue;
  SEXP names = Rf_getAttrib(list, R_NamesSymbol);
  if (names == R_NilValue) return R_NilValue;
  for (R_xlen_t i = 0; i < XLENGTH(list); i++) {
    if (strcmp(CHAR(STRING_ELT(names, i)), name) == 0) {
      return VECTOR_ELT(list, i);
    }
  }
  return R_NilValue;
}

static int rcallback_scalar_int(SEXP x, const char *name)
{
  if (TYPEOF(x) == INTSXP && XLENGTH(x) > 0) return INTEGER(x)[0];
  if (TYPEOF(x) == REALSXP && XLENGTH(x) > 0) return (int) REAL(x)[0];
  Rf_error("internal error: aggregate layout field '%s' is not an integer scalar", name);
  return 0;
}

static int rcallback_layout_size(SEXP layout)
{
  return rcallback_scalar_int(rcallback_get_list_element(layout, "size"), "size");
}

static int rcallback_layout_align(SEXP layout)
{
  return rcallback_scalar_int(rcallback_get_list_element(layout, "align"), "align");
}

static const char* rcallback_typeinfo_name(SEXP typeinfo)
{
  SEXP name = rcallback_get_list_element(typeinfo, "name");
  if (TYPEOF(name) != STRSXP || XLENGTH(name) < 1) {
    Rf_error("internal error: aggregate typeinfo is missing a name");
  }
  return CHAR(STRING_ELT(name, 0));
}

static DCsigchar rcallback_aggregate_field_sigchar(const char *type)
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

static DCaggr* rcallback_new_aggr(SEXP layout, DCaggr **aggrs, int *aggr_count)
{
  int size = rcallback_layout_size(layout);
  int alignment = rcallback_layout_align(layout);
  SEXP fields = rcallback_get_list_element(layout, "fields");
  SEXP field_layouts = rcallback_get_list_element(layout, "field_layouts");
  SEXP types = rcallback_get_list_element(fields, "type");
  SEXP offsets = rcallback_get_list_element(fields, "offset");
  SEXP array_lens = rcallback_get_list_element(fields, "array_len");

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
  if (*aggr_count >= RDYNCALL_CALLBACK_MAX_AGGRS) {
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
      DCaggr *sub_ag = rcallback_new_aggr(sub_layout, aggrs, aggr_count);
      dcAggrField(ag, DC_SIGCHAR_AGGREGATE, INTEGER(offsets)[i], (DCsize) array_len, sub_ag);
    } else {
      dcAggrField(ag, rcallback_aggregate_field_sigchar(type), INTEGER(offsets)[i], (DCsize) array_len);
    }
  }
  ag->alignment = (DCsize) alignment;
  dcCloseAggr(ag);
  return ag;
}

static void rcallback_free_aggrs(R_Callback *rdata)
{
  if (!rdata || !rdata->all_aggrs) return;
  for (int i = 0; i < rdata->aggr_count; i++) {
    if (rdata->all_aggrs[i]) dcFreeAggr(rdata->all_aggrs[i]);
  }
}

static void rcallback_set_struct_attrib(SEXP x, SEXP typeinfo)
{
  const char *name = rcallback_typeinfo_name(typeinfo);
  Rf_setAttrib(x, Rf_install("struct"), Rf_mkString(name));
  Rf_setAttrib(x, Rf_install("typeinfo"), typeinfo);
  Rf_setAttrib(x, R_ClassSymbol, Rf_mkString("struct"));
}

static int rcallback_expect_struct(SEXP x, SEXP typeinfo, int size)
{
  if (TYPEOF(x) != RAWSXP || XLENGTH(x) < size) return 0;

  SEXP struct_name = Rf_getAttrib(x, Rf_install("struct"));
  if (TYPEOF(struct_name) != STRSXP || XLENGTH(struct_name) < 1) return 0;

  const char *expected = rcallback_typeinfo_name(typeinfo);
  const char *actual = CHAR(STRING_ELT(struct_name, 0));
  return strcmp(actual, expected) == 0;
}

static SEXP C_callback_tag(void)
{
  return Rf_install(RDYNCALL_CALLBACK_TAG);
}

static int C_is_callback(SEXP callback)
{
  return TYPEOF(callback) == EXTPTRSXP &&
    R_ExternalPtrAddr(callback) != NULL &&
    R_ExternalPtrTag(callback) == C_callback_tag();
}

static R_Callback* C_callback_data(SEXP callback)
{
  DCCallback* cb;
  R_Callback* rdata;

  if (!C_is_callback(callback))
    Rf_error("not an rdyncall callback");

  cb = R_ExternalPtrAddr(callback);
  rdata = (R_Callback*) dcbGetUserData(cb);
  if (!rdata)
    Rf_error("not an rdyncall callback");

  return rdata;
}

static SEXP C_callback_last_error_object(R_Callback* rdata)
{
  SEXP last_error;

  if (!rdata)
    return R_NilValue;

  if (rdata->last_error != R_NilValue)
    return rdata->last_error;

  if (rdata->state == R_NilValue || TYPEOF(rdata->state) != ENVSXP)
    return R_NilValue;

  last_error = Rf_eval(Rf_install("last_error"), rdata->state);
  return last_error == R_UnboundValue ? R_NilValue : last_error;
}

static void C_callback_store_last_error(R_Callback* rdata, SEXP last_error)
{
  if (!rdata)
    return;

  if (rdata->last_error != R_NilValue)
    R_ReleaseObject(rdata->last_error);

  rdata->last_error = last_error;

  if (rdata->last_error != R_NilValue)
    R_PreserveObject(rdata->last_error);
}

static void C_callback_set_last_error(R_Callback* rdata, const char* message, const char* reason)
{
  SEXP last_error, names;

  if (!rdata)
    return;

  PROTECT(last_error = Rf_allocVector(VECSXP, 3));
  PROTECT(names = Rf_allocVector(STRSXP, 3));

  SET_STRING_ELT(names, 0, Rf_mkChar("message"));
  SET_STRING_ELT(names, 1, Rf_mkChar("class"));
  SET_STRING_ELT(names, 2, Rf_mkChar("reason"));
  Rf_setAttrib(last_error, R_NamesSymbol, names);

  SET_VECTOR_ELT(last_error, 0, Rf_mkString(message ? message : ""));
  SET_VECTOR_ELT(last_error, 1, Rf_mkString("rdyncall_callback_error"));
  SET_VECTOR_ELT(last_error, 2, Rf_mkString(reason ? reason : ""));

  C_callback_store_last_error(rdata, last_error);
  UNPROTECT(2);
}

static void C_callback_disable(R_Callback* rdata, const char* reason, const char* message)
{
  rdata->disabled = 1;
  rdata->disable_reason = reason;

  if (C_callback_last_error_object(rdata) == R_NilValue)
    C_callback_set_last_error(rdata, message, reason);
}

static void C_callback_disable_error(R_Callback* rdata, const char* reason, const char* message)
{
  /* Retain the interrupt classification captured by the R wrapper. */
  SEXP details = C_callback_last_error_object(rdata);
  SEXP stored_reason = rcallback_get_list_element(details, "reason");
  if (strcmp(reason, "r_error") == 0 && TYPEOF(stored_reason) == STRSXP &&
      XLENGTH(stored_reason) > 0 && strcmp(CHAR(STRING_ELT(stored_reason, 0)), "r_interrupt") == 0)
    reason = "r_interrupt";
  rdata->error_invocations++;
  C_callback_disable(rdata, reason, message);
}

static char C_callback_return_type(R_Callback* rdata, int* return_aggr_index)
{
  const char* ptr;
  int aggr_index = 0;

  if (return_aggr_index)
    *return_aggr_index = 0;
  if (!rdata || !rdata->signature)
    return DC_SIGCHAR_VOID;

  ptr = rdata->signature;
  while (*ptr && *ptr != ')') {
    if (*ptr == DC_SIGCHAR_AGGREGATE)
      aggr_index++;
    ptr++;
  }
  if (*ptr != ')')
    return DC_SIGCHAR_VOID;

  if (return_aggr_index)
    *return_aggr_index = aggr_index;
  return *(ptr + 1) ? *(ptr + 1) : DC_SIGCHAR_VOID;
}

/* Each invocation tracks its native cursor independently, including recursive calls. */
typedef struct {
  R_Callback* rdata;
  DCArgs* args;
  DCValue* result;
  char return_type;
  const char* next_argument;
} R_CallbackFrame;

/* Advance the opaque backend cursor to its return descriptor without allocating in R. */
static void rcallback_drain_arguments(R_CallbackFrame* frame)
{
  const char* ptr = frame->next_argument;
  while (*ptr && *ptr != ')') {
    switch (*ptr++) {
    case DC_SIGCHAR_BOOL: (void)dcbArgBool(frame->args); break;
    case DC_SIGCHAR_CHAR: (void)dcbArgChar(frame->args); break;
    case DC_SIGCHAR_UCHAR: (void)dcbArgUChar(frame->args); break;
    case DC_SIGCHAR_SHORT: (void)dcbArgShort(frame->args); break;
    case DC_SIGCHAR_USHORT: (void)dcbArgUShort(frame->args); break;
    case DC_SIGCHAR_INT: (void)dcbArgInt(frame->args); break;
    case DC_SIGCHAR_UINT: (void)dcbArgUInt(frame->args); break;
    case DC_SIGCHAR_LONG: (void)dcbArgLong(frame->args); break;
    case DC_SIGCHAR_ULONG: (void)dcbArgULong(frame->args); break;
    case DC_SIGCHAR_LONGLONG: (void)dcbArgLongLong(frame->args); break;
    case DC_SIGCHAR_ULONGLONG: (void)dcbArgULongLong(frame->args); break;
    case DC_SIGCHAR_FLOAT: (void)dcbArgFloat(frame->args); break;
    case DC_SIGCHAR_DOUBLE: (void)dcbArgDouble(frame->args); break;
    case DC_SIGCHAR_POINTER:
    case DC_SIGCHAR_STRING: (void)dcbArgPointer(frame->args); break;
    case DC_SIGCHAR_AGGREGATE:
      (void)dcbArgAggr(frame->args, frame->rdata->argument_scratch); break;
    default: return;
    }
    frame->next_argument = ptr;
  }
}

static char C_callback_zero_return(R_CallbackFrame* frame)
{
  R_Callback* rdata = frame->rdata;
  DCArgs* args = frame->args;
  DCValue* result = frame->result;
  int return_aggr_index = 0;
  char ch = C_callback_return_type(rdata, &return_aggr_index);

  switch (ch) {
  case DC_SIGCHAR_BOOL:      result->B = DC_FALSE; break;
  case DC_SIGCHAR_CHAR:      result->c = 0; break;
  case DC_SIGCHAR_UCHAR:     result->C = 0; break;
  case DC_SIGCHAR_SHORT:     result->s = 0; break;
  case DC_SIGCHAR_USHORT:    result->S = 0; break;
  case DC_SIGCHAR_INT:
  case DC_SIGCHAR_UINT:      result->i = 0; break;
  case DC_SIGCHAR_LONG:
  case DC_SIGCHAR_ULONG:     result->j = 0; break;
  case DC_SIGCHAR_LONGLONG:
  case DC_SIGCHAR_ULONGLONG: result->L = 0; break;
  case DC_SIGCHAR_FLOAT:     result->f = 0.0f; break;
  case DC_SIGCHAR_DOUBLE:    result->d = 0.0; break;
  case DC_SIGCHAR_POINTER:   result->p = NULL; break;
  case DC_SIGCHAR_STRING:    result->p = (DCpointer) ""; break;
  case DC_SIGCHAR_AGGREGATE:
    if (rdata && return_aggr_index < rdata->naggrs) {
      DCaggr *ag = rdata->callback_aggrs[return_aggr_index];
      (void) ag;
      rcallback_drain_arguments(frame);
      dcbReturnAggr(args, result, rdata->zero_return);
      break;
    }
    return DC_SIGCHAR_VOID;
  case DC_SIGCHAR_VOID:
  default:
    result->L = 0;
    break;
  }

  return ch;
}

/* Convert arguments, evaluate R, and convert results inside the protected frame. */
static char rcallback_invoke(R_CallbackFrame* frame)
{
	R_Callback* rdata;
	const char* ptr;
	int i,n;
	int aggr_index = 0;
	SEXP s, x, ans, item;
	char ch;

	rdata = frame->rdata;
	DCArgs* args = frame->args;
	DCValue* result = frame->result;

	rdata->invocations++;

	if (rdata->disabled) {
		rdata->disabled_invocations++;
		return C_callback_zero_return(frame);
	}

	ptr = rdata->signature;

	// allocate an nargs + 1 'call' language object
	//   first argument is function
	//   rest is arguments from callback
	n = 1 + rdata->nargs;

	PROTECT( s = Rf_allocVector(LANGSXP, n) );
	SETCAR( s, rdata->fun ); x = CDR(s);

	// fill up call object

	i = 1;
	for( ;; ++i) {
		int item_protected = 0;
		DCValue value;
		ch = *ptr++;
		if (ch == ')') break;
		if (i >= n) {
			C_callback_disable_error(rdata, "invalid_signature", "invalid callback signature");

			UNPROTECT(1);
			return C_callback_zero_return(frame);
		}
		switch(ch) {
		/* Native getters precede R allocation; fallback knows exactly what remains. */
		case DC_SIGCHAR_BOOL:
			value.B = dcbArgBool(args);
			frame->next_argument = ptr;
			item = ScalarLogical(value.B == DC_FALSE ? FALSE : TRUE); break;
		case DC_SIGCHAR_CHAR:
			value.c = dcbArgChar(args);
			frame->next_argument = ptr;
			item = ScalarInteger((int)value.c); break;
		case DC_SIGCHAR_UCHAR:
			value.C = dcbArgUChar(args);
			frame->next_argument = ptr;
			item = ScalarInteger((int)value.C); break;
		case DC_SIGCHAR_SHORT:
			value.s = dcbArgShort(args);
			frame->next_argument = ptr;
			item = ScalarInteger((int)value.s); break;
		case DC_SIGCHAR_USHORT:
			value.S = dcbArgUShort(args);
			frame->next_argument = ptr;
			item = ScalarInteger((int)value.S); break;
		case DC_SIGCHAR_INT:
			value.i = dcbArgInt(args);
			frame->next_argument = ptr;
			item = ScalarInteger(value.i); break;
		case DC_SIGCHAR_UINT:
			value.I = dcbArgUInt(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.I); break;
		case DC_SIGCHAR_LONG:
			value.j = dcbArgLong(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.j); break;
		case DC_SIGCHAR_ULONG:
			value.J = dcbArgULong(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.J); break;
		case DC_SIGCHAR_LONGLONG:
			value.l = dcbArgLongLong(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.l); break;
		case DC_SIGCHAR_ULONGLONG:
			value.L = dcbArgULongLong(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.L); break;
		case DC_SIGCHAR_FLOAT:
			value.f = dcbArgFloat(args);
			frame->next_argument = ptr;
			item = ScalarReal((double)value.f); break;
		case DC_SIGCHAR_DOUBLE:
			value.d = dcbArgDouble(args);
			frame->next_argument = ptr;
			item = ScalarReal(value.d); break;
		case DC_SIGCHAR_POINTER:
			value.p = dcbArgPointer(args);
			frame->next_argument = ptr;
			item = R_MakeExternalPtr(value.p, R_NilValue, R_NilValue); break;
		case DC_SIGCHAR_STRING:
			value.p = dcbArgPointer(args);
			frame->next_argument = ptr;
			item = mkString(value.p); break;
		case DC_SIGCHAR_AGGREGATE:
		{
			SEXP typeinfo;
			DCaggr *ag;
			if (aggr_index >= rdata->naggrs) {
				C_callback_disable_error(rdata, "invalid_signature", "invalid aggregate callback signature");

				UNPROTECT(1);
				return C_callback_zero_return(frame);
			}
			typeinfo = VECTOR_ELT(rdata->aggr_typeinfos, aggr_index);
			ag = rdata->callback_aggrs[aggr_index++];
			PROTECT(item = Rf_allocVector(RAWSXP, ag->size));
			item_protected = 1;
			void* consumed = dcbArgAggr(args, RAW(item));
			frame->next_argument = ptr;
			if (!consumed) {
				C_callback_disable_error(rdata, "unsupported_argument", "aggregate callback argument is unsupported by this backend");

				UNPROTECT(2);
				return C_callback_zero_return(frame);
			}
			rcallback_set_struct_attrib(item, typeinfo);
			break;
		}
		default:
		case '\0':
			C_callback_disable_error(rdata, "invalid_signature", "invalid callback signature");

			UNPROTECT(1);
			return C_callback_zero_return(frame);
		}
		SETCAR( x, item);
		if (item_protected) {
			UNPROTECT(1);
		}
		x = CDR(x);
	}

	/* evaluate expression */

	int error = 0;

	PROTECT( ans = R_tryEvalSilent( s, rdata->rho, &error ) );

	if (error)
	{
		C_callback_disable_error(rdata, "r_error", "an error occurred during callback invocation in R");

		UNPROTECT(2);
		return C_callback_zero_return(frame);
	}

	/* propagate return value */

	ch = *ptr;	/* scan return value type character */

	/* handle NULL and len(x) == 0 expressions special */
	if (ch == DC_SIGCHAR_VOID || (ans == R_NilValue) || (LENGTH(ans) == 0))
	{
		/* Empty scalar results retain their zero convention; aggregates require ABI marshalling. */
		if (ch == DC_SIGCHAR_AGGREGATE) {
			C_callback_disable_error(rdata, "invalid_return", "empty aggregate callback return");
			UNPROTECT(2);
			return C_callback_zero_return(frame);
		}
		C_callback_zero_return(frame);
	}
	else
	{
		switch(ch)
		{
		case DC_SIGCHAR_VOID:
			break;
		case DC_SIGCHAR_BOOL:
			switch( TYPEOF(ans) )
			{
			case INTSXP: result->B = (INTEGER(ans)[0] == 0 ) ? DC_FALSE : DC_TRUE; break;
			case LGLSXP: result->B = (LOGICAL(ans)[0] == FALSE ) ? DC_FALSE : DC_TRUE; break;
			default:     result->B = DC_FALSE; break;
			}
			break;
		case DC_SIGCHAR_CHAR:
		case DC_SIGCHAR_UCHAR:
		case DC_SIGCHAR_SHORT:
		case DC_SIGCHAR_USHORT:
		case DC_SIGCHAR_INT:
		case DC_SIGCHAR_UINT:
		case DC_SIGCHAR_LONG:
		case DC_SIGCHAR_ULONG:
			switch( TYPEOF(ans) )
			{
			case INTSXP:  result->i = INTEGER(ans)[0]; break;
			case REALSXP: result->i = (int) REAL(ans)[0]; break;
			default:      result->i = 0; break;
			}
			break;
		case DC_SIGCHAR_ULONGLONG:
		case DC_SIGCHAR_LONGLONG:
			switch( TYPEOF(ans) )
			{
			case INTSXP:  result->L = (long long) INTEGER(ans)[0]; break;
			case REALSXP: result->L = (long long) REAL(ans)[0]; break;
			default:      result->L = 0; break;
			}
			break;
		case DC_SIGCHAR_FLOAT:
			switch( TYPEOF(ans) )
			{
			case INTSXP:  result->f = (float) INTEGER(ans)[0]; break;
			case REALSXP: result->f = (float) REAL(ans)[0]; break;
			default:      result->f = 0.0f; break;
			}
			break;
		case DC_SIGCHAR_DOUBLE:
			switch( TYPEOF(ans) )
			{
			case INTSXP:  result->d = (double) INTEGER(ans)[0]; break;
			case REALSXP: result->d = REAL(ans)[0]; break;
			default:      result->d = 0.0; break;
			}
			break;
		case DC_SIGCHAR_POINTER:
			switch( TYPEOF(ans) )
			{
			case EXTPTRSXP: result->p = R_ExternalPtrAddr(ans); break;
			case INTSXP   : result->p = (DCpointer) (ptrdiff_t) (unsigned long long int) INTEGER(ans)[0]; break;
			case REALSXP  : result->p = (DCpointer) (ptrdiff_t) (unsigned long long int) REAL(ans)[0]; break;
			default:        result->p = NULL; break;
			}
			break;
		case DC_SIGCHAR_STRING:
			C_callback_disable_error(rdata, "unsupported_return", "callback string return values are not implemented");

			UNPROTECT(2);
			return C_callback_zero_return(frame);
		case DC_SIGCHAR_AGGREGATE:
		{
			SEXP typeinfo;
			DCaggr *ag;
			if (aggr_index >= rdata->naggrs) {
				C_callback_disable_error(rdata, "invalid_signature", "invalid aggregate callback return signature");

				UNPROTECT(2);
				return C_callback_zero_return(frame);
			}
			typeinfo = VECTOR_ELT(rdata->aggr_typeinfos, aggr_index);
			ag = rdata->callback_aggrs[aggr_index];
			if (!rcallback_expect_struct(ans, typeinfo, ag->size)) {
				C_callback_disable_error(rdata, "invalid_return", "aggregate callback return value has incompatible type or storage");

				UNPROTECT(2);
				return C_callback_zero_return(frame);
			}
			dcbReturnAggr(args, result, RAW(ans));
			break;
		}
		}
	}
	rdata->successful_invocations++;
	UNPROTECT(2);
	return ch;
}


/* R_ToplevelExec restores R contexts and protection stacks on any non-local exit. */
static void rcallback_protected_invoke(void* data)
{
  R_CallbackFrame* frame = (R_CallbackFrame*) data;
  frame->return_type = rcallback_invoke(frame);
}

/* Never let R errors, interrupts, allocations, or warning handlers unwind foreign code. */
char R_dcCallbackHandler(DCCallback* pcb, DCArgs* args, DCValue* result, void* userdata)
{
  (void) pcb;
  R_Callback* rdata = (R_Callback*) userdata;
  R_CallbackFrame frame = {rdata, args, result, DC_SIGCHAR_VOID, rdata->signature};
  if (!R_ToplevelExec(rcallback_protected_invoke, &frame)) {
    /* This recovery path uses only native writes and an allocation-free zero return. */
    if (!rdata->disabled) {
      rdata->disabled = 1;
      rdata->disable_reason = "boundary_error";
      rdata->error_invocations++;
    }
    return C_callback_zero_return(&frame);
  }
  return frame.return_type;
}

void R_callback_finalizer(SEXP x);

SEXP C_callback(SEXP sig_x, SEXP aggr_layouts_x, SEXP aggr_typeinfos_x, SEXP fun_x, SEXP rho_x, SEXP state_x)
{
  const char* signature;
  R_Callback* rdata;
  const char* ptr;
  char ch;
  R_xlen_t naggrs;

  if (TYPEOF(aggr_layouts_x) != VECSXP || TYPEOF(aggr_typeinfos_x) != VECSXP) {
    Rf_error("internal error: aggregate callback metadata must be lists");
  }
  naggrs = XLENGTH(aggr_layouts_x);
  if (XLENGTH(aggr_typeinfos_x) != naggrs) {
    Rf_error("internal error: aggregate callback metadata length mismatch");
  }
  if (naggrs > RDYNCALL_CALLBACK_MAX_AGGRS) {
    Rf_error("too many aggregate callback descriptors");
  }

  signature  = CHAR( STRING_ELT( sig_x, 0 ) );
  rdata = R_Calloc(1, R_Callback);
  rdata->disabled = 0;
  rdata->signature_x = sig_x;
  rdata->fun = fun_x;
  rdata->rho = rho_x;
  rdata->state = state_x;
  rdata->last_error = R_NilValue;
  rdata->aggr_typeinfos = aggr_typeinfos_x;
  rdata->naggrs = (int) naggrs;
  rdata->aggr_count = 0;
  rdata->disable_reason = NULL;
  rdata->callback_aggrs = NULL;
  rdata->all_aggrs = NULL;
  R_PreserveObject(rdata->signature_x);
  R_PreserveObject(rdata->fun);
  R_PreserveObject(rdata->rho);
  R_PreserveObject(rdata->state);
  R_PreserveObject(rdata->aggr_typeinfos);

  if (naggrs > 0) {
#if defined(RDYNCALL_HAS_CALLBACK_AGGR_BYVAL)
    rdata->callback_aggrs = R_Calloc(naggrs, DCaggr*);
    rdata->all_aggrs = R_Calloc(RDYNCALL_CALLBACK_MAX_AGGRS, DCaggr*);
    for (R_xlen_t i = 0; i < naggrs; i++) {
      rdata->callback_aggrs[i] = rcallback_new_aggr(VECTOR_ELT(aggr_layouts_x, i),
                                                     rdata->all_aggrs,
                                                     &rdata->aggr_count);
    }
#else
    R_ReleaseObject(rdata->signature_x);
    R_ReleaseObject(rdata->fun);
    R_ReleaseObject(rdata->rho);
    R_ReleaseObject(rdata->state);
    R_ReleaseObject(rdata->aggr_typeinfos);
    if (rdata->last_error != R_NilValue)
      R_ReleaseObject(rdata->last_error);
    R_Free(rdata);
    Rf_error("aggregate by-value callbacks are unsupported by this backend");
#endif
  }

  ptr = signature;
  // skip call mode signature
  if ( (ch=*ptr) == '_') {
    ptr += 2;
    ch=*ptr;
  }
  rdata->signature = ptr++;
  int nargs = 0;
  while( ch != ')') {
    nargs ++;
    ch = *ptr++;
  }
  rdata->nargs = nargs;
  /* Allocate aggregate fallback storage before any foreign callback can run. */
  int return_aggr_index = 0;
  if (C_callback_return_type(rdata, &return_aggr_index) == DC_SIGCHAR_AGGREGATE &&
      return_aggr_index < rdata->naggrs) {
    /* System V returns read whole 8-byte register slots, even for smaller structs. */
    size_t bytes = rdata->callback_aggrs[return_aggr_index]->size;
    bytes = (bytes + 7) & ~(size_t)7;
    rdata->zero_return = R_Calloc(bytes, char);
  }
  /* Draining skipped aggregate arguments needs the largest native argument storage. */
  size_t scratch_size = 0;
  for (int i = 0; i < return_aggr_index; i++) {
    if (rdata->callback_aggrs[i]->size > scratch_size)
      scratch_size = rdata->callback_aggrs[i]->size;
  }
  if (scratch_size) rdata->argument_scratch = R_Calloc(scratch_size, char);
  DCCallback* cb = naggrs > 0 ?
    dcbNewCallback2(signature, R_dcCallbackHandler, rdata, rdata->callback_aggrs) :
    dcbNewCallback(signature, R_dcCallbackHandler, rdata);
  if (!cb) {
    rcallback_free_aggrs(rdata);
    if (rdata->callback_aggrs) R_Free(rdata->callback_aggrs);
    if (rdata->all_aggrs) R_Free(rdata->all_aggrs);
    R_ReleaseObject(rdata->signature_x);
    R_ReleaseObject(rdata->fun);
    R_ReleaseObject(rdata->rho);
    R_ReleaseObject(rdata->state);
    R_ReleaseObject(rdata->aggr_typeinfos);
    if (rdata->last_error != R_NilValue)
      R_ReleaseObject(rdata->last_error);
    if (rdata->zero_return) R_Free(rdata->zero_return);
    if (rdata->argument_scratch) R_Free(rdata->argument_scratch);
    R_Free(rdata);
    Rf_error("failed to create callback");
  }
  SEXP ans = R_MakeExternalPtr( cb, C_callback_tag(), state_x );
  R_RegisterCFinalizerEx(ans, R_callback_finalizer, TRUE);
  return ans;
}

void R_callback_finalizer(SEXP x)
{
  DCCallback* cb = R_ExternalPtrAddr(x);
  if (!cb) return;
  R_Callback* rdata = dcbGetUserData(cb);
  R_ReleaseObject(rdata->signature_x);
  R_ReleaseObject(rdata->fun);
  R_ReleaseObject(rdata->rho);
  R_ReleaseObject(rdata->state);
  R_ReleaseObject(rdata->aggr_typeinfos);
  if (rdata->last_error != R_NilValue)
    R_ReleaseObject(rdata->last_error);
  rcallback_free_aggrs(rdata);
  if (rdata->callback_aggrs) R_Free(rdata->callback_aggrs);
  if (rdata->all_aggrs) R_Free(rdata->all_aggrs);
  if (rdata->zero_return) R_Free(rdata->zero_return);
  if (rdata->argument_scratch) R_Free(rdata->argument_scratch);
  R_Free(rdata);
  dcbFreeCallback(cb);
  R_ClearExternalPtr(x);
}

SEXP C_callback_status(SEXP callback)
{
  R_Callback* rdata = C_callback_data(callback);
  SEXP ans, names, last_error;

  PROTECT(ans = Rf_allocVector(VECSXP, 9));
  PROTECT(names = Rf_allocVector(STRSXP, 9));

  SET_STRING_ELT(names, 0, Rf_mkChar("active"));
  SET_STRING_ELT(names, 1, Rf_mkChar("disabled"));
  SET_STRING_ELT(names, 2, Rf_mkChar("signature"));
  SET_STRING_ELT(names, 3, Rf_mkChar("invocations"));
  SET_STRING_ELT(names, 4, Rf_mkChar("successful_invocations"));
  SET_STRING_ELT(names, 5, Rf_mkChar("error_invocations"));
  SET_STRING_ELT(names, 6, Rf_mkChar("disabled_invocations"));
  SET_STRING_ELT(names, 7, Rf_mkChar("disable_reason"));
  SET_STRING_ELT(names, 8, Rf_mkChar("last_error"));
  Rf_setAttrib(ans, R_NamesSymbol, names);

  SET_VECTOR_ELT(ans, 0, Rf_ScalarLogical(!rdata->disabled));
  SET_VECTOR_ELT(ans, 1, Rf_ScalarLogical(rdata->disabled));
  SET_VECTOR_ELT(ans, 2, Rf_duplicate(rdata->signature_x));
  SET_VECTOR_ELT(ans, 3, Rf_ScalarReal((double) rdata->invocations));
  SET_VECTOR_ELT(ans, 4, Rf_ScalarReal((double) rdata->successful_invocations));
  SET_VECTOR_ELT(ans, 5, Rf_ScalarReal((double) rdata->error_invocations));
  SET_VECTOR_ELT(ans, 6, Rf_ScalarReal((double) rdata->disabled_invocations));
  SET_VECTOR_ELT(ans, 7, rdata->disable_reason ? Rf_mkString(rdata->disable_reason) : R_NilValue);
  last_error = C_callback_last_error_object(rdata);
  SET_VECTOR_ELT(ans, 8, last_error == R_NilValue ? R_NilValue : Rf_duplicate(last_error));

  Rf_setAttrib(ans, R_ClassSymbol, Rf_mkString("callback_status"));

  UNPROTECT(2);
  return ans;
}

SEXP C_callback_is_active(SEXP callback)
{
  R_Callback* rdata = C_callback_data(callback);
  return Rf_ScalarLogical(!rdata->disabled);
}

SEXP C_callback_last_error(SEXP callback)
{
  R_Callback* rdata = C_callback_data(callback);
  SEXP last_error = C_callback_last_error_object(rdata);
  return last_error == R_NilValue ? R_NilValue : Rf_duplicate(last_error);
}
