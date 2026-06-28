/** ===========================================================================
 ** R-Package: rdyncall
 ** File: src/rpack.c
 ** Description: (un-)packing of C structure data
 **/

// #define USE_RINTERNALS
#include <Rinternals.h>
#include <stdint.h>
#include <string.h>
#include <stddef.h>
#include <limits.h>
#include "rdyncall_signature.h"
/** ---------------------------------------------------------------------------
 ** C-Function: C_dataptr
 ** Description: retrieve the 'data' pointer on an R expression.
 ** R-Calling Convention: .Call
 **
 **/

static ptrdiff_t C_byte_size(R_xlen_t length, size_t element_size)
{
  if (element_size > 0 && length > (R_xlen_t) (PTRDIFF_MAX / (ptrdiff_t) element_size)) {
    error("R object is too large for pointer offset arithmetic");
  }
  return (ptrdiff_t) length * (ptrdiff_t) element_size;
}

static char* C_dataptr_offset(SEXP x, ptrdiff_t o, size_t element_size)
{
  char* p = NULL;
  ptrdiff_t s = 0;

  if (o < 0) error("offset must be a non-missing non-negative integer scalar");

  switch(TYPEOF(x))
  {
    case CHARSXP:   p = (char*) CHAR(x);    s = (ptrdiff_t) strlen(p); break;
    case LGLSXP:    p = (char*) LOGICAL(x); s = C_byte_size(XLENGTH(x), sizeof(Rboolean)); break;
    case INTSXP:    p = (char*) INTEGER(x); s = C_byte_size(XLENGTH(x), sizeof(int)); break;
    case REALSXP:   p = (char*) REAL(x);    s = C_byte_size(XLENGTH(x), sizeof(double)); break;
    case CPLXSXP:   p = (char*) COMPLEX(x); s = C_byte_size(XLENGTH(x), sizeof(Rcomplex)); break;
    case STRSXP:
      if (XLENGTH(x) == 0) error("value must have length greater zero");
      p = (char*) CHAR( STRING_ELT(x,0) );
      s = (ptrdiff_t) strlen(p);
      break;
    case RAWSXP:    p = (char*) RAW(x); s = C_byte_size(XLENGTH(x), sizeof(char)); break;
    case EXTPTRSXP:
      p = (char*) R_ExternalPtrAddr(x);
      if (p == NULL) error("NULL address pointer");
      return p + o;
    default: error("invalid object type"); break;
  }
  if (p == NULL) error("NULL address pointer");
  if (o > s || element_size > (size_t) (s - o)) error("offset %td is out-of-bounds of the R object (max size %td)", o, s);
  return p + o; 
}

static ptrdiff_t C_validate_offset(SEXP off)
{
  if (TYPEOF(off) != INTSXP || XLENGTH(off) < 1) error("offset must be a non-missing non-negative integer scalar");
  int value = INTEGER(off)[0];
  if (value == NA_INTEGER || value < 0) error("offset must be a non-missing non-negative integer scalar");
  return (ptrdiff_t) value;
}

static int C_validate_int_scalar(SEXP x, const char *name)
{
  if (TYPEOF(x) != INTSXP || XLENGTH(x) < 1 || INTEGER(x)[0] == NA_INTEGER) {
    error("%s must be a non-missing integer scalar", name);
  }
  return INTEGER(x)[0];
}

static const char* C_validate_sig(SEXP sig_x)
{
  if (TYPEOF(sig_x) != STRSXP || XLENGTH(sig_x) < 1 ||
      STRING_ELT(sig_x, 0) == NA_STRING) {
    error("sigchar must be a non-missing character scalar");
  }
  const char *sig = CHAR(STRING_ELT(sig_x, 0));
  if (sig[0] == '\0') error("sigchar must not be empty");
  return sig;
}

static void C_require_nonempty_vector(SEXP x, const char *name)
{
  switch(TYPEOF(x))
  {
    case LGLSXP:
    case INTSXP:
    case REALSXP:
    case CPLXSXP:
    case STRSXP:
    case RAWSXP:
      if (XLENGTH(x) == 0) error("%s must have length greater zero", name);
      break;
    default:
      break;
  }
}

static char* C_dataptr(SEXP x, SEXP off, size_t element_size)
{
  return C_dataptr_offset(x, C_validate_offset(off), element_size);
}

static void C_store(SEXP x, SEXP off, const void* value, size_t size)
{
  memcpy(C_dataptr(x, off, size), value, size);
}

static void C_load(SEXP x, SEXP off, void* value, size_t size)
{
  memcpy(value, C_dataptr(x, off, size), size);
}

static int C_bit_index_in_byte(int bit)
{
#if defined(__BYTE_ORDER__) && defined(__ORDER_BIG_ENDIAN__) && (__BYTE_ORDER__ == __ORDER_BIG_ENDIAN__)
  return 7 - bit;
#else
  return bit;
#endif
}

static uint64_t C_bitfield_mask(int width)
{
  if (width >= 64) return UINT64_MAX;
  return (UINT64_C(1) << width) - UINT64_C(1);
}

static uint64_t C_read_bitfield_bits(const unsigned char* ptr, int bit_offset, int width)
{
  uint64_t value = 0;
  for (int i = 0; i < width; ++i) {
    int absolute_bit = bit_offset + i;
    int byte_index = absolute_bit / 8;
    int bit_index = C_bit_index_in_byte(absolute_bit % 8);
    if (ptr[byte_index] & (1u << bit_index)) {
      value |= (UINT64_C(1) << i);
    }
  }
  return value;
}

static void C_write_bitfield_bits(unsigned char* ptr, int bit_offset, int width, uint64_t value)
{
  for (int i = 0; i < width; ++i) {
    int absolute_bit = bit_offset + i;
    int byte_index = absolute_bit / 8;
    int bit_index = C_bit_index_in_byte(absolute_bit % 8);
    unsigned char mask = (unsigned char) (1u << bit_index);
    if (value & (UINT64_C(1) << i)) {
      ptr[byte_index] = (unsigned char) (ptr[byte_index] | mask);
    } else {
      ptr[byte_index] = (unsigned char) (ptr[byte_index] & ~mask);
    }
  }
}

static int C_bitfield_sig_is_signed(char sig)
{
  return sig == DC_SIGCHAR_CHAR ||
         sig == DC_SIGCHAR_SHORT ||
         sig == DC_SIGCHAR_INT ||
         sig == DC_SIGCHAR_LONG ||
         sig == DC_SIGCHAR_LONGLONG;
}

static uint64_t C_bitfield_value(SEXP value_x, int is_signed)
{
  C_require_nonempty_vector(value_x, "value");
  switch(TYPEOF(value_x))
  {
    case LGLSXP:
      return (uint64_t) LOGICAL(value_x)[0];
    case INTSXP:
      return is_signed ? (uint64_t) ((int64_t) INTEGER(value_x)[0]) :
                         (uint64_t) ((uint32_t) INTEGER(value_x)[0]);
    case REALSXP:
      return is_signed ? (uint64_t) ((int64_t) REAL(value_x)[0]) :
                         (uint64_t) REAL(value_x)[0];
    case RAWSXP:
      return (uint64_t) RAW(value_x)[0];
    default:
      error("value mismatch with bitfield pack type");
  }
  return 0;
}

SEXP C_unpack_bitfield(SEXP ptr_x, SEXP bit_offset_x, SEXP bit_width_x, SEXP sig_x)
{
  int bit_offset = C_validate_int_scalar(bit_offset_x, "bit offset");
  int width = C_validate_int_scalar(bit_width_x, "bit width");
  const char sig = C_validate_sig(sig_x)[0];
  if (bit_offset < 0) error("bit offset must be non-negative");
  if (width < 1 || width > 64) error("bit width must be between 1 and 64");
  if (bit_offset > INT_MAX - width - 7) error("bitfield range is too large");
  int byte_offset = bit_offset / 8;
  int intra_bit_offset = bit_offset % 8;
  size_t byte_count = (size_t) ((intra_bit_offset + width + 7) / 8);
  unsigned char* ptr = (unsigned char*) C_dataptr_offset(ptr_x, byte_offset, byte_count);
  uint64_t raw = C_read_bitfield_bits(ptr, intra_bit_offset, width);

  if (sig == DC_SIGCHAR_BOOL) {
    return ScalarLogical(raw != 0);
  }

  if (C_bitfield_sig_is_signed(sig)) {
    int64_t value;
    if (width < 64 && (raw & (UINT64_C(1) << (width - 1)))) {
      value = (int64_t) (raw | ~C_bitfield_mask(width));
    } else {
      value = (int64_t) raw;
    }
    switch(sig) {
      case DC_SIGCHAR_CHAR:
      case DC_SIGCHAR_SHORT:
      case DC_SIGCHAR_INT:
        return ScalarInteger((int) value);
      case DC_SIGCHAR_LONG:
      case DC_SIGCHAR_LONGLONG:
        return ScalarReal((double) value);
    }
  }

  switch(sig) {
    case DC_SIGCHAR_UCHAR:
    case DC_SIGCHAR_USHORT:
      return ScalarInteger((int) raw);
    case DC_SIGCHAR_UINT:
    case DC_SIGCHAR_ULONG:
    case DC_SIGCHAR_ULONGLONG:
      return ScalarReal((double) raw);
    default:
      error("invalid bitfield signature");
  }

  return R_NilValue;
}

SEXP C_pack_bitfield(SEXP ptr_x, SEXP bit_offset_x, SEXP bit_width_x, SEXP sig_x, SEXP value_x)
{
  int bit_offset = C_validate_int_scalar(bit_offset_x, "bit offset");
  int width = C_validate_int_scalar(bit_width_x, "bit width");
  const char sig = C_validate_sig(sig_x)[0];
  if (bit_offset < 0) error("bit offset must be non-negative");
  if (width < 1 || width > 64) error("bit width must be between 1 and 64");
  if (bit_offset > INT_MAX - width - 7) error("bitfield range is too large");
  int byte_offset = bit_offset / 8;
  int intra_bit_offset = bit_offset % 8;
  size_t byte_count = (size_t) ((intra_bit_offset + width + 7) / 8);
  unsigned char* ptr = (unsigned char*) C_dataptr_offset(ptr_x, byte_offset, byte_count);
  uint64_t value = C_bitfield_value(value_x, C_bitfield_sig_is_signed(sig));

  C_write_bitfield_bits(ptr, intra_bit_offset, width, value & C_bitfield_mask(width));
  return R_NilValue;
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
  const char* sig = C_validate_sig(sig_x);
  if (sig[0] != DC_SIGCHAR_SEXP) C_require_nonempty_vector(value_x, "value");
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
  const char* sig = C_validate_sig(sig_x);
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
