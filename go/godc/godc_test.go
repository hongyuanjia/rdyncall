/*

 godc_test.go
 Copyright (c) 2014 Tassilo Philipp <tphilipp@potion-studios.com>

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


package godc

import (
	"testing"
	"fmt"
	"unsafe"
	"math"
)

func TestGoDC(t *testing.T) {
	lm := new(ExtLib)
	if err := lm.Load("/usr/lib/libm.so"); err != nil {
		t.FailNow()
	}
	defer lm.Free()

	if err := lm.SymsInit("/usr/lib/libm.so"); err != nil {
		t.FailNow()
	}
	defer lm.SymsCleanup()

	fmt.Printf("Testing dl:\n")
	fmt.Printf("-----------\n")
	fmt.Printf("Loaded library at address: %p\n", lm.lib)
	fmt.Printf("C sqrt function at address: %p\n", lm.FindSymbol("sqrt"))
	fmt.Printf("C pow function at address: %p\n\n", lm.FindSymbol("pow"))

	fmt.Printf("Testing dlSyms:\n")
	fmt.Printf("---------------\n")
	fmt.Printf("Symbols in libm: %d\n", lm.SymsCount())
	fmt.Printf("Symbol name for address %p: %s\n", lm.FindSymbol("pow"), lm.SymsNameFromValue(lm.FindSymbol("pow")))
	fmt.Printf("All symbol names in libm:\n")
	for i, n := 0, lm.SymsCount(); i<n; i++ {
		fmt.Printf("  %s\n", lm.SymsName(i))
	}
	fmt.Printf("\n")



	// Another lib
	lc := new(ExtLib)
	if err := lc.Load("/usr/lib/libc.so"); err != nil {
		t.FailNow()
	}
	defer lc.Free()

	if err := lc.SymsInit("/usr/lib/libc.so"); err != nil {
		t.FailNow()
	}
	defer lc.SymsCleanup()

	fmt.Printf("Symbols in libc: %d (not listing them here, too many)\n\n", lc.SymsCount())



	// Call some functions
	fmt.Printf("Testing dc:\n")
	fmt.Printf("-----------\n")
	vm := new(CallVM)
	if err := vm.InitCallVM(); err != nil {
		t.FailNow()
	}
	defer vm.Free()

	vm.Mode(DC_CALL_C_DEFAULT)


	// Float
	vm.Reset()
	vm.ArgFloat(36)
	rf := vm.CallFloat(lm.FindSymbol("sqrtf"))
	fmt.Printf("sqrtf(36) = %f\n", rf)
	if(rf != 6.0) { t.FailNow() }

	vm.Reset() // Test reset, reusing VM
	vm.ArgDouble(3.6)
	rd := vm.CallDouble(lm.FindSymbol("floor"))
	fmt.Printf("floor(3.6) = %f\n", rd)
	if(rd != 3.0) { t.FailNow() }


	// Double
	vm.Reset()
	vm.ArgDouble(4.2373)
	rd = vm.CallDouble(lm.FindSymbol("sqrt"))
	fmt.Printf("sqrt(4.2373) = %f\n", rd)
	if(math.Abs(rd - 2.05847) > 0.00001) { t.FailNow() }

	vm.Reset()
	vm.ArgDouble(2.373)
	vm.ArgDouble(-1000) // 2 args
	rd = vm.CallDouble(lm.FindSymbol("copysign"))
	fmt.Printf("copysign(2.373, -1000) = %f\n", rd)
	if(rd != -2.373) { t.FailNow() }


	// Strings
	vm.Reset()
	cs1 := vm.AllocCString("/return/only/this_here")
	defer vm.FreeCString(cs1)

	vm.ArgPointer(cs1)
	rs := vm.CallPointerToStr(lc.FindSymbol("basename"))
	fmt.Printf("basename(\"/return/only/this_here\") = %s\n", rs)
	if(rs != "this_here") { t.FailNow() }
	// Reuse path
	rs = vm.CallPointerToStr(lc.FindSymbol("dirname"))
	fmt.Printf("dirname(\"/return/only/this_here\") = %s\n", rs)
	if(rs != "/return/only") { t.FailNow() }


	// Integer
	vm.Reset()
	vm.ArgInt('a')
	ri := vm.CallInt(lc.FindSymbol("toupper"))
	fmt.Printf("toupper('a') = %c\n", ri)
	if(ri != 'A') { t.FailNow() }

	vm.Reset()
	vm.ArgInt('a')
	ri = vm.CallInt(lc.FindSymbol("tolower"))
	fmt.Printf("tolower('a') = %c\n", ri)
	if(ri != 'a') { t.FailNow() }

	vm.Reset()
	vm.ArgInt('R')
	ri = vm.CallInt(lc.FindSymbol("toupper"))
	fmt.Printf("toupper('R') = %c\n", vm.CallInt(lc.FindSymbol("toupper")))
	if(ri != 'R') { t.FailNow() }

	vm.Reset()
	vm.ArgInt('R')
	ri = vm.CallInt(lc.FindSymbol("tolower"))
	fmt.Printf("tolower('R') = %c\n", vm.CallInt(lc.FindSymbol("tolower")))
	if(ri != 'r') { t.FailNow() }


	// Integer return
	vm.Reset()
	cs2 := vm.AllocCString("Tassilo")
	defer vm.FreeCString(cs2)

	fmt.Printf("rand() = %d\n", vm.CallInt(lc.FindSymbol("rand")))
	fmt.Printf("rand() = %d\n", vm.CallInt(lc.FindSymbol("rand")))
	fmt.Printf("rand() = %d\n", vm.CallInt(lc.FindSymbol("rand")))
	fmt.Printf("rand() = %d\n", vm.CallInt(lc.FindSymbol("rand")))
	fmt.Printf("rand() = %d\n", vm.CallInt(lc.FindSymbol("rand")))
	vm.ArgPointer(cs2)
	ri = vm.CallInt(lc.FindSymbol("strlen"))
	fmt.Printf("strlen(\"Tassilo\") = %d\n", ri)
	if(ri != 7) { t.FailNow() }


	// Formatted - with signature/conversion
	vm.Reset()
	vm.ArgF("dd)d", 3.14, -2000) // 2 args, second passed as int, but ArgF will convert
	rd = vm.CallDouble(lm.FindSymbol("copysign"))
	fmt.Printf("dd)d: copysign(3.14, -2000) = %f\n", rd)
	if(rd != -3.14) { t.FailNow() }

	// Formatted - without signature/conversion
	vm.Reset()
	vm.ArgF("dd)d", -31.4, 42.4) // 2 args, second passed as int, but ArgF will convert
	rd = vm.CallDouble(lm.FindSymbol("copysign"))
	fmt.Printf("dd)d: copysign(-31.4, 42.4) = %f\n", rd)
	if(rd != 31.4) { t.FailNow() }

	// Formatted - use Go's types, pass unsupported type, should return an error
	vm.Reset()
	err := vm.ArgF_Go(6.14, vm)
	fmt.Printf("ArgF_Go: copysign(6.14, <unsupported type>) should return error: %t\n", err != nil)
	if(err == nil) { t.FailNow() }

	// Formatted - use Go's types
	vm.Reset()
	vm.ArgF_Go(-61.4, 42.4) // 2 args, both need to be correct or undefined behaviour
	rd = vm.CallDouble(lm.FindSymbol("copysign"))
	fmt.Printf("copysign(-61.4, 42.4) = %f\n", rd)
	if(rd != 61.4) { t.FailNow() }


	// Ellipse
	vm.Mode(DC_CALL_C_ELLIPSIS)
	vm.Reset()
	buf := make([]byte, 1000)
	bufPtr := unsafe.Pointer(&buf[0])
	cs3 := vm.AllocCString("Four:%d | \"Hello\":%s | Pi:%f")
	cs4 := vm.AllocCString("Hello")
	defer vm.FreeCString(cs4)
	defer vm.FreeCString(cs3)

	vm.ArgPointer(bufPtr)
	vm.ArgPointer(cs3)
	vm.Mode(DC_CALL_C_ELLIPSIS_VARARGS)
	vm.ArgInt(4)
	vm.ArgPointer(cs4)
	vm.ArgDouble(3.14) // Double, b/c of ... promotion rules
	ri = vm.CallInt(lc.FindSymbol("sprintf"))
	fmt.Printf("sprintf(bufPtr, \"Four:%%d | \\\"Hello\\\":%%s | Pi:%%f\", 4, \"Hello\", 3.14) = %d:\n", ri)
	fmt.Printf("  bufPtr: %s\n", string(buf[/*slice printed bytes*/:ri]))
	if(ri != 36) { t.FailNow() }


//@@@ untested:
// - ArgF and ArgF_Go with strings
// - ArgF and ArgF_Go with bools
// - ...
}

