dyncall go bindings
Copyright 2014 Tassilo Philipp
February 23, 2014


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
- callf wrap
