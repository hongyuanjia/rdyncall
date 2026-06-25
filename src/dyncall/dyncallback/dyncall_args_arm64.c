/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_args_arm64.c
 Description: Callback's Arguments VM - Implementation for ARM64 / ARMv8 / AAPCS64
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
  uint64_t* sp;

  /* counters: */
  int i;
  int f;

  DCaggr** aggrs;
  DCpointer aggr_return_ptr;
};

DClonglong  dcbArgLongLong (DCArgs* p) { return (p->i < 8) ? p->I[p->i++] : *(p->sp)++; }
DCdouble    dcbArgDouble   (DCArgs* p) { return (p->f < 8) ? p->F[p->f++].d.value : * ( (double*) (p->sp++) ); }
DCfloat     dcbArgFloat    (DCArgs* p) { return (p->f < 8) ? p->F[p->f++].f.value : * ( (float*)  (p->sp++) ); }


DClong      dcbArgLong     (DCArgs* p) { return (DClong)  dcbArgLongLong(p); }
DCint       dcbArgInt      (DCArgs* p) { return (DCint)   dcbArgLongLong(p); }
DCshort     dcbArgShort    (DCArgs* p) { return (DCshort) dcbArgLongLong(p); }
DCchar      dcbArgChar     (DCArgs* p) { return (DCchar)  dcbArgLongLong(p); }
DCbool      dcbArgBool     (DCArgs* p) { return dcbArgLongLong(p) & 0x1; }
DCpointer   dcbArgPointer  (DCArgs* p) { return (DCpointer)dcbArgLongLong(p); }

DCuint      dcbArgUInt     (DCArgs* p) { return (DCuint)     dcbArgInt(p);      }
DCuchar     dcbArgUChar    (DCArgs* p) { return (DCuchar)    dcbArgChar(p);     }
DCushort    dcbArgUShort   (DCArgs* p) { return (DCushort)   dcbArgShort(p);    }
DCulong     dcbArgULong    (DCArgs* p) { return (DCulong)    dcbArgLong(p);     }
DCulonglong dcbArgULongLong(DCArgs* p) { return (DCulonglong)dcbArgLongLong(p); }

#define DCB_ARM64_NUM_REGS 8
#define DCB_ARM64_MAX_HFA_FIELDS 4

static DCsize dcb_arm64_align_up(DCsize x, DCsize align)
{
  DCsize rem;
  if(align <= 1)
    return x;
  rem = x % align;
  return rem ? x + align - rem : x;
}

static DCsize dcb_arm64_stack_align(const DCaggr* ag)
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

static void dcb_arm64_copy_stack(DCArgs* p, DCpointer target, DCsize size, DCsize align)
{
  uint8_t *sp = (uint8_t*)p->sp;
  DCsize advance;
  if(align > 1)
    sp = (uint8_t*)dcb_arm64_align_up((DCsize)sp, align);
  memcpy(target, sp, size);
  advance = dcb_arm64_align_up(size, 8);
  p->sp = (uint64_t*)(sp + advance);
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
