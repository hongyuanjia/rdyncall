/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rdyncall.c
 ** Description: R bindings to dyncall
 **/

#include <Rinternals.h>
#include "dyncall.h"
#include "rdyncall_signature.h"
#include <string.h>
#include <ctype.h>

/** ---------------------------------------------------------------------------
 ** C-Function: new_callvm
 ** R-Interface: .Call
 **/

SEXP r_new_callvm(SEXP mode_x, SEXP size_x)
{
  /* default call mode is "cdecl" */
  int size_i = INTEGER(size_x)[0];

  const char* mode_S = CHAR( STRING_ELT( mode_x, 0 ) );

  int mode_i = DC_CALL_C_DEFAULT;
  if      (strcmp(mode_S,"default") == 0 || strcmp(mode_S,"cdecl") == 0) mode_i = DC_CALL_C_DEFAULT;
#if WIN32
  else if (strcmp(mode_S,"stdcall") == 0)	mode_i = DC_CALL_C_X86_WIN32_STD;
  else if (strcmp(mode_S,"thiscall") == 0) 	mode_i = DC_CALL_C_X86_WIN32_THIS_GNU;
  else if (strcmp(mode_S,"thiscall.gcc") == 0)  mode_i = DC_CALL_C_X86_WIN32_THIS_GNU;
  else if (strcmp(mode_S,"thiscall.msvc") == 0) mode_i = DC_CALL_C_X86_WIN32_THIS_MS;
  else if (strcmp(mode_S,"fastcall") == 0)      mode_i = DC_CALL_C_X86_WIN32_FAST_GNU;
  else if (strcmp(mode_S,"fastcall.msvc") == 0) mode_i = DC_CALL_C_X86_WIN32_FAST_MS;
  else if (strcmp(mode_S,"fastcall.gcc") == 0)  mode_i = DC_CALL_C_X86_WIN32_FAST_GNU;
#endif
/*
   else { error("invalid 'callmode'"); return R_NilValue; }
*/

  DCCallVM* pvm = dcNewCallVM(size_i);
  dcMode( pvm, mode_i );
  return R_MakeExternalPtr( pvm, R_NilValue, R_NilValue );
}

/** ---------------------------------------------------------------------------
 ** C-Function: free_callvm
 ** R-Interface: .Call
 **/

SEXP r_free_callvm(SEXP callvm_x)
{
  DCCallVM* callvm_p = (DCCallVM*) R_ExternalPtrAddr( callvm_x );
  dcFree( callvm_p );
  return R_NilValue;
}

/** ---------------------------------------------------------------------------
 ** C-Function: r_dyncall
 ** R-Interface: .External
 **/

SEXP r_dyncall(SEXP args) /* callvm, address, signature, args ... */
{
  DCCallVM*   pvm;
  void*       addr;
  const char* signature;
  const char* sig;
  SEXP        arg;
  int         ptrcnt;
  int         argpos;

  args = CDR(args);

  /* extract CallVM reference, address and signature */

  pvm  = (DCCallVM*) R_ExternalPtrAddr( CAR(args) ); args = CDR(args);

  switch(TYPEOF(CAR(args))) {
    case EXTPTRSXP:
      addr = R_ExternalPtrAddr( CAR(args) ); args = CDR(args);
      if (!addr) {
        error("Target address is null-pointer.");
        return R_NilValue; /* dummy */
      }
      break;
    default:
      error("Target address must be external pointer.");
      return R_NilValue; /* dummy */
  }
  signature = CHAR( STRING_ELT( CAR(args), 0 ) ); args = CDR(args);
  sig = signature;

  if (!pvm) {
    error("Argument 'callvm' is null");
    /* dummy */ return R_NilValue;
  }
  if (!addr) {
    error("Argument 'addr' is null");
    /* dummy */ return R_NilValue;
  }
  /* reset CallVM to initial state */

  dcReset(pvm);
  ptrcnt = 0;
  argpos = 0;

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
        error("Unknown calling convention prefix hint signature character '%c'", ch );
        /* dummy */ return R_NilValue;
    }
    dcMode(pvm, mode);
  }

  /* load arguments */
  for(;;) {

    char ch = *sig++;

    if (ch == '\0') { 
      error("Function-call signature '%s' is invalid - missing argument terminator character ')' and return type signature.", signature);
      /* dummy */ return R_NilValue;
    }
    /* argument terminator */
    if (ch == ')') break;

    /* end of arguments? */
    if (args == R_NilValue) {
      error("Not enough arguments for function-call signature '%s'.", signature);
      /* dummy */ return R_NilValue;
    }
    /* pointer counter */
    else if (ch == '*') { ptrcnt++; continue; }

    /* unpack next argument */
    arg = CAR(args); args = CDR(args);
    argpos++;

    int type_id = TYPEOF(arg);

    if (ptrcnt == 0) { /* base types */

      /* 'x' signature for passing language objects 'as-is' */
      if (ch == DC_SIGCHAR_SEXP) {
        dcArgPointer(pvm, (void*)arg);
        continue;
      }
      
      if ( type_id != NILSXP && type_id != EXTPTRSXP && LENGTH(arg) == 0 ) {
		error("Argument type mismatch at position %d: expected length greater zero.", argpos); 
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
            default:      error("Argument type mismatch at position %d: expected C bool convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C char convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C unsigned char convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C short convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C unsigned short convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C long convertable value", argpos);  /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C unsigned long convertable value", argpos);  /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C int convertable value", argpos); /*dummy*/ return R_NilValue; 
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
            default:      error("Argument type mismatch at position %d: expected C unsigned int convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C float convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C double convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C long long (int64_t) convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C unsigned long long (uint64_t) convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C pointer convertable value", argpos); /* dummy */ return R_NilValue;
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
            default:      error("Argument type mismatch at position %d: expected C string pointer convertable value", argpos); /* dummy */ return R_NilValue;
          }
          dcArgPointer(pvm, cstringValue);
        }
        break;
        default: error("Signature type mismatch at position %d: Unknown token '%c' at argument %d.", ch, argpos); /* dummy */ return R_NilValue;
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
          error("Invalid signature '%s' - missing '>' marker for structure at argument %d.", signature, argpos);
          return R_NilValue; /* Dummy */
        }
        sig++;
        /* check pointer type */
        if (type_id != NILSXP) {
          SEXP structName = getAttrib(arg, install("struct"));
          if (structName == R_NilValue) {
            error("typed pointer needed here");
            return R_NilValue; /* Dummy */
          }
          e = sig-1;
          l = e - b;
          n = CHAR(STRING_ELT(structName,0));
          if ( (strlen(n) != l) || (strncmp(b,n,l) != 0) ) {
            error("incompatible pointer types");
            return R_NilValue; /* Dummy */
          }
        }
        switch(type_id) {
          case NILSXP:    ptrValue = (DCpointer) 0; break;
          case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
          case RAWSXP:    ptrValue = (DCpointer) RAW(arg); break;
          default:        error("internal error: typed-pointer can be external pointers or raw only.");
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
              default:        error("Argument type mismatch at position %d: expected pointer convertable value", argpos); 
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
                  error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos); 
                  return R_NilValue; /* dummy */
                }
                break;
              case RAWSXP:
                if (ptrcnt == 1) {
                  ptrValue = RAW(arg);
                } else {
                  error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos); 
                  return R_NilValue; /* dummy */
                }
                break;
              case EXTPTRSXP: ptrValue = R_ExternalPtrAddr(arg); break;
              default:        
                error("Argument type mismatch at position %d: expected 'C string' convertable value", argpos); 
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_USHORT:
          case DC_SIGCHAR_SHORT:
              error("Signature '*[sS]' not implemented");
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_UINT:
          case DC_SIGCHAR_INT:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case INTSXP:  ptrValue = (DCpointer) INTEGER(arg); break;
              default:      error("Argument type mismatch at position %d: expected 'pointer to C integer' convertable value", argpos); 
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_ULONG:
          case DC_SIGCHAR_LONG:
              error("Signature '*[jJ]' not implemented"); 
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_ULONGLONG:
          case DC_SIGCHAR_LONGLONG:
              error("Signature '*[lJ]' not implemented"); 
              return R_NilValue; /* dummy */
          case DC_SIGCHAR_FLOAT:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case RAWSXP:
                if ( strcmp( CHAR(STRING_ELT(getAttrib(arg, install("class")),0)),"floatraw") == 0 ) {
                  ptrValue = (DCpointer) RAW(arg);
                } else {
                  error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos); 
                  return R_NilValue; /* dummy */
                }
                break;
              default:      error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos); 
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_DOUBLE:
            switch(type_id)
            {
              case NILSXP:  ptrValue = (DCpointer) 0; break;
              case REALSXP: ptrValue = (DCpointer) REAL(arg); break;
              default:      error("Argument type mismatch at position %d: expected 'pointer to C double' convertable value", argpos); 
                return R_NilValue; /* dummy */
            }
            break;
          case DC_SIGCHAR_POINTER:
          case DC_SIGCHAR_STRING:
            switch(type_id)
            {
              case EXTPTRSXP: 
                ptrValue = R_ExternalPtrAddr( arg ); break;
              default: error("low-level typed pointer on pointer not implemented");
                return R_NilValue; /* dummy */
            }
            break;
          default:
            error("low-level typed pointer on C char pointer not implemented");
            return R_NilValue; /* dummy */
        }
        dcArgPointer(pvm, ptrValue);
        ptrcnt = 0;
      }
    }
  }


  if (args != R_NilValue) {
    error ("Too many arguments for signature '%s'.", signature);
    return R_NilValue; /* dummy */
  }
  /* process return type, invoke call and return R value  */

  switch(*sig++) {
    case DC_SIGCHAR_BOOL:      return ScalarLogical( ( dcCallBool(pvm, addr) == DC_FALSE ) ? FALSE : TRUE );

    case DC_SIGCHAR_CHAR:      return ScalarInteger( (int) dcCallChar(pvm, addr)  );
    case DC_SIGCHAR_UCHAR:     return ScalarInteger( (int) ( (unsigned char) dcCallChar(pvm, addr ) ) );

    case DC_SIGCHAR_SHORT:     return ScalarInteger( (int) dcCallShort(pvm,addr) );
    case DC_SIGCHAR_USHORT:    return ScalarInteger( (int) ( (unsigned short) dcCallShort(pvm,addr) ) );

    case DC_SIGCHAR_INT:       return ScalarInteger( dcCallInt(pvm,addr) );
    case DC_SIGCHAR_UINT:      return ScalarReal( (double) (unsigned int) dcCallInt(pvm, addr) );

    case DC_SIGCHAR_LONG:      return ScalarReal( (double) dcCallLong(pvm, addr) );
    case DC_SIGCHAR_ULONG:     return ScalarReal( (double) ( (unsigned long) dcCallLong(pvm, addr) ) );

    case DC_SIGCHAR_LONGLONG:  return ScalarReal( (double) dcCallLongLong(pvm, addr) );
    case DC_SIGCHAR_ULONGLONG: return ScalarReal( (double) dcCallLongLong(pvm, addr) );

    case DC_SIGCHAR_FLOAT:     return ScalarReal( (double) dcCallFloat(pvm,addr) );
    case DC_SIGCHAR_DOUBLE:    return ScalarReal( dcCallDouble(pvm,addr) );
    case DC_SIGCHAR_POINTER:   return R_MakeExternalPtr( dcCallPointer(pvm,addr), R_NilValue, R_NilValue );
    case DC_SIGCHAR_STRING:    return mkString( dcCallPointer(pvm, addr) );
    case DC_SIGCHAR_VOID:      dcCallVoid(pvm,addr); /* TODO: return invisible */ return R_NilValue;
    case '*':
    {
      SEXP ans;
      ptrcnt = 1;
      while (*sig == '*') { ptrcnt++; sig++; }
      switch(*sig) {
        case '<': {
          /* struct/union pointers */
          PROTECT(ans = R_MakeExternalPtr( dcCallPointer(pvm, addr), R_NilValue, R_NilValue ) );
          char buf[128];
          const char* begin = ++sig;
          const char* end   = strchr(sig, '>');
          size_t n = end - begin;
          strncpy(buf, begin, n);
          buf[n] = '\0';
          setAttrib(ans, install("struct"), mkString(buf) );
          setAttrib(ans, install("class"), mkString("struct") ); 
        } break;
        case 'C':
        case 'c': {
          PROTECT(ans = mkString( dcCallPointer(pvm, addr) ) );
        } break;
        case 'v': {
          PROTECT(ans = R_MakeExternalPtr( dcCallPointer(pvm, addr), R_NilValue, R_NilValue ) );
        } break;
        default: error("Unsupported return type signature"); return R_NilValue;
      }
      UNPROTECT(1);
      return(ans);
    }
    default: error("Unknown return type specification for signature '%s'.", signature); 
             return R_NilValue; /* dummy */
  }

}

