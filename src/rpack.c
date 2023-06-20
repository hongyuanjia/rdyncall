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
  if (o < 0 || o+element_size > s) error("offset %d is out-of-bounds of the R object (max size %d)", o, s);
  return p + o; 
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
      int* Bp = (int*) C_dataptr(ptr_x, offset, sizeof(Rboolean));
      switch(type_of)
      {
        case LGLSXP:  *Bp = (int) LOGICAL(value_x)[0]; break;
        case INTSXP:  *Bp = (int) ( INTEGER(value_x)[0] == 0) ? 0 : 1; break;
        case REALSXP: *Bp = (int) ( REAL(value_x)[0] == 0.0) ? 0 : 1; break;
        case RAWSXP:  *Bp = (int) ( RAW(value_x)[0] == 0) ? 0 : 1; break;
	default: error("value mismatch with 'B' pack type");
      }
    }
    break;
    case DC_SIGCHAR_CHAR:
    {
      char* cp = (char*) C_dataptr(ptr_x, offset, sizeof(char));
	  switch(type_of)
	  {
	  case LGLSXP:  *cp = (char) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *cp = (char) INTEGER(value_x)[0]; break;
	  case REALSXP: *cp = (char) REAL(value_x)[0];    break;
	  case RAWSXP:  *cp = (char) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'c' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_UCHAR:
	{
	  unsigned char* cp = (unsigned char*) C_dataptr(ptr_x,offset,sizeof(unsigned char));
	  switch(type_of)
	  {
	  case LGLSXP:  *cp = (unsigned char) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *cp = (unsigned char) INTEGER(value_x)[0]; break;
	  case REALSXP: *cp = (unsigned char) REAL(value_x)[0];    break;
	  case RAWSXP:  *cp = (unsigned char) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'C' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_SHORT:
	{
	  short* sp = (short*) C_dataptr(ptr_x,offset,sizeof(short));
	  switch(type_of)
	  {
	  case LGLSXP:  *sp = (short) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *sp = (short) INTEGER(value_x)[0]; break;
	  case REALSXP: *sp = (short) REAL(value_x)[0];    break;
	  case RAWSXP:  *sp = (short) RAW(value_x)[0];     break;
	  default: error("value mismatch with 's' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_USHORT:
	{
	  unsigned short* sp = (unsigned short*) C_dataptr(ptr_x,offset,sizeof(unsigned short));
	  switch(type_of)
	  {
	  case LGLSXP:  *sp = (unsigned short) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *sp = (unsigned short) INTEGER(value_x)[0]; break;
	  case REALSXP: *sp = (unsigned short) REAL(value_x)[0];    break;
	  case RAWSXP:  *sp = (unsigned short) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'S' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_INT:
	{
	  int* ip = (int*) C_dataptr(ptr_x,offset,sizeof(int));
	  switch(type_of)
	  {
	  case LGLSXP:  *ip = (int) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *ip = (int) INTEGER(value_x)[0]; break;
	  case REALSXP: *ip = (int) REAL(value_x)[0];    break;
	  case RAWSXP:  *ip = (int) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'i' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_UINT:
	{
	  unsigned int* ip = (unsigned int*) C_dataptr(ptr_x,offset,sizeof(unsigned int));
	  switch(type_of)
	  {
	  case LGLSXP:  *ip = (unsigned int) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *ip = (unsigned int) INTEGER(value_x)[0]; break;
	  case REALSXP: *ip = (unsigned int) REAL(value_x)[0];    break;
	  case RAWSXP:  *ip = (unsigned int) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'I' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_LONG:
	{
	  long* ip = (long*) C_dataptr(ptr_x,offset,sizeof(long));
	  switch(type_of)
	  {
	  case LGLSXP:  *ip = (long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *ip = (long) INTEGER(value_x)[0]; break;
	  case REALSXP: *ip = (long) REAL(value_x)[0];    break;
	  case RAWSXP:  *ip = (long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'j' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_ULONG:
	{
	  unsigned long* ip = (unsigned long*) C_dataptr(ptr_x,offset,sizeof(unsigned long));
	  switch(type_of)
	  {
	  case LGLSXP:  *ip = (unsigned long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *ip = (unsigned long) INTEGER(value_x)[0]; break;
	  case REALSXP: *ip = (unsigned long) REAL(value_x)[0];    break;
	  case RAWSXP:  *ip = (unsigned long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'J' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_LONGLONG:
	{
	  long long* Lp = (long long*) C_dataptr(ptr_x,offset,sizeof(long long));
	  switch(type_of)
	  {
	  case LGLSXP:  *Lp = (long long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *Lp = (long long) INTEGER(value_x)[0]; break;
	  case REALSXP: *Lp = (long long) REAL(value_x)[0];    break;
	  case RAWSXP:  *Lp = (long long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'l' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_ULONGLONG:
	{
	  unsigned long long* Lp = (unsigned long long*) C_dataptr(ptr_x,offset,sizeof(unsigned long long));
	  switch(type_of)
	  {
	  case LGLSXP:  *Lp = (unsigned long long) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *Lp = (unsigned long long) INTEGER(value_x)[0]; break;
	  case REALSXP: *Lp = (unsigned long long) REAL(value_x)[0];    break;
	  case RAWSXP:  *Lp = (unsigned long long) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'L' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_FLOAT:
	{
	  float* fp = (float*) C_dataptr(ptr_x,offset,sizeof(float));
	  switch(type_of)
	  {
	  case LGLSXP:  *fp = (float) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *fp = (float) INTEGER(value_x)[0]; break;
	  case REALSXP: *fp = (float) REAL(value_x)[0];    break;
	  case RAWSXP:  *fp = (float) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'f' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_DOUBLE:
	{
	  double* dp = (double*) C_dataptr(ptr_x,offset,sizeof(double));
	  switch(type_of)
	  {
	  case LGLSXP:  *dp = (double) LOGICAL(value_x)[0]; break;
	  case INTSXP:  *dp = (double) INTEGER(value_x)[0]; break;
	  case REALSXP: *dp = (double) REAL(value_x)[0];    break;
	  case RAWSXP:  *dp = (double) RAW(value_x)[0];     break;
	  default: error("value mismatch with 'd' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_POINTER:
	case '*':
	{
	  void** pp = (void**) C_dataptr(ptr_x,offset,sizeof(void*));
	  switch(type_of)
	  {
	  case NILSXP:   *pp = (void*) 0; break;
	  case CHARSXP:  *pp = (void*) CHAR(value_x); break;
	  case LGLSXP:   *pp = (void*) LOGICAL(value_x); break;
	  case INTSXP:   *pp = (void*) INTEGER(value_x); break;
	  case REALSXP:  *pp = (void*) REAL(value_x); break;
	  case CPLXSXP:  *pp = (void*) COMPLEX(value_x); break;
	  case STRSXP:   *pp = (void*) CHAR( STRING_ELT(value_x,0) ); break;
	  case EXTPTRSXP:*pp = (void*) R_ExternalPtrAddr(value_x); break;
	  case RAWSXP:   *pp = (void*) RAW(value_x); break;
	  default: error("value type mismatch with 'p' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_STRING:
	{
	  char** Sp = (char**) C_dataptr(ptr_x,offset,sizeof(char*));
	  switch(type_of)
	  {
	  case NILSXP:   *Sp = (char*) NULL; break;
	  case CHARSXP:  *Sp = (char*) CHAR(value_x); break;
	  case STRSXP:   *Sp = (char*) CHAR( STRING_ELT(value_x,0) ); break;
	  case EXTPTRSXP:*Sp = (char*) R_ExternalPtrAddr(value_x); break;
	  default: error("value type mismatch with 'Z' pack type");
	  }
	}
	break;
	case DC_SIGCHAR_SEXP:
	{
	  SEXP* px = (SEXP*) C_dataptr(ptr_x,offset,sizeof(SEXP*));
	  *px = value_x;
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
  char* ptr = NULL;
  const char* sig = CHAR(STRING_ELT(sig_x,0) );
  switch(sig[0])
  {
    case DC_SIGCHAR_BOOL:
      ptr = C_dataptr(ptr_x,offset,sizeof(Rboolean));
      return ScalarLogical( ((int*)ptr)[0] );
    case DC_SIGCHAR_CHAR:     
      ptr = C_dataptr(ptr_x,offset,sizeof(char));
      return ScalarInteger( ( (char*)ptr)[0] );
    case DC_SIGCHAR_UCHAR:
      ptr = C_dataptr(ptr_x,offset,sizeof(unsigned char));
      return ScalarInteger( ( (unsigned char*)ptr)[0] );
    case DC_SIGCHAR_SHORT:
      ptr = C_dataptr(ptr_x,offset,sizeof(short));
      return ScalarInteger( ( (short*)ptr)[0] );
    case DC_SIGCHAR_USHORT:
      ptr = C_dataptr(ptr_x,offset,sizeof(unsigned short));
      return ScalarInteger( ( (unsigned short*)ptr)[0] );
    case DC_SIGCHAR_INT:
      ptr = C_dataptr(ptr_x,offset,sizeof(int));
      return ScalarInteger( ( (int*)ptr )[0] );
    case DC_SIGCHAR_UINT:
      ptr = C_dataptr(ptr_x,offset,sizeof(unsigned int));
      return ScalarReal( (double) ( (unsigned int*)ptr )[0] );
    case DC_SIGCHAR_LONG:
      ptr = C_dataptr(ptr_x,offset,sizeof(long));
      return ScalarReal( (double) ( (long*)ptr )[0] );
    case DC_SIGCHAR_ULONG:
      ptr = C_dataptr(ptr_x,offset,sizeof(unsigned long));
      return ScalarReal( (double) ( (unsigned long*) ptr )[0] );
    case DC_SIGCHAR_FLOAT:
      ptr = C_dataptr(ptr_x,offset,sizeof(float));
      return ScalarReal( (double) ( (float*) ptr )[0] );
    case DC_SIGCHAR_DOUBLE:
      ptr = C_dataptr(ptr_x,offset,sizeof(double));
      return ScalarReal( ((double*)ptr)[0] );
    case DC_SIGCHAR_LONGLONG:
      ptr = C_dataptr(ptr_x,offset,sizeof(long long));
      return ScalarReal( (double) ( ((long long*)ptr)[0] ) );
    case DC_SIGCHAR_ULONGLONG:
      ptr = C_dataptr(ptr_x,offset,sizeof(unsigned long long));
      return ScalarReal( (double) ( ((unsigned long long*)ptr)[0] ) );
    case '*':
    case DC_SIGCHAR_POINTER:  
      ptr = C_dataptr(ptr_x,offset,sizeof(void*));
      return R_MakeExternalPtr( ((void**)ptr)[0] , R_NilValue, R_NilValue );
    case DC_SIGCHAR_STRING:   {
      ptr = C_dataptr(ptr_x,offset,sizeof(char*));
    	char* s = ( (char**) ptr )[0];
		if (s == NULL) return R_MakeExternalPtr( 0, R_NilValue, R_NilValue );
		return mkString(s);
    }
    case DC_SIGCHAR_SEXP:     
      return (SEXP) ptr;
    default: error("invalid signature");
  }
  return R_NilValue;
}
