/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rpack.c
 ** Description: (un-)packing of C structure data
 ** TODO
 ** - support for bitfields
 **/

// #define USE_RINTERNALS
#include <Rinternals.h>
#include <string.h>
#include <stddef.h>
#include "rdyncall_signature.h"
/** ---------------------------------------------------------------------------
 ** C-Function: C_dataptr
 ** Description: retrieve the 'data' pointer on an R expression.
 ** R-Calling Convention: .Call
 **
 **/

static char* C_dataptr(SEXP x, SEXP off, size_t element_size)
{
  if ( LENGTH(off) == 0 ) error("missing offset");
  char* p = NULL;
  ptrdiff_t o = INTEGER(off)[0], s = 0;
  
  switch(TYPEOF(x))
  {
    case CHARSXP:   p = (char*) CHAR(x);    s = LENGTH(x)*sizeof(char); break;
    case LGLSXP:    p = (char*) LOGICAL(x); s = LENGTH(x)*sizeof(Rboolean); break;
    case INTSXP:    p = (char*) INTEGER(x); s = LENGTH(x)*sizeof(int); break;
    case REALSXP:   p = (char*) REAL(x);    s = LENGTH(x)*sizeof(double); break;
    case CPLXSXP:   p = (char*) COMPLEX(x); s = LENGTH(x)*sizeof(Rcomplex); break; 
    case STRSXP:    p = (char*) CHAR( STRING_ELT(x,0) ); s = strlen(p)*sizeof(char); break;
    case RAWSXP:    p = (char*) RAW(x); s = LENGTH(x)*sizeof(char); break;
    case EXTPTRSXP: return (char*) R_ExternalPtrAddr(x) + o; break;
    default: error("invalid object type"); break;
  }
  if (p == NULL) error("NULL address pointer");
  if (o < 0 || o+element_size > s) error("offset %td is out-of-bounds of the R object (max size %td)", o, s);
  return p + o; 
}

static void C_store(SEXP x, SEXP off, const void* value, size_t size)
{
  memcpy(C_dataptr(x, off, size), value, size);
}

static void C_load(SEXP x, SEXP off, void* value, size_t size)
{
  memcpy(value, C_dataptr(x, off, size), size);
}



/** ---------------------------------------------------------------------------
 ** C-Function: C_pack
 ** Description: pack R data type into a C data type
 ** R-Calling Convention: .Call
 **
 **/
SEXP C_pack(SEXP ptr_x, SEXP offset, SEXP sig_x, SEXP value_x)
{
  int type_of = TYPEOF(value_x);
  const char* sig = CHAR(STRING_ELT(sig_x,0) );
  switch(sig[0])
  {
    case DC_SIGCHAR_BOOL:
    {
      Rboolean Bv;
      switch(type_of)
      {
        case LGLSXP:  Bv = (Rboolean) LOGICAL(value_x)[0]; break;
        case INTSXP:  Bv = (Rboolean) ((INTEGER(value_x)[0] == 0) ? 0 : 1); break;
        case REALSXP: Bv = (Rboolean) ((REAL(value_x)[0] == 0.0) ? 0 : 1); break;
        case RAWSXP:  Bv = (Rboolean) ((RAW(value_x)[0] == 0) ? 0 : 1); break;
	default: error("value mismatch with 'B' pack type");
      }
      C_store(ptr_x, offset, &Bv, sizeof(Bv));
    }
    break;
    case DC_SIGCHAR_CHAR:
    {
      char cv;
	  switch(type_of)
	  {
	  case LGLSXP:  cv = (char) LOGICAL(value_x)[0]; break;
	  case INTSXP:  cv = (char) INTEGER(value_x)[0]; break;
	  case REALSXP: cv = (char) REAL(value_x)[0];    break;
	  case RAWSXP:  cv = (char) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'c' pack type");
	  }
      C_store(ptr_x, offset, &cv, sizeof(cv));
	}
	break;
	case DC_SIGCHAR_UCHAR:
	{
	  unsigned char cv;
	  switch(type_of)
	  {
	  case LGLSXP:  cv = (unsigned char) LOGICAL(value_x)[0]; break;
	  case INTSXP:  cv = (unsigned char) INTEGER(value_x)[0]; break;
	  case REALSXP: cv = (unsigned char) REAL(value_x)[0];    break;
	  case RAWSXP:  cv = (unsigned char) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'C' pack type");
	  }
      C_store(ptr_x, offset, &cv, sizeof(cv));
	}
	break;
	case DC_SIGCHAR_SHORT:
	{
	  short sv;
	  switch(type_of)
	  {
	  case LGLSXP:  sv = (short) LOGICAL(value_x)[0]; break;
	  case INTSXP:  sv = (short) INTEGER(value_x)[0]; break;
	  case REALSXP: sv = (short) REAL(value_x)[0];    break;
	  case RAWSXP:  sv = (short) RAW(value_x)[0];     break;
	  default: error("value mismatch with 's' pack type");
	  }
      C_store(ptr_x, offset, &sv, sizeof(sv));
	}
	break;
	case DC_SIGCHAR_USHORT:
	{
	  unsigned short sv;
	  switch(type_of)
	  {
	  case LGLSXP:  sv = (unsigned short) LOGICAL(value_x)[0]; break;
	  case INTSXP:  sv = (unsigned short) INTEGER(value_x)[0]; break;
	  case REALSXP: sv = (unsigned short) REAL(value_x)[0];    break;
	  case RAWSXP:  sv = (unsigned short) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'S' pack type");
	  }
      C_store(ptr_x, offset, &sv, sizeof(sv));
	}
	break;
	case DC_SIGCHAR_INT:
	{
	  int iv;
	  switch(type_of)
	  {
	  case LGLSXP:  iv = (int) LOGICAL(value_x)[0]; break;
	  case INTSXP:  iv = (int) INTEGER(value_x)[0]; break;
	  case REALSXP: iv = (int) REAL(value_x)[0];    break;
	  case RAWSXP:  iv = (int) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'i' pack type");
	  }
      C_store(ptr_x, offset, &iv, sizeof(iv));
	}
	break;
	case DC_SIGCHAR_UINT:
	{
	  unsigned int iv;
	  switch(type_of)
	  {
	  case LGLSXP:  iv = (unsigned int) LOGICAL(value_x)[0]; break;
	  case INTSXP:  iv = (unsigned int) INTEGER(value_x)[0]; break;
	  case REALSXP: iv = (unsigned int) REAL(value_x)[0];    break;
	  case RAWSXP:  iv = (unsigned int) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'I' pack type");
	  }
      C_store(ptr_x, offset, &iv, sizeof(iv));
	}
	break;
	case DC_SIGCHAR_LONG:
	{
	  long lv;
	  switch(type_of)
	  {
	  case LGLSXP:  lv = (long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  lv = (long) INTEGER(value_x)[0]; break;
	  case REALSXP: lv = (long) REAL(value_x)[0];    break;
	  case RAWSXP:  lv = (long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'j' pack type");
	  }
      C_store(ptr_x, offset, &lv, sizeof(lv));
	}
	break;
	case DC_SIGCHAR_ULONG:
	{
	  unsigned long lv;
	  switch(type_of)
	  {
	  case LGLSXP:  lv = (unsigned long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  lv = (unsigned long) INTEGER(value_x)[0]; break;
	  case REALSXP: lv = (unsigned long) REAL(value_x)[0];    break;
	  case RAWSXP:  lv = (unsigned long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'J' pack type");
	  }
      C_store(ptr_x, offset, &lv, sizeof(lv));
	}
	break;
	case DC_SIGCHAR_LONGLONG:
	{
	  long long lv;
	  switch(type_of)
	  {
	  case LGLSXP:  lv = (long long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  lv = (long long) INTEGER(value_x)[0]; break;
	  case REALSXP: lv = (long long) REAL(value_x)[0];    break;
	  case RAWSXP:  lv = (long long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'l' pack type");
	  }
      C_store(ptr_x, offset, &lv, sizeof(lv));
	}
	break;
	case DC_SIGCHAR_ULONGLONG:
	{
	  unsigned long long lv;
	  switch(type_of)
	  {
	  case LGLSXP:  lv = (unsigned long long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  lv = (unsigned long long) INTEGER(value_x)[0]; break;
	  case REALSXP: lv = (unsigned long long) REAL(value_x)[0];    break;
	  case RAWSXP:  lv = (unsigned long long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'L' pack type");
	  }
      C_store(ptr_x, offset, &lv, sizeof(lv));
	}
	break;
	case DC_SIGCHAR_FLOAT:
	{
	  float fv;
	  switch(type_of)
	  {
	  case LGLSXP:  fv = (float) LOGICAL(value_x)[0]; break;
	  case INTSXP:  fv = (float) INTEGER(value_x)[0]; break;
	  case REALSXP: fv = (float) REAL(value_x)[0];    break;
	  case RAWSXP:  fv = (float) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'f' pack type");
	  }
      C_store(ptr_x, offset, &fv, sizeof(fv));
	}
	break;
	case DC_SIGCHAR_DOUBLE:
	{
	  double dv;
	  switch(type_of)
	  {
	  case LGLSXP:  dv = (double) LOGICAL(value_x)[0]; break;
	  case INTSXP:  dv = (double) INTEGER(value_x)[0]; break;
	  case REALSXP: dv = (double) REAL(value_x)[0];    break;
	  case RAWSXP:  dv = (double) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'd' pack type");
	  }
      C_store(ptr_x, offset, &dv, sizeof(dv));
	}
	break;
	case DC_SIGCHAR_POINTER:
	case '*':
	{
	  void* pv;
	  switch(type_of)
	  {
	  case NILSXP:   pv = (void*) 0; break;
	  case CHARSXP:  pv = (void*) CHAR(value_x); break;
	  case LGLSXP:   pv = (void*) LOGICAL(value_x); break;
	  case INTSXP:   pv = (void*) INTEGER(value_x); break;
	  case REALSXP:  pv = (void*) REAL(value_x); break;
	  case CPLXSXP:  pv = (void*) COMPLEX(value_x); break;
	  case STRSXP:   pv = (void*) CHAR( STRING_ELT(value_x,0) ); break;
	  case EXTPTRSXP:pv = (void*) R_ExternalPtrAddr(value_x); break;
	  case RAWSXP:   pv = (void*) RAW(value_x); break;
	  default: error("value type mismatch with 'p' pack type");
	  }
      C_store(ptr_x, offset, &pv, sizeof(pv));
	}
	break;
	case DC_SIGCHAR_STRING:
	{
	  char* sv;
	  switch(type_of)
	  {
	  case NILSXP:   sv = (char*) NULL; break;
	  case CHARSXP:  sv = (char*) CHAR(value_x); break;
	  case STRSXP:   sv = (char*) CHAR( STRING_ELT(value_x,0) ); break;
	  case EXTPTRSXP:sv = (char*) R_ExternalPtrAddr(value_x); break;
	  default: error("value type mismatch with 'Z' pack type");
	  }
      C_store(ptr_x, offset, &sv, sizeof(sv));
	}
	break;
	case DC_SIGCHAR_SEXP:
	{
      C_store(ptr_x, offset, &value_x, sizeof(value_x));
	}
	break;
	default: error("invalid signature");
  }
  return R_NilValue;
}

/** ---------------------------------------------------------------------------
 ** C-Function: C_unpack
 ** Description: unpack elements from C-like structures to R values.
 ** R-Calling Convention: .Call
 **
 **/
SEXP C_unpack(SEXP ptr_x, SEXP offset, SEXP sig_x)
{
  const char* sig = CHAR(STRING_ELT(sig_x,0) );
  switch(sig[0])
  {
    case DC_SIGCHAR_BOOL: {
      Rboolean v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarLogical(v);
    }
    case DC_SIGCHAR_CHAR: {
      char v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarInteger(v);
    }
    case DC_SIGCHAR_UCHAR: {
      unsigned char v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarInteger(v);
    }
    case DC_SIGCHAR_SHORT: {
      short v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarInteger(v);
    }
    case DC_SIGCHAR_USHORT: {
      unsigned short v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarInteger(v);
    }
    case DC_SIGCHAR_INT: {
      int v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarInteger(v);
    }
    case DC_SIGCHAR_UINT: {
      unsigned int v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case DC_SIGCHAR_LONG: {
      long v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case DC_SIGCHAR_ULONG: {
      unsigned long v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case DC_SIGCHAR_FLOAT: {
      float v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case DC_SIGCHAR_DOUBLE: {
      double v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal(v);
    }
    case DC_SIGCHAR_LONGLONG: {
      long long v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case DC_SIGCHAR_ULONGLONG: {
      unsigned long long v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return ScalarReal((double) v);
    }
    case '*':
    case DC_SIGCHAR_POINTER: {
      void* v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return R_MakeExternalPtr(v, R_NilValue, R_NilValue);
    }
    case DC_SIGCHAR_STRING:   {
      char* s;
      C_load(ptr_x, offset, &s, sizeof(s));
      if (s == NULL) return R_MakeExternalPtr(0, R_NilValue, R_NilValue);
      return mkString(s);
    }
    case DC_SIGCHAR_SEXP: {
      SEXP v;
      C_load(ptr_x, offset, &v, sizeof(v));
      return v;
    }
    default: error("invalid signature");
  }
  return R_NilValue;
}
