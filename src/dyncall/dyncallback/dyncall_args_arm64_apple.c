/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_arm64_apple.c
 Description: Callback's Arguments VM - Implementation for Apple's ARM64 / ARMv8 / AAPCS64
 License:

   Copyright (c) 2015-2022 Daniel Adler <dadler@uni-goettingen.de>,
                           Tassilo Philipp <tphilipp@potion-studios.com>

   Permission to use, copy, modify, and distribute this software for any
   purpose with or without fee is hereby granted, provided that the above
   copyright notice and this permission notice appear in all copies.

   THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
   WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
   MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
   ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
   WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
   ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
   OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

*/

#include "dyncall_args.h"
#include "dyncall_aggregate.h"

#include <stdint.h>
#include <string.h>

typedef union {
  struct { double value; } d;
  struct { float  value; } f;
} DCFPU_t;

struct DCArgs
{
  /* buffers and stack-pointer: */
  uint64_t  I[8];
  DCFPU_t   F[8];
  uint8_t*  sp;

  /* counters: */
  int i;
  int f;

  DCaggr** aggrs;
  DCpointer aggr_return_ptr;
};

static inline uint8_t* align(uint8_t* p, size_t v)
{
  return (uint8_t*) ( ( ( (ptrdiff_t) p ) + v - 1) & (ptrdiff_t) -v );
}


DClonglong dcbArgLongLong(DCArgs* p)
{
  if (p->i < 8) {
    return p->I[p->i++];
  } else {
    DClonglong value;
    p->sp = align(p->sp,sizeof(DClonglong));
    value =  * ( (DClonglong*) p->sp );
    p->sp += sizeof(DClonglong);
    return value;
  }
}

DCdouble dcbArgDouble(DCArgs* p)
{
  if (p->f < 8) {
    return p->F[p->f++].d.value;
  } else {
    DCdouble value;
    p->sp = align(p->sp,sizeof(DCdouble));
    value =  * ( (DCdouble*) p->sp );
    p->sp += sizeof(DCdouble);
    return value;
  }
}

DCfloat dcbArgFloat(DCArgs* p)
{
  if (p->f < 8) {
    return p->F[p->f++].f.value;
  } else {
    DCfloat value;
    p->sp = align(p->sp,sizeof(DCfloat));
    value =  * ( (DCfloat*) p->sp );
    p->sp += sizeof(DCfloat);
    return value;
  }
}

DClong dcbArgLong(DCArgs* p)
{
  if (p->i < 8) {
    return (DClong) p->I[p->i++];
  } else {
    DClong value;
    p->sp = align(p->sp,sizeof(DClong));
    value =  * ( (DClong*) p->sp );
    p->sp += sizeof(DClong);
    return value;
  }
}

DCint dcbArgInt(DCArgs* p)
{
  if (p->i < 8) {
    return (DCint) p->I[p->i++];
  } else {
    DCint value;
    p->sp = align(p->sp,sizeof(DCint));
    value =  * ( (DCint*) p->sp );
    p->sp += sizeof(DCint);
    return value;
  }
}

DCshort dcbArgShort(DCArgs* p)
{
  if (p->i < 8) {
    return (DCshort) p->I[p->i++];
  } else {
    DCshort value;
    p->sp = align(p->sp,sizeof(DCshort));
    value =  * ( (DCshort*) p->sp );
    p->sp += sizeof(DCshort);
    return value;
  }
}

DCchar dcbArgChar(DCArgs* p)
{
  if (p->i < 8) {
    return (DCchar) p->I[p->i++];
  } else {
    DCchar value;
    p->sp = align(p->sp,sizeof(DCchar));
    value =  * ( (DCchar*) p->sp );
    p->sp += sizeof(DCchar);
    return value;
  }
}

DCbool dcbArgBool(DCArgs* p)
{
  if (p->i < 8) {
    return (DCbool) p->I[p->i++];
  } else {
    DCbool value;
    p->sp = align(p->sp,sizeof(DCbool));
    value =  * ( (DCbool*) p->sp );
    p->sp += sizeof(DCbool);
    return value;
  }
}

DCpointer dcbArgPointer(DCArgs* p) {
  return (DCpointer) dcbArgLongLong(p);
}

DCuint      dcbArgUInt     (DCArgs* p) { return (DCuint)      dcbArgInt(p);      }
DCuchar     dcbArgUChar    (DCArgs* p) { return (DCuchar)     dcbArgChar(p);     }
DCushort    dcbArgUShort   (DCArgs* p) { return (DCushort)    dcbArgShort(p);    }
DCulong     dcbArgULong    (DCArgs* p) { return (DCulong)     dcbArgLong(p);     }
DCulonglong dcbArgULongLong(DCArgs* p) { return (DCulonglong) dcbArgLongLong(p); }

#define DCB_ARM64_NUM_REGS 8
#define DCB_ARM64_MAX_HFA_FIELDS 4

static size_t dcb_arm64_align_up(size_t x, size_t alignment)
{
  size_t rem;
  if(alignment <= 1)
    return x;
  rem = x % alignment;
  return rem ? x + alignment - rem : x;
}

static size_t dcb_arm64_stack_align(const DCaggr* ag)
{
  (void)ag;
  /* Match the call-side AAPCS64 aggregate stack rule: stack arguments occupy
     8-byte slots regardless of the aggregate object's natural alignment. */
  return 8;
}

static int dcb_arm64_hfa_scan(const DCaggr* ag, DCsigchar* type, DCint* count)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        if(!dcb_arm64_hfa_scan(f->sub_aggr, type, count))
          return 0;
      } else if(f->type == DC_SIGCHAR_FLOAT || f->type == DC_SIGCHAR_DOUBLE) {
        if(*type == '\0')
          *type = f->type;
        else if(*type != f->type)
          return 0;
        if(++(*count) > DCB_ARM64_MAX_HFA_FIELDS)
          return 0;
      } else {
        return 0;
      }
    }
  }

  return 1;
}

static int dcb_arm64_is_hfa(const DCaggr* ag, DCsigchar* type, DCint* count)
{
  *type = '\0';
  *count = 0;
  return ag && dcb_arm64_hfa_scan(ag, type, count) && *count > 0;
}

static void dcb_arm64_copy_hfa_from_regs(const DCaggr* ag, DCchar* base, DCArgs* p, DCsigchar type)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      DCchar* dst = base + f->offset + j * f->size;
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        dcb_arm64_copy_hfa_from_regs(f->sub_aggr, dst, p, type);
      } else if(type == DC_SIGCHAR_FLOAT) {
        DCfloat x = p->F[p->f++].f.value;
        memcpy(dst, &x, sizeof(x));
      } else {
        DCdouble x = p->F[p->f++].d.value;
        memcpy(dst, &x, sizeof(x));
      }
    }
  }
}

static void dcb_arm64_copy_hfa_to_result(const DCaggr* ag, const DCchar* base, DCchar* out, DCsigchar type, DCint* index)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      const DCchar* src = base + f->offset + j * f->size;
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        dcb_arm64_copy_hfa_to_result(f->sub_aggr, src, out, type, index);
      } else if(type == DC_SIGCHAR_FLOAT) {
        memset(out + (*index * 8), 0, 8);
        memcpy(out + (*index * 8), src, sizeof(DCfloat));
        ++(*index);
      } else {
        memcpy(out + (*index * 8), src, sizeof(DCdouble));
        ++(*index);
      }
    }
  }
}

static void dcb_arm64_copy_stack(DCArgs* p, DCpointer target, DCsize size, size_t alignment)
{
  p->sp = align(p->sp, alignment);
  memcpy(target, p->sp, size);
  p->sp += dcb_arm64_align_up(size, 8);
}

DCpointer dcbArgAggr(DCArgs* p, DCpointer target)
{
  DCaggr *ag = *(p->aggrs++);
  DCsigchar hfa_type;
  DCint hfa_count;

  if(!ag)
    return dcbArgPointer(p);
  if(!target)
    return NULL;

  if(dcb_arm64_is_hfa(ag, &hfa_type, &hfa_count)) {
    if(p->f + hfa_count <= DCB_ARM64_NUM_REGS)
      dcb_arm64_copy_hfa_from_regs(ag, (DCchar*)target, p, hfa_type);
    else {
      dcb_arm64_copy_stack(p, target, ag->size, dcb_arm64_stack_align(ag));
      p->f = DCB_ARM64_NUM_REGS;
    }
    return target;
  }

  if(ag->size > 16) {
    DCpointer src = dcbArgPointer(p);
    memcpy(target, src, ag->size);
    return target;
  }

  {
    DCsize chunk_count = dcb_arm64_align_up(ag->size, 8) >> 3;
    if(p->i + chunk_count <= DCB_ARM64_NUM_REGS) {
      DCsize i;
      DCchar *dst = (DCchar*)target;
      memset(target, 0, ag->size);
      for(i = 0; i < chunk_count; ++i) {
        DCsize remaining = ag->size > i * 8 ? ag->size - i * 8 : 0;
        DCsize n = remaining > 8 ? 8 : remaining;
        if(n)
          memcpy(dst + i * 8, &p->I[p->i], n);
        ++p->i;
      }
    } else {
      dcb_arm64_copy_stack(p, target, ag->size, dcb_arm64_stack_align(ag));
      p->i = DCB_ARM64_NUM_REGS;
    }
  }

  return target;
}

void dcbReturnAggr(DCArgs *args, DCValue *result, DCpointer ret)
{
  DCaggr *ag = *(args->aggrs++);
  DCsigchar hfa_type;
  DCint hfa_count;

  if(args->aggr_return_ptr) {
    if(ag && ret)
      memcpy(args->aggr_return_ptr, ret, ag->size);
    result->p = args->aggr_return_ptr;
    return;
  }

  if(!ag || !ret)
    return;

  if(dcb_arm64_is_hfa(ag, &hfa_type, &hfa_count)) {
    DCint index = 0;
    (void)hfa_count;
    memset(result, 0, 32);
    dcb_arm64_copy_hfa_to_result(ag, (const DCchar*)ret, (DCchar*)result, hfa_type, &index);
  } else {
    memset(result, 0, 16);
    memcpy(result, ret, ag->size);
  }
}
