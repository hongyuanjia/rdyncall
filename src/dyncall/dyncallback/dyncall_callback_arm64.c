/*

 Package: dyncall
 Library: dyncallback
 File: dyncallback/dyncall_callback_arm64.c
 Description: Callback - Implementation for ARM64 / ARMv8 / AAPCS64
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


#include "dyncall_callback.h"
#include "dyncall_alloc_wx.h"
#include "dyncall_aggregate.h"
#include "dyncall_thunk.h"

#define DCB_ARM64_AGGR_RET_NONE   -2
#define DCB_ARM64_AGGR_RET_HIDDEN  0
#define DCB_ARM64_AGGR_RET_INT     1
#define DCB_ARM64_AGGR_RET_FLOAT   2
#define DCB_ARM64_AGGR_RET_DOUBLE  3
#define DCB_ARM64_MAX_HFA_FIELDS   4


/* Callback symbol. */
extern void dcCallbackThunkEntry();

struct DCCallback                    /*  off  size */
{                                    /* ----|----- */
  DCThunk            thunk;          /*   0     32 */
  DCCallbackHandler* handler;        /*  32      8 */
  void*              userdata;       /*  40      8 */
  DCaggr *const *    aggrs;          /*  48      8 */
  DCint              aggr_ret_mode;  /*  56      4 */
  DCint              aggr_ret_count; /*  60      4 */
};                                   /* total   64 */
                                     /* aligned 64 */

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

void dcbInitCallback2(DCCallback* pcb, const DCsigchar* signature, DCCallbackHandler* handler, void* userdata, DCaggr *const * aggrs)
{
  const DCsigchar *ch = signature;
  DCint num_aggrs = 0;

  pcb->handler = handler;
  pcb->userdata = userdata;
  pcb->aggrs = NULL;
  pcb->aggr_ret_mode = DCB_ARM64_AGGR_RET_NONE;
  pcb->aggr_ret_count = 0;

  if(*ch == DC_SIGCHAR_CC_PREFIX)
    ch += 2;

  while(*ch)
    num_aggrs += (*(ch++) == DC_SIGCHAR_AGGREGATE);

  if(num_aggrs) {
    pcb->aggrs = aggrs;

    if(ch != signature && *(ch - 1) == DC_SIGCHAR_AGGREGATE) {
      const DCaggr *ag = pcb->aggrs[num_aggrs - 1];
      DCsigchar hfa_type;
      DCint hfa_count;

      if(!ag) {
        pcb->aggr_ret_mode = DCB_ARM64_AGGR_RET_HIDDEN;
      } else if(dcb_arm64_is_hfa(ag, &hfa_type, &hfa_count)) {
        pcb->aggr_ret_mode = hfa_type == DC_SIGCHAR_FLOAT ?
          DCB_ARM64_AGGR_RET_FLOAT : DCB_ARM64_AGGR_RET_DOUBLE;
        pcb->aggr_ret_count = hfa_count;
      } else if(ag->size > 16) {
        pcb->aggr_ret_mode = DCB_ARM64_AGGR_RET_HIDDEN;
      } else {
        pcb->aggr_ret_mode = DCB_ARM64_AGGR_RET_INT;
      }
    }
  }
}


DCCallback* dcbNewCallback2(const DCsigchar* signature, DCCallbackHandler* handler, void* userdata, DCaggr *const * aggrs)
{
  DCCallback* pcb;
  int err = dcAllocWX(sizeof(DCCallback), (void**)&pcb);
  if(err)
    return NULL;

  dcbInitCallback2(pcb, signature, handler, userdata, aggrs);
  dcbInitThunk(&pcb->thunk, dcCallbackThunkEntry);

  err = dcInitExecWX(pcb, sizeof(DCCallback));
  if(err) {
    dcFreeWX(pcb, sizeof(DCCallback));
    return NULL;
  }

  return pcb;
}
