/*

 godc.go
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


// Go/dyncall extension implementation.
package godc

// #cgo LDFLAGS: -ldyncall_s
// #cgo LDFLAGS: -ldynload_s
// #cgo LDFLAGS: -ldyncallback_s
// #include <stdlib.h>
// #include "dyncall.h"
// #include "dynload.h"
// #include "dyncall_signature.h"
import "C"
import (
	"unsafe"
	"fmt"
	"reflect"
)

type ExtLib struct {
	lib  *C.DLLib
	syms *C.DLSyms
}

type CallVM struct {
	cvm  *C.DCCallVM
}


// dynload
func (p *ExtLib) Load(path string) error {
	s := C.CString(path)
	defer C.free(unsafe.Pointer(s))
	p.lib = C.dlLoadLibrary(s)
	if p.lib != nil { return nil }
	return fmt.Errorf("Can't load %s", path)
}

func (p *ExtLib) Free() {
	C.dlFreeLibrary(p.lib)
}

func (p *ExtLib) FindSymbol(name string) unsafe.Pointer {
	s := C.CString(name)
	defer C.free(unsafe.Pointer(s))
	return unsafe.Pointer(C.dlFindSymbol(p.lib, s))
}


// dynload Syms
func (p *ExtLib) SymsInit(path string) error {
	s := C.CString(path)
	defer C.free(unsafe.Pointer(s))
	p.syms = C.dlSymsInit(s)
	if p.syms != nil { return nil }
	return fmt.Errorf("Can't load %s", path)
}

func (p *ExtLib) SymsCleanup() {
	C.dlSymsCleanup(p.syms)
}

func (p *ExtLib) SymsCount() int {
	return int(C.dlSymsCount(p.syms))
}

func (p *ExtLib) SymsName(i int) string {
	return C.GoString(C.dlSymsName(p.syms, C.int(i)))
}

func (p *ExtLib) SymsNameFromValue(v unsafe.Pointer) string {
	return C.GoString(C.dlSymsNameFromValue(p.syms, v))
}


// dyncall
func (p *CallVM) InitCallVM() error {
	return p.InitCallVMWithStackSize(4096)
}

func (p *CallVM) InitCallVMWithStackSize(stackSize int) error {
	p.cvm = C.dcNewCallVM(C.DCsize(stackSize))
	if p.cvm != nil { return nil }
	return fmt.Errorf("Can't create CallVM")
}

func (p *CallVM) Free() {
	C.dcFree(p.cvm)
}

func (p *CallVM) Reset() {
	C.dcReset(p.cvm)
}



// Modes
const (
	DC_CALL_C_DEFAULT            = C.DC_CALL_C_DEFAULT
	DC_CALL_C_ELLIPSIS           = C.DC_CALL_C_ELLIPSIS
	DC_CALL_C_ELLIPSIS_VARARGS   = C.DC_CALL_C_ELLIPSIS_VARARGS
	DC_CALL_C_X86_CDECL          = C.DC_CALL_C_X86_CDECL
	DC_CALL_C_X86_WIN32_STD      = C.DC_CALL_C_X86_WIN32_STD
	DC_CALL_C_X86_WIN32_FAST_MS  = C.DC_CALL_C_X86_WIN32_FAST_MS
	DC_CALL_C_X86_WIN32_FAST_GNU = C.DC_CALL_C_X86_WIN32_FAST_GNU
	DC_CALL_C_X86_WIN32_THIS_MS  = C.DC_CALL_C_X86_WIN32_THIS_MS
	DC_CALL_C_X86_WIN32_THIS_GNU = C.DC_CALL_C_X86_WIN32_THIS_GNU
	DC_CALL_C_X64_WIN64          = C.DC_CALL_C_X64_WIN64
	DC_CALL_C_X64_SYSV           = C.DC_CALL_C_X64_SYSV
	DC_CALL_C_PPC32_DARWIN       = C.DC_CALL_C_PPC32_DARWIN
	DC_CALL_C_PPC32_OSX          = C.DC_CALL_C_PPC32_OSX
	DC_CALL_C_ARM_ARM_EABI       = C.DC_CALL_C_ARM_ARM_EABI
	DC_CALL_C_ARM_THUMB_EABI     = C.DC_CALL_C_ARM_THUMB_EABI
	DC_CALL_C_ARM_ARMHF          = C.DC_CALL_C_ARM_ARMHF
	DC_CALL_C_MIPS32_EABI        = C.DC_CALL_C_MIPS32_EABI
	DC_CALL_C_MIPS32_PSPSDK      = C.DC_CALL_C_MIPS32_PSPSDK
	DC_CALL_C_PPC32_SYSV         = C.DC_CALL_C_PPC32_SYSV
	DC_CALL_C_PPC32_LINUX        = C.DC_CALL_C_PPC32_LINUX
	DC_CALL_C_ARM_ARM            = C.DC_CALL_C_ARM_ARM
	DC_CALL_C_ARM_THUMB          = C.DC_CALL_C_ARM_THUMB
	DC_CALL_C_MIPS32_O32         = C.DC_CALL_C_MIPS32_O32
	DC_CALL_C_MIPS64_N32         = C.DC_CALL_C_MIPS64_N32
	DC_CALL_C_MIPS64_N64         = C.DC_CALL_C_MIPS64_N64
	DC_CALL_C_X86_PLAN9          = C.DC_CALL_C_X86_PLAN9
	DC_CALL_C_SPARC32            = C.DC_CALL_C_SPARC32
	DC_CALL_C_SPARC64            = C.DC_CALL_C_SPARC64
	DC_CALL_C_ARM64              = C.DC_CALL_C_ARM64
	DC_CALL_C_PPC64              = C.DC_CALL_C_PPC64
	DC_CALL_C_PPC64_LINUX        = C.DC_CALL_C_PPC64_LINUX
	DC_CALL_SYS_DEFAULT          = C.DC_CALL_SYS_DEFAULT
	DC_CALL_SYS_X86_INT80H_LINUX = C.DC_CALL_SYS_X86_INT80H_LINUX
	DC_CALL_SYS_X86_INT80H_BSD   = C.DC_CALL_SYS_X86_INT80H_BSD
	DC_CALL_SYS_X64_SYSCALL_SYSV = C.DC_CALL_SYS_X64_SYSCALL_SYSV
	DC_CALL_SYS_PPC32            = C.DC_CALL_SYS_PPC32
	DC_CALL_SYS_PPC64            = C.DC_CALL_SYS_PPC64
)


func (p *CallVM) Mode(mode int) {
	C.dcMode(p.cvm, C.DCint(mode))
}

// Error codes
const (
	DC_ERROR_NONE             = C.DC_ERROR_NONE
	DC_ERROR_UNSUPPORTED_MODE = C.DC_ERROR_UNSUPPORTED_MODE
)


func (p *CallVM) GetError() int {
	return int(C.dcGetError(p.cvm))
}


// Helper for string/pointer conversion, needed as low-level string alloc needs to be freed in different scope
func (p *CallVM) AllocCString(value string) unsafe.Pointer { s := C.CString(value); return unsafe.Pointer(s) }
func (p *CallVM) FreeCString (value unsafe.Pointer)        { C.free(value) }

// Args
func (p *CallVM) ArgBool        (value bool)           { if value==true { C.dcArgBool(p.cvm, C.DC_TRUE) } else { C.dcArgBool(p.cvm, C.DC_FALSE) } }
func (p *CallVM) ArgChar        (value int8)           { C.dcArgChar    (p.cvm, C.DCchar    (value)) }
func (p *CallVM) ArgShort       (value int16)          { C.dcArgShort   (p.cvm, C.DCshort   (value)) }
func (p *CallVM) ArgInt         (value int)            { C.dcArgInt     (p.cvm, C.DCint     (value)) }
func (p *CallVM) ArgLong        (value int32)          { C.dcArgLong    (p.cvm, C.DClong    (value)) }
func (p *CallVM) ArgLongLong    (value int64)          { C.dcArgLongLong(p.cvm, C.DClonglong(value)) }
func (p *CallVM) ArgFloat       (value float32)        { C.dcArgFloat   (p.cvm, C.DCfloat   (value)) }
func (p *CallVM) ArgDouble      (value float64)        { C.dcArgDouble  (p.cvm, C.DCdouble  (value)) }
func (p *CallVM) ArgPointer     (value unsafe.Pointer) { C.dcArgPointer (p.cvm, C.DCpointer (value)) }
//@@@func (p *CallVM) ArgStruct  (s C.DCstruct*, value unsafe.Pointer)

// "Formatted" args
//   - first takes Go's types (as they cover all C types dyncall supports) and pushes values accordingly
//   - second uses a dyncall signature for implicit type conversion/casting, however it uses reflect package and is slower
// Note that first version doesn't feature calling convention mode switching.
func (p *CallVM) ArgF_Go(args ...interface{}) error {

	for i, n := 0, len(args); i<n; i++ {
		switch args[i].(type) {
			case bool:           p.ArgBool    (              (args[i].(bool          )))
			case int8:           p.ArgChar    (              (args[i].(int8          )))
			case uint8/*byte*/:  p.ArgChar    (int8          (args[i].(uint8         )))
			case int16:          p.ArgShort   (              (args[i].(int16         )))
			case uint16:         p.ArgShort   (int16         (args[i].(uint16        )))
			case int:            p.ArgInt     (              (args[i].(int           )))
			case uint:           p.ArgInt     (int           (args[i].(uint          )))
			case int32/*rune*/:  p.ArgLong    (              (args[i].(int32         )))
			case uint32:         p.ArgLong    (int32         (args[i].(uint32        )))
			case int64:          p.ArgLongLong(              (args[i].(int64         )))
			case uint64:         p.ArgLongLong(int64         (args[i].(uint64        )))
			case float32:        p.ArgFloat   (              (args[i].(float32       )))
			case float64:        p.ArgDouble  (              (args[i].(float64       )))
			case uintptr:        p.ArgPointer (unsafe.Pointer(args[i].(unsafe.Pointer)))
			case unsafe.Pointer: p.ArgPointer (              (args[i].(unsafe.Pointer)))
			default: return fmt.Errorf("Unknown type passed to ArgF_Go")
		}
	}
	return nil
}

func (p *CallVM) ArgF(signature string, args ...interface{}) {

	tb := reflect.TypeOf((*bool   )(nil)).Elem()
	ti := reflect.TypeOf((*int64  )(nil)).Elem()
	tf := reflect.TypeOf((*float64)(nil)).Elem()
	tp := reflect.TypeOf((*uintptr)(nil)).Elem()

	for i, n := 0, len(signature); i<n; i++ {
		//@@@ add support for calling convention mode(s)
		switch s := signature[i]; s {
			case C.DC_SIGCHAR_BOOL:                              p.ArgBool    (bool          (reflect.ValueOf(args[i]).Convert(tb).Bool   ()))
			case C.DC_SIGCHAR_CHAR,     C.DC_SIGCHAR_UCHAR:      p.ArgChar    (int8          (reflect.ValueOf(args[i]).Convert(ti).Int    ()))
			case C.DC_SIGCHAR_INT,      C.DC_SIGCHAR_UINT:       p.ArgInt     (int           (reflect.ValueOf(args[i]).Convert(ti).Int    ()))
			case C.DC_SIGCHAR_LONG,     C.DC_SIGCHAR_ULONG:      p.ArgLong    (int32         (reflect.ValueOf(args[i]).Convert(ti).Int    ()))
			case C.DC_SIGCHAR_LONGLONG, C.DC_SIGCHAR_ULONGLONG:  p.ArgLongLong(int64         (reflect.ValueOf(args[i]).Convert(ti).Int    ()))
			case C.DC_SIGCHAR_FLOAT:                             p.ArgFloat   (float32       (reflect.ValueOf(args[i]).Convert(tf).Float  ()))
			case C.DC_SIGCHAR_DOUBLE:                            p.ArgDouble  (float64       (reflect.ValueOf(args[i]).Convert(tf).Float  ()))
			case C.DC_SIGCHAR_POINTER,  C.DC_SIGCHAR_STRING:     p.ArgPointer (unsafe.Pointer(reflect.ValueOf(args[i]).Convert(tp).Pointer()))
			case C.DC_SIGCHAR_ENDARG:                            return
		}
		// Faster, but doesn't do cross-type conversions.
		//switch s := signature[i]; s {
		//	case C.DC_SIGCHAR_BOOL:                              p.ArgBool    (args[i].(bool          ))
		//	case C.DC_SIGCHAR_CHAR,     C.DC_SIGCHAR_UCHAR:      p.ArgChar    (args[i].(int8          ))
		//	case C.DC_SIGCHAR_SHORT,    C.DC_SIGCHAR_USHORT:     p.ArgShort   (args[i].(int16         ))
		//	case C.DC_SIGCHAR_INT,      C.DC_SIGCHAR_UINT:       p.ArgInt     (args[i].(int           ))
		//	case C.DC_SIGCHAR_LONG,     C.DC_SIGCHAR_ULONG:      p.ArgLong    (args[i].(int32         ))
		//	case C.DC_SIGCHAR_LONGLONG, C.DC_SIGCHAR_ULONGLONG:  p.ArgLongLong(args[i].(int64         ))
		//	case C.DC_SIGCHAR_FLOAT:                             p.ArgFloat   (args[i].(float32       ))
		//	case C.DC_SIGCHAR_DOUBLE:                            p.ArgDouble  (args[i].(float64       ))
		//	case C.DC_SIGCHAR_POINTER,  C.DC_SIGCHAR_STRING:     p.ArgPointer (args[i].(unsafe.Pointer))
		//	case C.DC_SIGCHAR_ENDARG:                            return
		//}
	}
}


// Calls
func (p *CallVM) CallVoid        (funcptr unsafe.Pointer)                {                       C.dcCallVoid    (p.cvm, C.DCpointer(funcptr))  }
func (p *CallVM) CallBool        (funcptr unsafe.Pointer) bool           { b := (C.dcCallBool(p.cvm, C.DCpointer(funcptr))); if b==C.DC_TRUE { return true } else { return false } }
func (p *CallVM) CallChar        (funcptr unsafe.Pointer) int8           { return int8          (C.dcCallChar    (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallShort       (funcptr unsafe.Pointer) int16          { return int16         (C.dcCallShort   (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallInt         (funcptr unsafe.Pointer) int            { return int           (C.dcCallInt     (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallLong        (funcptr unsafe.Pointer) int32          { return int32         (C.dcCallLong    (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallLongLong    (funcptr unsafe.Pointer) int64          { return int64         (C.dcCallLongLong(p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallFloat       (funcptr unsafe.Pointer) float32        { return float32       (C.dcCallFloat   (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallDouble      (funcptr unsafe.Pointer) float64        { return float64       (C.dcCallDouble  (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallPointer     (funcptr unsafe.Pointer) unsafe.Pointer { return unsafe.Pointer(C.dcCallPointer (p.cvm, C.DCpointer(funcptr))) }
func (p *CallVM) CallPointerToStr(funcptr unsafe.Pointer) string         { return C.GoString((*C.char)(C.dcCallPointer (p.cvm, C.DCpointer(funcptr)))) } // For convenience
//@@@func (p *CallVM) CallStruct  (funcptr unsafe.Pointer, s C.DCstruct* s, returnValue unsafe.Pointer)

// "Formatted" calls
//@@@func (p *CallVM) Call(result, funcptr unsafe.Pointer, signature string, args ...interface{}) {
//@@@...
//@@@}


//void dcCallF (DCCallVM* vm, DCValue* result, DCpointer funcptr, const DCsigchar* signature, ...);

/*
DC_API DCstruct*  dcNewStruct      (DCsize fieldCount, DCint alignment);
DC_API void       dcStructField    (DCstruct* s, DCint type, DCint alignment, DCsize arrayLength);
DC_API void       dcSubStruct      (DCstruct* s, DCsize fieldCount, DCint alignment, DCsize arrayLength);  	
DC_API void       dcCloseStruct    (DCstruct* s);  	
DC_API DCsize     dcStructSize     (DCstruct* s);  	
DC_API DCsize     dcStructAlignment(DCstruct* s);  	
DC_API void       dcFreeStruct     (DCstruct* s);

DC_API DCstruct*  dcDefineStruct  (const char* signature);
*/

