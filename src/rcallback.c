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

#if defined(DC__Feature_AggrByVal) && (defined(DC__Arch_AMD64) || defined(DC__Arch_ARM64))
#define RDYNCALL_HAS_CALLBACK_AGGR_BYVAL 1
#endif

typedef struct
{
  int         disabled;
  SEXP        signature_x;
  SEXP        fun;
  SEXP        rho;
  SEXP        aggr_typeinfos;
  int         nargs;
  int         naggrs;
  int         aggr_count;
  const char* signature; /* argument signature without call mode prefix */
  DCaggr**    callback_aggrs;
  DCaggr**    all_aggrs;
} R_Callback;

static SEXP rcallback_get_list_element(SEXP list, const char *name)
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

char R_dcCallbackHandler( DCCallback* pcb, DCArgs* args, DCValue* result, void* userdata )
{
	R_Callback* rdata;
	const char* ptr;
	int i,n;
	int aggr_index = 0;
	SEXP s, x, ans, item;
	char ch;

	rdata = (R_Callback*) userdata;

	if (rdata->disabled) return DC_SIGCHAR_VOID;

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
		ch = *ptr++;
		if (ch == ')') break;
		if (i >= n) {
			warning("invalid signature.");
			rdata->disabled = 1;
			UNPROTECT(1);
			return DC_SIGCHAR_VOID;
		}
		switch(ch) {
		case DC_SIGCHAR_BOOL:      item = ScalarLogical( ( dcbArgBool(args) == DC_FALSE ) ? FALSE : TRUE ); break;
		case DC_SIGCHAR_CHAR:      item = ScalarInteger( (int) dcbArgChar(args) ); break;
		case DC_SIGCHAR_UCHAR:     item = ScalarInteger( (int) dcbArgUChar(args) ); break;
		case DC_SIGCHAR_SHORT:     item = ScalarInteger( (int) dcbArgShort(args) ); break;
		case DC_SIGCHAR_USHORT:    item = ScalarInteger( (int) dcbArgUShort(args) ); break;
		case DC_SIGCHAR_INT:       item = ScalarInteger( (int) dcbArgInt(args) ); break;
		case DC_SIGCHAR_UINT:      item = ScalarReal( (double) dcbArgUInt(args) ); break;
		case DC_SIGCHAR_LONG:      item = ScalarReal( (double) dcbArgLong(args) ); break;
		case DC_SIGCHAR_ULONG:     item = ScalarReal( (double) dcbArgULong(args) ); break;
		case DC_SIGCHAR_LONGLONG:  item = ScalarReal( (double) dcbArgLongLong(args) ); break;
		case DC_SIGCHAR_ULONGLONG: item = ScalarReal( (double) dcbArgULongLong(args) ); break;
		case DC_SIGCHAR_FLOAT:     item = ScalarReal( (double) dcbArgFloat(args) ); break;
		case DC_SIGCHAR_DOUBLE:    item = ScalarReal( dcbArgDouble(args) ); break;
		case DC_SIGCHAR_POINTER:   item = R_MakeExternalPtr( dcbArgPointer(args), R_NilValue, R_NilValue ); break;
		case DC_SIGCHAR_STRING:    item = mkString( dcbArgPointer(args) ); break;
		case DC_SIGCHAR_AGGREGATE:
		{
			SEXP typeinfo;
			DCaggr *ag;
			if (aggr_index >= rdata->naggrs) {
				warning("invalid aggregate callback signature");
				rdata->disabled = 1;
				UNPROTECT(1);
				return DC_SIGCHAR_VOID;
			}
			typeinfo = VECTOR_ELT(rdata->aggr_typeinfos, aggr_index);
			ag = rdata->callback_aggrs[aggr_index++];
			PROTECT(item = Rf_allocVector(RAWSXP, ag->size));
			item_protected = 1;
			if (!dcbArgAggr(args, RAW(item))) {
				warning("aggregate callback argument is unsupported by this backend");
				rdata->disabled = 1;
				UNPROTECT(2);
				return DC_SIGCHAR_VOID;
			}
			rcallback_set_struct_attrib(item, typeinfo);
			break;
		}
		default:
		case '\0':
			warning("invalid signature");
			rdata->disabled = 1;
			UNPROTECT(1);
			return DC_SIGCHAR_VOID;
		}
		SETCAR( x, item);
		if (item_protected) {
			UNPROTECT(1);
		}
		x = CDR(x);
	}

	/* evaluate expression */

	int error = 0;

	PROTECT( ans = R_tryEval( s, rdata->rho, &error ) );

	if (error)
	{
		warning("an error occurred during callback invocation in R. Callback disabled.");
		rdata->disabled = 1;
		UNPROTECT(2);
		return DC_SIGCHAR_VOID;
	}

	/* propagate return value */

	ch = *ptr;	/* scan return value type character */

	/* handle NULL and len(x) == 0 expressions special */
	if ( (ans == R_NilValue) || (LENGTH(ans) == 0) )
	{
		/* handle NULL */
		result->L = 0;
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
			warning("not implemented");
			rdata->disabled = 1;
			break;
		case DC_SIGCHAR_AGGREGATE:
		{
			SEXP typeinfo;
			DCaggr *ag;
			if (aggr_index >= rdata->naggrs) {
				warning("invalid aggregate callback return signature");
				rdata->disabled = 1;
				break;
			}
			typeinfo = VECTOR_ELT(rdata->aggr_typeinfos, aggr_index);
			ag = rdata->callback_aggrs[aggr_index];
			if (!rcallback_expect_struct(ans, typeinfo, ag->size)) {
				warning("aggregate callback return value has incompatible type or storage");
				rdata->disabled = 1;
				break;
			}
			dcbReturnAggr(args, result, RAW(ans));
			break;
		}
		}
	}
	UNPROTECT(2);
	return ch;
}

void R_callback_finalizer(SEXP x);

SEXP C_callback(SEXP sig_x, SEXP aggr_layouts_x, SEXP aggr_typeinfos_x, SEXP fun_x, SEXP rho_x)
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
  rdata->aggr_typeinfos = aggr_typeinfos_x;
  rdata->naggrs = (int) naggrs;
  rdata->aggr_count = 0;
  rdata->callback_aggrs = NULL;
  rdata->all_aggrs = NULL;
  R_PreserveObject(rdata->signature_x);
  R_PreserveObject(rdata->fun);
  R_PreserveObject(rdata->rho);
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
    R_ReleaseObject(rdata->aggr_typeinfos);
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
    R_ReleaseObject(rdata->aggr_typeinfos);
    R_Free(rdata);
    Rf_error("failed to create callback");
  }
  SEXP ans = R_MakeExternalPtr( cb, R_NilValue, R_NilValue );
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
  R_ReleaseObject(rdata->aggr_typeinfos);
  rcallback_free_aggrs(rdata);
  if (rdata->callback_aggrs) R_Free(rdata->callback_aggrs);
  if (rdata->all_aggrs) R_Free(rdata->all_aggrs);
  R_Free(rdata);
  dcbFreeCallback(cb);
  R_ClearExternalPtr(x);
}
