 AREA .text, CODE, ARM64
 EXPORT dcCallbackThunkEntry
dcCallbackThunkEntry PROC
 mov x10, sp
 stp x29, x30, [sp, #-224 ]!
 mov x29, sp
 add x11, x29 , #16
 stp x0, x1, [x11, #0 ]
 stp x2, x3, [x11, #16]
 stp x4, x5, [x11, #32]
        stp x6, x7, [x11, #48]
 stp d0, d1, [x11, #64]
 stp d2, d3, [x11, #80]
      stp d4, d5, [x11, #96]
 stp d6, d7, [x11, #112]
 eor x12, x12, x12
 stp x10,x12,[x11, #128]
 ldr x13, [x9, #48]
 str x13, [x11, #144]
 ldr w13, [x9, #56]
 cmp w13, #0
 csel x13, x8, xzr, eq
 str x13, [x11, #152]
 mov x0 , x9
 add x1 , x29 , #16
 add x2 , x29 , #176
 ldr x3 , [x9 , #40]
 ldr x11, [x9 , #32]
 str x9, [x29, #216]
 blr x11
 ldr x14, [x29, #216]
 add x15, x29, #16
 and w0, w0, #255
 cmp w0, 'A'
 b.eq dcCall_arm64_reta
 cmp w0, 'f'
 b.eq dcCall_arm64_retf
 cmp w0, 'd'
 b.eq dcCall_arm64_retf
dcCall_arm64_reti
 ldr x0, [x29, #176]
 b dcCall_arm64_ret
dcCall_arm64_retf
 ldr d0, [x29, #176]
 b dcCall_arm64_ret
dcCall_arm64_reta
 ldr w10, [x14, #56]
 cmp w10, #1
 b.eq dcCall_arm64_retai
 cmp w10, #2
 b.eq dcCall_arm64_retaf
 cmp w10, #3
 b.eq dcCall_arm64_retaf
 ldr x0, [x15, #152]
 b dcCall_arm64_ret
dcCall_arm64_retai
 ldr x0, [x29, #176]
 ldr x1, [x29, #184]
 b dcCall_arm64_ret
dcCall_arm64_retaf
 ldr d0, [x29, #176]
 ldr d1, [x29, #184]
 ldr d2, [x29, #192]
 ldr d3, [x29, #200]
dcCall_arm64_ret
 ldp x29, x30, [sp], #224
 ret
 ENDP
 END
