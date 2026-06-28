# Structs, unions, and memory

Many C APIs exchange data through structs, unions, arrays, and pointers.
`rdyncall` models those layouts at run time so R code can read and write
the same memory shape that C expects.

Use this article when a C function takes a struct, fills an output
buffer, returns a pointer to memory, or expects fields with C-specific
alignment, packing, arrays, bitfields, or unions. The goal is to choose
the highest-level rdyncall memory interface that still matches the C API
exactly.

## Raw memory with `pack()` and `unpack()`

The lowest-level tools are
[`pack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)
and
[`unpack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md).
They write and read C values inside raw vectors or memory referenced by
external pointers.

``` r
buf <- raw(8)
pack(buf, 0, "f", 1.5)
#> NULL
pack(buf, 4, "f", 2.25)
#> NULL

c(
    first = unpack(buf, 0, "f"),
    second = unpack(buf, 4, "f")
)
#>  first second 
#>   1.50   2.25
```

Offsets are byte offsets starting at 0.

## Choosing a memory interface

Use the highest-level interface that still matches the C API you are
binding.

| Need                                                     | Use                                                                                                                                                                                                                                             |
|:---------------------------------------------------------|:------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Read or write a named aggregate field                    | `$` and `$<-` on a [`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md) object                                                                                                                                               |
| Fill an output buffer or scalar field by byte offset     | [`pack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)                                                                                                                                                                         |
| Read a value from a pointer or raw buffer by byte offset | [`unpack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)                                                                                                                                                                       |
| Treat existing raw memory as a registered aggregate      | [`as.ctype()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)                                                                                                                                                                      |
| Pass an aggregate by value                               | [`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md) with a registered [`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md) or [`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md) |

## Register a struct

This C type:

``` c
struct Rect {
  short x;
  short y;
  unsigned short w;
  unsigned short h;
};
```

is represented by one structure signature:

``` r
cstruct("DocRect{ssSS}x y w h;")
DocRect
#> struct typeinfo DocRect
#>   size: 8
#>   align: 2
#>   signature: ssSS
#>   fields:
#>  name type offset array_len
#>     x    s      0         1
#>     y    s      2         1
#>     w    S      4         1
#>     h    S      6         1

rect <- cdata(DocRect)
rect$x <- 10L
rect$y <- 20L
rect$w <- 200L
rect$h <- 100L

rect
#> struct DocRect {
#>    x :10 
#>    y :20 
#>    w :200 
#>    h :100 
#>  }
```

The object returned by
[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
is a raw vector with class metadata. Field access is translated into
byte-level reads and writes.

You can inspect the registered layout before passing data to C:

``` r
c(
    size = DocRect$size,
    align = DocRect$align
)
#>  size align 
#>     8     2

DocRect$fields[, c("name", "type", "offset", "array_len")]
#>   name type offset array_len
#> 1    x    s      0         1
#> 2    y    s      2         1
#> 3    w    S      4         1
#> 4    h    S      6         1
```

The field offsets are byte offsets in the aggregate. If values appear
shifted or truncated after a foreign call, compare this table with the C
compiler’s layout for the same type.

## Fixed-size array fields

Array lengths are written after the field type.

``` r
cstruct("DocColor{C[4]}rgba;")

color <- cdata(DocColor)
color$rgba <- c(255L, 128L, 0L, 255L)
color$rgba
#> [1] 255 128   0 255
```

The whole array field is assigned and read as an R vector.

## Nested aggregates

Struct fields can contain other registered aggregate types, including
fixed-size arrays of nested structs.

``` r
cstruct("DocVec2{ff}x y;")
cstruct("DocSegment{<DocVec2>[2]}points;")

a <- cdata(DocVec2)
a$x <- 1.25
a$y <- 2.5

b <- cdata(DocVec2)
b$x <- 3.5
b$y <- 4.75

segment <- cdata(DocSegment)
segment$points <- list(a, b)
segment$points
#> [[1]]
#> struct DocVec2 {
#>    x :0 
#>    y :0 
#>  }
#> 
#> [[2]]
#> struct DocVec2 {
#>    x :0 
#>    y :0 
#>  }
```

Nested structs are still raw-backed values. This matters when they are
passed by value to C functions on supported platforms.

## Bitfields

Bitfields keep their ordinary integer storage type in the type list and
put the bit width in the field-name list.

``` r
cstruct("DocBits{IIII}enabled:1 mode:3 :4 code:8;")

bits <- cdata(DocBits)
bits$enabled <- 1L
bits$mode <- 5L
bits$code <- 171L

c(
    enabled = bits$enabled,
    mode = bits$mode,
    code = bits$code
)
#> enabled    mode    code 
#>       1       5     171

DocBits$fields[, c("name", "type", "offset", "bit_offset", "bit_width",
                   "storage_offset", "storage_size")]
#>      name type offset bit_offset bit_width storage_offset storage_size
#> 1 enabled    I      0          0         1              0            4
#> 2    mode    I      0          1         3              0            4
#> 3            I      0          4         4              0            4
#> 4    code    I      1          8         8              0            4
```

Unnamed bitfields such as `:4` reserve padding bits. A zero-width
unnamed bitfield, written `:0`, aligns the next bitfield to a new
storage unit.

## Packed and aligned layouts

Layout directives appear after the field list.

``` r
cstruct("DocPacked{Cd}tag value @packed;")
cstruct("DocPack4{Cd}tag value @pack(4);")
cstruct("DocAligned{C}tag @align(8);")

c(
    packed_size = DocPacked$size,
    packed_align = DocPacked$align,
    pack4_align = DocPack4$align,
    aligned_align = DocAligned$align
)
#>   packed_size  packed_align   pack4_align aligned_align 
#>             9             1             4             8

DocPacked$fields[, c("name", "type", "offset")]
#>    name type offset
#> 1   tag    C      0
#> 2 value    d      1
```

`@packed` is equivalent to `@pack(1)`. `@pack(n)` caps member alignment
at `n`, and `@align(n)` raises the final aggregate alignment to at least
`n`.

## Unions

Unions use `|` instead of `{` after the type name.

``` r
cunion("DocValue|iC[4]}i bytes;")

value <- cdata(DocValue)
value$i <- 16909060L
value$bytes
#> [1] 4 3 2 1
```

All union fields share the same storage. Writing one field changes what
another field reads from the same bytes.

## Safety notes

- Register the aggregate layout before using it in
  [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
- Keep the C definition beside the R signature while developing.
- Be careful with platform-dependent layout, especially packing and
  bitfields.
- Treat external pointers as borrowed memory unless the C API explicitly
  says that R owns or must free the pointer.

## Next steps

- Use
  [signatures](https://hongyuanjia.github.io/rdyncall/articles/signatures.md)
  to connect these memory layouts to function call signatures.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  when a struct or pointer is passed into an R callback from C.
- Use [FFI
  safety](https://hongyuanjia.github.io/rdyncall/articles/ffi-safety.md)
  before passing ownership-sensitive pointers or memory allocated by a
  foreign library.
- Use
  [troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.md)
  when field values look shifted, truncated, or platform-dependent.
