#include "dyntype.h"
#include "dyncall.h"
#include "dyncall_signature.h"
#include <boost/type_traits/alignment_of.hpp>

using namespace boost;

extern "C" size_t dtAlign(const char* signature)
{
  char ch = *signature;
  switch(ch)
  {
    case DC_SIGCHAR_BOOL: return alignment_of<DCbool>::value;
    case DC_SIGCHAR_CHAR: return alignment_of<DCchar>::value;
    case DC_SIGCHAR_UCHAR: return alignment_of<DCuchar>::value;
    case DC_SIGCHAR_SHORT: return alignment_of<DCshort>::value;
    case DC_SIGCHAR_USHORT: return alignment_of<DCushort>::value;
    case DC_SIGCHAR_INT: return alignment_of<DCint>::value;
    case DC_SIGCHAR_UINT: return alignment_of<DCuint>::value;
    case DC_SIGCHAR_LONG: return alignment_of<DClong>::value;
    case DC_SIGCHAR_ULONG: return alignment_of<DCulong>::value;
    case DC_SIGCHAR_LONGLONG: return alignment_of<DClonglong>::value;
    case DC_SIGCHAR_ULONGLONG: return alignment_of<DCulonglong>::value;
    case DC_SIGCHAR_FLOAT: return alignment_of<DCfloat>::value;
    case DC_SIGCHAR_DOUBLE: return alignment_of<DCdouble>::value;
    case DC_SIGCHAR_POINTER: return alignment_of<DCpointer>::value;
    case DC_SIGCHAR_STRING: return alignment_of<DCstring>::value;
    case DC_SIGCHAR_VOID: return alignment_of<DCvoid>::value;
    default: return 0;
  }
}

extern "C" size_t dtSize(const char* signature)
{
  char ch = *signature;
  switch(ch)
  {
    case DC_SIGCHAR_BOOL: return sizeof(DCbool);
    case DC_SIGCHAR_CHAR: return sizeof(DCchar);
    case DC_SIGCHAR_UCHAR: return sizeof(DCuchar);
    case DC_SIGCHAR_SHORT: return sizeof(DCshort);
    case DC_SIGCHAR_USHORT: return sizeof(DCushort);
    case DC_SIGCHAR_INT: return sizeof(DCint);
    case DC_SIGCHAR_UINT: return sizeof(DCuint);
    case DC_SIGCHAR_LONG: return sizeof(DClong);
    case DC_SIGCHAR_ULONG: return sizeof(DCulong);
    case DC_SIGCHAR_LONGLONG: return sizeof(DClonglong);
    case DC_SIGCHAR_ULONGLONG: return sizeof(DCulonglong);
    case DC_SIGCHAR_FLOAT: return sizeof(DCfloat);
    case DC_SIGCHAR_DOUBLE: return sizeof(DCdouble);
    case DC_SIGCHAR_POINTER: return sizeof(DCpointer);
    case DC_SIGCHAR_STRING: return sizeof(DCstring);
    case DC_SIGCHAR_VOID: return 0;
    default: return 0;
  }
}

