# Allocation and handling of foreign C aggregate data types

Functions for allocation, access and registration of foreign C `struct`
and `union` data type.

## Usage

``` r
cstruct(sigs, envir = parent.frame())

cunion(sigs, envir = parent.frame())

as.ctype(x, type)

cdata(type)

# S3 method for class 'struct'
x$index

# S3 method for class 'struct'
x$index <- value

# S3 method for class 'struct'
print(x, indent = 0, ...)

# S3 method for class 'ctype'
print(x, ...)
```

## Arguments

- sigs:

  character string that specifies several C struct/union type
  `signature`s.

- envir:

  the environment to install S3 type information object(s).

- x:

  external pointer or atomic raw vector of S3 class 'struct'.

- type:

  S3
  [`typeinfo()`](https://hongyuanjia.github.io/rdyncall/reference/typeinfo.md)
  Object or character string that names the structure type.

- index:

  character string specifying the field name.

- value:

  value to be converted according to struct/union field type given by
  field index.

- indent:

  indentation level for pretty printing structures.

- ...:

  additional arguments to be passed to
  [`base::print()`](https://rdrr.io/r/base/print.html) method.

## Details

References to foreign C data objects are represented by objects of class
'struct'.

Two reference types are supported:

- *External pointers* returned by
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  using a call signature with a *typed pointer* return type signature
  and pointers extracted as a result of
  [`unpack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)
  and S3 `struct` `$`-operators.

- *Internal objects*, memory-managed by R, are allocated by `cdata()`:
  An atomic `raw` storage object is returned, initialized with length
  equal to the byte size of the foreign C data type.

In order to access and manipulate the data fields of foreign C aggregate
data objects, the `$` and `$<-` S3 operator methods can be used.

S3 objects of class `struct` have an attribute `struct` set to the name
of a
[typeinfo](https://hongyuanjia.github.io/rdyncall/reference/typeinfo.md)
object, which provides the run-time type information of a particular
foreign C type.

The run-time type information for foreign C `struct` and `union` types
need to be registered once via `cstruct` and `cunion` functions. The C
data types are specified by `sigs`, a signature character string. The
formats for both types are described next:

**Structure type signatures** describe the layout of aggregate `struct`
C data types. Type Signatures are used within the `field-types`.
Fixed-size array fields are written as a type signature followed by
`[N]`, for example `C[4]` for `unsigned char[4]` or `<Point>[2]` for two
nested aggregate values. `field-names` consists of space separated
identifier names and should match the number of fields. Integer
bitfields are written as `name:width` in the field name list. Unnamed
padding bitfields use `:width`; zero-width alignment bitfields use `:0`.
Optional layout directives can follow the field names before the final
semicolon.

    struct-name { field-types } field-names [layout-directives] ;

Here is an example of a C `struct` type:

    struct Rect {
      signed short x, y;
      unsigned short w, h;
    };

The corresponding structure type signature string is:

    "Rect{ssSS}x y w h;"

Bitfields keep the ordinary type signature in `field-types` and put the
bit width next to the field name:

    "Flags{IIII}a:1 b:3 :4 c:8;"

Packed or manually aligned aggregate layouts can be registered with
`@packed`, `@pack(n)` and `@align(n)` directives, where `n` must be a
positive power of two. `@packed` is equivalent to `@pack(1)`, `@pack(n)`
caps member alignment at `n`, and `@align(n)` raises the final aggregate
alignment to at least `n`.

    "Packed{Cd}c d @packed;"
    "Pack4{Cd}c d @pack(4);"
    "PackedAligned{Cd}c d @packed @align(8);"

**Union type signatures** describe the components of the `union` C data
type. Type signatures are used within the `field-types`. Fixed-size
array fields use the same `[N]` suffix as structure fields.
`field-names` consists of space separated identifier names and should
match the number of fields. The same layout directives can follow union
field names.

    union-name | field-types } field-names [layout-directives] ;

Here is an example of a C `union` type:

    union Value {
      int anInt;
      float aFloat;
      struct LongValue aStruct
    };

The corresponding union type signature string is:

    "Value|if<LongValue>}anInt aFloat aStruct;"

`as.ctype()` can be used to *cast* a foreign C data reference to a
different type. When using an external pointer reference, this can lead
quickly to a **fatal R process crash** - like in C.

## See also

[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for type signatures and
[`typeinfo()`](https://hongyuanjia.github.io/rdyncall/reference/typeinfo.md)
for details on run-time type information S3 objects.

## Examples

``` r
# Specify the following foreign type:
# struct Rect {
#     short x, y;
#     unsigned short w, h;
# }
cstruct("Rect{ssSS}x y w h;")
r <- cdata(Rect)
print(r)
#> struct Rect {
#>    x :0 
#>    y :0 
#>    w :0 
#>    h :0 
#>  }
r$x <- 40
r$y <- 60
r$w <- 10
r$h <- 15
print(r)
#> struct Rect {
#>    x :40 
#>    y :60 
#>    w :10 
#>    h :15 
#>  }
str(r)
#>  'struct' raw [1:8] 28 00 3c 00 ...
#>  - attr(*, "struct")= chr "Rect"
#>  - attr(*, "typeinfo")=List of 7
#>   ..$ name     : chr "Rect"
#>   ..$ type     : chr "struct"
#>   ..$ size     : int 8
#>   ..$ align    : num 2
#>   ..$ basetype : logi NA
#>   ..$ fields   :'data.frame':    4 obs. of  8 variables:
#>   .. ..$ name          : chr [1:4] "x" "y" "w" "h"
#>   .. ..$ type          : 'AsIs' chr [1:4] "s" "s" "S" "S"
#>   .. ..$ offset        : int [1:4] 0 2 4 6
#>   .. ..$ array_len     : int [1:4] 1 1 1 1
#>   .. ..$ bit_offset    : int [1:4] NA NA NA NA
#>   .. ..$ bit_width     : int [1:4] NA NA NA NA
#>   .. ..$ storage_offset: int [1:4] NA NA NA NA
#>   .. ..$ storage_size  : int [1:4] NA NA NA NA
#>   ..$ signature: chr "ssSS"
#>   ..- attr(*, "class")= chr "typeinfo"
#>  - attr(*, "typeinfo_env")=<environment: 0x56259dada760> 
```
