dyncall go bindings
Copyright 2014-2016 Tassilo Philipp
February 23, 2014


BUILD/INSTALLATION
------------------

1) make sure dyncall is built and libraries/headers are in include paths or
   CGO_CFLAGS points to them, etc.

2) Build this nut with:
   go build


API
---

Since go is low level, dyncall's public functions are pretty much exposed
function by function. Referg to dyncall(3) and godc.go.

l := new(ExtLib)
err := l.Load(libpath)
defer l.Free()
err := l.SymsInit(libpath)
defer l.SymsCleanup()

l.lib // Address lib is loaded at
l.FindSymbol(symbolname)
l.SymsCount()
l.SymsNameFromValue(l.FindSymbol(synbolname))
l.SymsName(index)

vm := new(CallVM)
err := vm.InitCallVM()
defer vm.Free()
vm.Mode(DC_CALL_C_DEFAULT)
vm.Reset()
vm.ArgFloat(36)
rf := vm.CallFloat(l.FindSymbol("sqrtf"))

vm.Arg....


SIGNATURE FORMAT
----------------

Signature string is only used by ArgF function, rest uses type info from Go.

TYPE CONVERSIONS (and reserved signature char)

  SIG | FROM GO             | C/C++              | TO GO
  ----+---------------------+--------------------+----------------
  'v' |                     | void               | 
  'B' | bool                | bool               | bool
  'c' | int8,C.schar        | char               | int8
  'C' | uint8,byte,C.uchar  | unsigned char      | uint8,byte
  's' | int16,C.sshort      | short              | int16
  'S' | uint16,C.ushort     | unsigned short     | uint16
  'i' | int32,C.sint        | int                | int32
  'I' | uint32,C.uint       | unsigned int       | uint32
  'j' | int32,rune,C.slong  | long               | int32,rune
  'J' | uint32,C.ulong      | unsigned long      | uint32
  'l' | int64,C.slonglong   | long long          | int64
  'L' | uint64,C.ulonglong  | unsigned long long | uint64
  'f' | float32,C.float     | float              | float32
  'd' | float64,C.double    | double             | float64
  'p' | *,[],unsafe.Pointer | void*              | unsafe.Pointer
  'Z' | string              | void*              | string


ToDo:
- structs
- callbacks
- callf wrap (argf already there)

