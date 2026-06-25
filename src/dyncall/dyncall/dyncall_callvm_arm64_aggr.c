/*

 Package: dyncall
 Library: dyncall
 File: dyncall/dyncall_callvm_arm64_aggr.c
 Description: ARM 64-bit aggregate by-value helpers
 License:

   Copyright (c) 2026 Hongyuan Jia <hongyuanjia@cqust.edu.cn>

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

#include "dyncall_aggregate.h"
#include <stdint.h>
#include <string.h>

void dcCall_arm64_aggr(DCpointer target, DCpointer data, DCsize size, DCpointer regdata, DCpointer ret_regs, DCpointer ret_ptr);

#define DC_ARM64_NUM_REGS 8
#define DC_ARM64_MAX_HFA_FIELDS 4
#define DC_ARM64_RET_INT_OFFSET 0
#define DC_ARM64_RET_FP_OFFSET 16

static DCsize dc_arm64_align_up(DCsize x, DCsize align)
{
  DCsize rem;
  if(align <= 1)
    return x;
  rem = x % align;
  return rem ? x + align - rem : x;
}

static DCsize dc_arm64_stack_align(const DCaggr* ag)
{
  (void)ag;
  /* AAPCS64 stack aggregate arguments use 8-byte argument slots. The
     aggregate's own alignment is for object layout, not stack slot placement. */
  return 8;
}

static void dc_arm64_append_stack(DCCallVM_arm64* self, const void* x, DCsize size, DCsize align, int pad_to_8)
{
  if(align > 1)
    dcVecResize(&self->mVecHead, dc_arm64_align_up(dcVecSize(&self->mVecHead), align));
  dcVecAppend(&self->mVecHead, x, size);
  if(pad_to_8) {
    DCsize aligned = dc_arm64_align_up(size, 8);
    if(aligned > size)
      dcVecSkip(&self->mVecHead, aligned - size);
  }
}

static int dc_arm64_hfa_scan(const DCaggr* ag, const DCchar* base, DCsigchar* type, DCint* count)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        if(!dc_arm64_hfa_scan(f->sub_aggr, base ? base + f->offset + j * f->size : NULL, type, count))
          return 0;
      } else if(f->type == DC_SIGCHAR_FLOAT || f->type == DC_SIGCHAR_DOUBLE) {
        if(*type == '\0')
          *type = f->type;
        else if(*type != f->type)
          return 0;
        if(++(*count) > DC_ARM64_MAX_HFA_FIELDS)
          return 0;
      } else {
        return 0;
      }
    }
  }

  return 1;
}

static int dc_arm64_is_hfa(const DCaggr* ag, DCsigchar* type, DCint* count)
{
  *type = '\0';
  *count = 0;
  return ag && dc_arm64_hfa_scan(ag, NULL, type, count) && *count > 0;
}

static void dc_arm64_copy_hfa_to_regs(DCCallVM_arm64* self, const DCaggr* ag, const DCchar* base, DCsigchar type)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      const DCchar* src = base + f->offset + j * f->size;
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        dc_arm64_copy_hfa_to_regs(self, f->sub_aggr, src, type);
      } else if(type == DC_SIGCHAR_FLOAT) {
        DCfloat x;
        memcpy(&x, src, sizeof(x));
        self->u.S[self->f << 1] = x;
        ++self->f;
      } else {
        DCdouble x;
        memcpy(&x, src, sizeof(x));
        self->u.D[self->f] = x;
        ++self->f;
      }
    }
  }
}

static void dc_arm64_copy_hfa_from_regs(const DCaggr* ag, DCchar* base, const DCchar* fp_regs, DCsigchar type, DCint* index)
{
  DCsize i;

  for(i = 0; i < ag->n_fields; ++i) {
    const DCfield* f = ag->fields + i;
    DCsize j;

    for(j = 0; j < f->array_len; ++j) {
      DCchar* dst = base + f->offset + j * f->size;
      if(f->type == DC_SIGCHAR_AGGREGATE) {
        dc_arm64_copy_hfa_from_regs(f->sub_aggr, dst, fp_regs, type, index);
      } else if(type == DC_SIGCHAR_FLOAT) {
        memcpy(dst, fp_regs + (*index * 8), sizeof(DCfloat));
        ++(*index);
      } else {
        memcpy(dst, fp_regs + (*index * 8), sizeof(DCdouble));
        ++(*index);
      }
    }
  }
}

static void dc_arm64_arg_i64(DCCallVM* in_self, DClonglong x)
{
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  if(self->i < DC_ARM64_NUM_REGS)
    self->I[self->i++] = x;
  else
    dc_arm64_append_stack(self, &x, sizeof(x), sizeof(x), 1);
}

static void dc_arm64_arg_pointer(DCCallVM* in_self, DCpointer x)
{
  dc_arm64_arg_i64(in_self, (DClonglong)x);
}

static void dc_arm64_arg_small_int_regs(DCCallVM_arm64* self, const void* x, DCsize size)
{
  DCsize chunk_count = dc_arm64_align_up(size, 8) >> 3;
  DCsize i;
  const DCchar* src = (const DCchar*)x;

  if(self->i + chunk_count <= DC_ARM64_NUM_REGS) {
    for(i = 0; i < chunk_count; ++i) {
      DClonglong chunk = 0;
      DCsize remaining = size > i * 8 ? size - i * 8 : 0;
      DCsize n = remaining > 8 ? 8 : remaining;
      if(n)
        memcpy(&chunk, src + i * 8, n);
      self->I[self->i++] = chunk;
    }
  } else {
    dc_arm64_append_stack(self, x, size, 8, 1);
  }
}

static void dc_arm64_arg_large_by_pointer(DCCallVM* in_self, const DCaggr* ag, const void* x)
{
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  self->mpAggrVecCopies = (void*)((intptr_t)((DCchar*)self->mpAggrVecCopies - ag->size) & -16);
  x = memcpy(self->mpAggrVecCopies, x, ag->size);
  dc_arm64_arg_pointer(in_self, (DCpointer)x);
}

static void dc_callvm_argAggr_arm64(DCCallVM* in_self, const DCaggr* ag, const void* x)
{
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  DCsigchar hfa_type;
  DCint hfa_count;

  if(!ag) {
    dc_arm64_arg_pointer(in_self, (DCpointer)x);
    return;
  }

  if(dc_arm64_is_hfa(ag, &hfa_type, &hfa_count)) {
    if(self->f + hfa_count <= DC_ARM64_NUM_REGS)
      dc_arm64_copy_hfa_to_regs(self, ag, (const DCchar*)x, hfa_type);
    else {
      dc_arm64_append_stack(self, x, ag->size, dc_arm64_stack_align(ag), 1);
      self->f = DC_ARM64_NUM_REGS;
    }
    return;
  }

  if(ag->size <= 16) {
    DCsize chunk_count = dc_arm64_align_up(ag->size, 8) >> 3;
    if(self->i + chunk_count <= DC_ARM64_NUM_REGS) {
      dc_arm64_arg_small_int_regs(self, x, ag->size);
      return;
    }
  } else {
    dc_arm64_arg_large_by_pointer(in_self, ag, x);
    return;
  }

  dc_arm64_append_stack(self, x, ag->size, dc_arm64_stack_align(ag), 1);
  self->i = DC_ARM64_NUM_REGS;
}

static void dc_callvm_argAggr_arm64_vararg(DCCallVM* in_self, const DCaggr* ag, const void* x)
{
#if defined(DC__OS_Darwin)
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  if(!ag) {
    var_pointer(in_self, (DCpointer)x);
    return;
  }
  dc_arm64_append_stack(self, x, ag->size, dc_arm64_stack_align(ag), 1);
#elif defined(DC__OS_Win64)
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  if(!ag) {
    dc_arm64_arg_pointer(in_self, (DCpointer)x);
    return;
  }
  if(ag->size > 16) {
    dc_arm64_arg_large_by_pointer(in_self, ag, x);
    return;
  }
  dc_arm64_arg_small_int_regs(self, x, ag->size);
#else
  dc_callvm_argAggr_arm64(in_self, ag, x);
#endif
}

static void dc_callvm_beginAggr_arm64(DCCallVM* in_self, const DCaggr* ag)
{
  (void)in_self;
  (void)ag;
}

static void dc_callvm_callAggr_arm64(DCCallVM* in_self, DCpointer target, const DCaggr* ag, DCpointer ret)
{
  DCCallVM_arm64* self = (DCCallVM_arm64*)in_self;
  DCchar ret_regs[48];
  DCsigchar hfa_type;
  DCint hfa_count;
  DCpointer ret_ptr = NULL;
  int is_hfa = dc_arm64_is_hfa(ag, &hfa_type, &hfa_count);

  if(!ag || (!is_hfa && ag->size > 16))
    ret_ptr = ret;

  memset(ret_regs, 0, sizeof(ret_regs));
  dcCall_arm64_aggr(target, dcVecData(&self->mVecHead), (dcVecSize(&self->mVecHead) + 15) & -16, &self->u.S[0], ret_regs, ret_ptr);

  if(ret_ptr)
    return;

  if(is_hfa) {
    DCint index = 0;
    dc_arm64_copy_hfa_from_regs(ag, (DCchar*)ret, ret_regs + DC_ARM64_RET_FP_OFFSET, hfa_type, &index);
  } else {
    memcpy(ret, ret_regs + DC_ARM64_RET_INT_OFFSET, ag->size);
  }
}
