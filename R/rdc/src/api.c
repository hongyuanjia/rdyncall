#include <R.h>
#define USE_RINTERNALS
#include <Rinternals.h>
#include <R_ext/Rdynload.h>
#include "dynload.h"
#include "dyncall.h"
#include "dyncall_signature.h"


/* rdcLoad */

SEXP rdcLoad(SEXP sLibPath)
{
  void* libHandle;
  const char* libPath;
  SEXP r;
  libPath = CHAR(STRING_ELT(sLibPath,0));

  libHandle = dlLoadLibrary(libPath);

  if (!libHandle) {
    error("rdcLoad failed on path %s", libPath );
  }

  r = R_NilValue;

  PROTECT( r = R_MakeExternalPtr(libHandle, R_NilValue, R_NilValue) );
  UNPROTECT(1);

  return r;
}

/* rdcFree */

SEXP rdcFree(SEXP sLibHandle)
{
  void* libHandle;

  libHandle = R_ExternalPtrAddr(sLibHandle);
  dlFreeLibrary( libHandle );

  R_SetExternalPtrAddr(sLibHandle, 0);
  return R_NilValue;
}

/* rdcFind */

SEXP rdcFind(SEXP sLibHandle, SEXP sSymbol)
{
  void* libHandle;
  const char* symbol;
  void* addr;
  SEXP r;
  libHandle = R_ExternalPtrAddr(sLibHandle);
  symbol = CHAR(STRING_ELT(sSymbol,0) );
  addr = dlFindSymbol( libHandle, symbol );

  r = R_NilValue;

  PROTECT( r = R_MakeExternalPtr(addr, R_NilValue, R_NilValue) );
  UNPROTECT(1);

  return r;
}

SEXP r_dcCall(SEXP sCallVM, SEXP sFuncPtr, SEXP sSignature, SEXP sArgs)
{
  DCCallVM* pvm;
  void* funcPtr;
  const char* signature;
  const char* ptr;
  int i,l,protect_count;
  SEXP r;

  pvm = R_ExternalPtrAddr(sCallVM);
  if (!pvm) error("callvm is null");

  funcPtr = R_ExternalPtrAddr(sFuncPtr);
  if (!funcPtr) error("funcptr is null");

  signature = CHAR(STRING_ELT(sSignature,0) );
  if (!signature) error("signature is null");

  dcReset(pvm);
  ptr = signature;

  l = LENGTH(sArgs);
  i = 0;
  protect_count = 0;
  for(;;) {
    char ch = *ptr++;
    SEXP arg;

    if (ch == '\0') error("invalid signature - no return type specified");

    if (ch == ')') break;

    if (i >= l) error("not enough arguments for given signature (arg length = %d %d %c)", l,i,ch );

    arg = VECTOR_ELT(sArgs,i);
    switch(ch) {
      case DC_SIGCHAR_BOOL:
      {
    	DCbool value;
    	if ( isLogical(arg) )
    	{
    	  value = ( LOGICAL(arg)[0] == 0 ) ? DC_FALSE : DC_TRUE;
    	}
    	else
    	{
		  value = LOGICAL( coerceVector(arg, LGLSXP) )[0] ? DC_FALSE : DC_TRUE;
    	}
        dcArgBool(pvm, value );
        break;
      }
      case DC_SIGCHAR_INT:
      {
    	int value;
    	if ( isInteger(arg) )
    	{
    	  value = INTEGER(arg)[0];
    	}
    	else
    	{
    	  value = INTEGER( coerceVector(arg, INTSXP) )[0];
    	}
    	dcArgInt(pvm, value);
        break;
      }
      case DC_SIGCHAR_FLOAT:
      {
        dcArgFloat( pvm, (float) REAL( coerceVector(arg, REALSXP) )[0] );
        break;
      }
      case DC_SIGCHAR_DOUBLE:
      {
    	double value;
    	if ( isReal(arg) )
    	{
    		value = REAL(arg)[0];
    	}
    	else
    	{
			value = REAL( coerceVector(arg,REALSXP) )[0];
    	}
      	dcArgDouble( pvm, value );
      	break;
      }
      /*
      case DC_SIGCHAR_LONG:
      {
        PROTECT(arg = coerceVector(arg, REALSXP) );
        dcArgLong( pvm, (DClong) ( REAL(arg)[0] ) );
        UNPROTECT(1);
        break;
      }
      */
      case DC_SIGCHAR_STRING:
      {
        DCpointer ptr;
        if (arg == R_NilValue) ptr = (DCpointer) 0;
        else if (isString(arg)) ptr = (DCpointer) CHAR( STRING_ELT(arg,0) );
        else {
          if (protect_count) UNPROTECT(protect_count);
          error("invalid value for C string argument"); break;
        }
      }
      case DC_SIGCHAR_POINTER:
      {
        DCpointer ptr;
        if ( arg == R_NilValue )  ptr = (DCpointer) 0;
        else if (isString(arg) )  ptr = (DCpointer) CHAR( STRING_ELT(arg,0) );
        else if (isReal(arg) )    ptr = (DCpointer) REAL(arg);
        else if (isInteger(arg) ) ptr = (DCpointer) INTEGER(arg);
        else if (isLogical(arg) ) ptr = (DCpointer) LOGICAL(arg);
        else if (TYPEOF(arg) == EXTPTRSXP) ptr = R_ExternalPtrAddr(arg);
        else {
          if (protect_count) UNPROTECT(protect_count);
          error("invalid signature"); break;
        }
        dcArgPointer(pvm, ptr);
        break;
      }
    }
    ++i;
  }

  if ( i != l )
  {
    if (protect_count)
      UNPROTECT(protect_count);
    error ("signature claims to have %d arguments while %d arguments are given", i, l);
  }

  switch(*ptr) {
    case DC_SIGCHAR_BOOL:
      PROTECT( r = allocVector(LGLSXP, 1) ); protect_count++;
      LOGICAL(r)[0] = ( dcCallBool(pvm, funcPtr) == DC_FALSE ) ? FALSE : TRUE;
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_CHAR:
        PROTECT( r = allocVector(INTSXP, 1) ); protect_count++;
        INTEGER(r)[0] = dcCallChar(pvm, funcPtr);
        UNPROTECT(protect_count);
        return r;
    case DC_SIGCHAR_SHORT:
        PROTECT( r = allocVector(INTSXP, 1) ); protect_count++;
        INTEGER(r)[0] = dcCallShort(pvm, funcPtr);
        UNPROTECT(protect_count);
        return r;
    case DC_SIGCHAR_LONG:
        PROTECT( r = allocVector(INTSXP, 1) ); protect_count++;
        INTEGER(r)[0] = dcCallLong(pvm, funcPtr);
        UNPROTECT(protect_count);
        return r;
    case DC_SIGCHAR_INT:
      PROTECT( r = allocVector(INTSXP, 1) ); protect_count++;
      INTEGER(r)[0] = dcCallInt(pvm, funcPtr);
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_LONGLONG:
      PROTECT( r = allocVector(REALSXP, 1) ); protect_count++;
      REAL(r)[0] = (double) ( dcCallLong(pvm, funcPtr) );
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_FLOAT:
      PROTECT( r = allocVector(REALSXP, 1) ); protect_count++;
      REAL(r)[0] = (double) ( dcCallFloat(pvm, funcPtr) );
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_DOUBLE:
      PROTECT( r = allocVector(REALSXP, 1) );
      protect_count++;
      REAL(r)[0] = dcCallDouble(pvm, funcPtr);
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_POINTER:
      PROTECT( r = R_MakeExternalPtr( dcCallPointer(pvm,funcPtr), R_NilValue, R_NilValue ) );
      protect_count++;
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_VOID:
      dcCallVoid(pvm,funcPtr);
      if (protect_count) UNPROTECT(protect_count);
      break;
    default:
      {
        if (protect_count)
          UNPROTECT(protect_count);
        error("invalid return type signature");
      }
      break;
  }
  return R_NilValue;

}

/* rdcCall */

DCCallVM* gCall;

SEXP rdcCall(SEXP sFuncPtr, SEXP sSignature, SEXP sArgs)
{
  void* funcPtr;
  const char* signature;
  const char* ptr;
  int i,l,protect_count;
  SEXP r;

  funcPtr = R_ExternalPtrAddr(sFuncPtr);

  if (!funcPtr) error("funcptr is null");

  signature = CHAR(STRING_ELT(sSignature,0) );

  if (!signature) error("signature is null");

  dcReset(gCall);
  ptr = signature;

  l = LENGTH(sArgs);
  i = 0;
  protect_count = 0;
  for(;;) {
    char ch = *ptr++;
    SEXP arg;

    if (ch == '\0') error("invalid signature - no return type specified");

    if (ch == ')') break;

    if (i >= l) error("not enough arguments for given signature (arg length = %d %d %c)", l,i,ch );

    arg = VECTOR_ELT(sArgs,i);
    switch(ch) {
      case DC_SIGCHAR_BOOL:
      {
        if ( !isLogical(arg) )
        {
          PROTECT(arg = coerceVector(arg, LGLSXP));
          protect_count++;
        }
        dcArgBool(gCall, ( LOGICAL(arg)[0] == 0 ) ? DC_FALSE : DC_TRUE );
        // UNPROTECT(1);
        break;
      }
      case DC_SIGCHAR_INT:
      {
        if ( !isInteger(arg) )
        {
          PROTECT(arg = coerceVector(arg, INTSXP));
          protect_count++;
        }
        dcArgInt(gCall, INTEGER(arg)[0]);
        // UNPROTECT(1);
        break;
      }
      case DC_SIGCHAR_FLOAT:
      {
        PROTECT(arg = coerceVector(arg, REALSXP) );
        dcArgFloat( gCall, REAL(arg)[0] );
        UNPROTECT(1);
        break;
      }
      case DC_SIGCHAR_DOUBLE:
      {
        if ( !isReal(arg) )
        {
          PROTECT(arg = coerceVector(arg, REALSXP) );
          protect_count++;
        }
      	dcArgDouble( gCall, REAL(arg)[0] );
      	// UNPROTECT(1);
      	break;
      }
      /*
      case DC_SIGCHAR_LONG:
      {
        PROTECT(arg = coerceVector(arg, REALSXP) );
        dcArgLong( gCall, (DClong) ( REAL(arg)[0] ) );
        UNPROTECT(1);
        break;
      }
      */
      case DC_SIGCHAR_STRING:
      {
        DCpointer ptr;
        if (arg == R_NilValue) ptr = (DCpointer) 0;
        else if (isString(arg)) ptr = (DCpointer) CHAR( STRING_ELT(arg,0) );
        else {
          if (protect_count) UNPROTECT(protect_count);
          error("invalid value for C string argument"); break;
        }
      }
      case DC_SIGCHAR_POINTER:
      {
        DCpointer ptr;
        if ( arg == R_NilValue )  ptr = (DCpointer) 0;
        else if (isString(arg) )  ptr = (DCpointer) CHAR( STRING_ELT(arg,0) );
        else if (isReal(arg) )    ptr = (DCpointer) REAL(arg);
        else if (isInteger(arg) ) ptr = (DCpointer) INTEGER(arg);
        else if (isLogical(arg) ) ptr = (DCpointer) LOGICAL(arg);
        else if (TYPEOF(arg) == EXTPTRSXP) ptr = R_ExternalPtrAddr(arg);
        else {
          if (protect_count) UNPROTECT(protect_count);
          error("invalid signature"); break;
        }
        dcArgPointer(gCall, ptr);
        break;
      }
    }
    ++i;
  }

  if ( i != l )
  {
    if (protect_count)
      UNPROTECT(protect_count);
    error ("signature claims to have %d arguments while %d arguments are given", i, l);
  }

  switch(*ptr) {
    case DC_SIGCHAR_BOOL:
      PROTECT( r = allocVector(LGLSXP, 1) ); protect_count++;
      LOGICAL(r)[0] = ( dcCallBool(gCall, funcPtr) == DC_FALSE ) ? FALSE : TRUE;
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_INT:
      PROTECT( r = allocVector(INTSXP, 1) ); protect_count++;
      INTEGER(r)[0] = dcCallInt(gCall, funcPtr);
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_LONG:
      PROTECT( r = allocVector(REALSXP, 1) ); protect_count++;
      REAL(r)[0] = (double) ( dcCallLong(gCall, funcPtr) );
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_FLOAT:
      PROTECT( r = allocVector(REALSXP, 1) ); protect_count++;
      REAL(r)[0] = (double) ( dcCallFloat(gCall, funcPtr) );
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_DOUBLE:
      PROTECT( r = allocVector(REALSXP, 1) );
      protect_count++;
      REAL(r)[0] = dcCallDouble(gCall, funcPtr);
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_POINTER:
      PROTECT( r = R_MakeExternalPtr( dcCallPointer(gCall,funcPtr), R_NilValue, R_NilValue ) );
      protect_count++;
      UNPROTECT(protect_count);
      return r;
    case DC_SIGCHAR_VOID:
      dcCallVoid(gCall,funcPtr);
      if (protect_count) UNPROTECT(protect_count);
      break;
    default:
      {
        if (protect_count)
          UNPROTECT(protect_count);
        error("invalid return type signature");
      }
  }
  return R_NilValue;
}

SEXP rdcUnpack1(SEXP ptr_x, SEXP offset, SEXP sig_x)
{
  char* ptr = ( (char*) R_ExternalPtrAddr(ptr_x) ) + INTEGER(offset)[0];
  const char* sig = CHAR(STRING_ELT(sig_x,0) );
  switch(sig[0])
  {
    case DC_SIGCHAR_CHAR: return ScalarInteger( ( (unsigned char*)ptr)[0] );
    case DC_SIGCHAR_INT: return ScalarInteger( ( (int*)ptr )[0] );
    case DC_SIGCHAR_FLOAT: return ScalarReal( (double) ( (float*) ptr )[0] );
    case DC_SIGCHAR_DOUBLE: return ScalarReal( ((double*)ptr)[0] );
    default: error("invalid signature");
  }
  return R_NilValue;
}

SEXP rdcDataPtr(SEXP x, SEXP offset)
{
	void* ptr = ( ( (unsigned char*) DATAPTR(x) ) + INTEGER(offset)[0] );
	return R_MakeExternalPtr( ptr, R_NilValue, R_NilValue );
}

SEXP rdcMode(SEXP id)
{
  dcMode( gCall, INTEGER(id)[0] );
  dcReset( gCall );
  return R_NilValue;
}

SEXP r_dcNewCallVM(SEXP size)
{
  return R_MakeExternalPtr( dcNewCallVM( INTEGER(size)[0] ), R_NilValue, R_NilValue );
}

SEXP r_dcFree(SEXP callvm)
{
  DCCallVM* pvm = R_ExternalPtrAddr(callvm);
  dcFree(pvm);
  return R_NilValue;
}

SEXP r_dcMode(SEXP callvm, SEXP id)
{
  DCCallVM* pvm = R_ExternalPtrAddr(callvm);
  dcMode( pvm, INTEGER(id)[0] );
  dcReset( pvm );
  return R_NilValue;
}

/* register R to C calls */

R_CallMethodDef callMethods[] =
{
 {"rdcLoad", (DL_FUNC) &rdcLoad, 1},
 {"rdcFree", (DL_FUNC) &rdcFree, 1},
 {"rdcFind", (DL_FUNC) &rdcFind, 2},
 {"rdcCall", (DL_FUNC) &rdcCall, 3},
 {"rdcUnpack1", (DL_FUNC) &rdcUnpack1, 3},
 {"rdcDataPtr", (DL_FUNC) &rdcDataPtr, 2},
 {"rdcMode", (DL_FUNC) &rdcMode, 1},

 {"dcNewCallVM", (DL_FUNC) &r_dcNewCallVM, 1},
 {"dcFree", (DL_FUNC) &r_dcFree, 1},
 {"dcCall", (DL_FUNC) &r_dcCall, 4},
 {"dcMode", (DL_FUNC) &r_dcMode, 2},

 {NULL, NULL, 0}
};

void R_init_rdc(DllInfo *info)
{
  R_registerRoutines(info, NULL, callMethods, NULL, NULL);
  gCall = dcNewCallVM(4096);
}

void R_unload_rdc(DllInfo *info)
{
}

