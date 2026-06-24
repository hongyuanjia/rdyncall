# S3 class for run-time type information of foreign C data types

S3 class for run-time type information of foreign C data types.

## Usage

``` r
typeinfo(
  name,
  type = c("base", "pointer", "struct", "union"),
  size = NA,
  align = NA,
  basetype = NA,
  fields = NA,
  signature = NA
)

# S3 method for class 'typeinfo'
print(x, ...)

get_typeinfo(name, envir = parent.frame())
```

## Arguments

- name:

  character string specifying the type name.

- type:

  character string specifying the type.

- size:

  integer, size of type in bytes.

- align:

  integer, alignment of type in bytes.

- basetype:

  character string, base type of 'pointer' types.

- fields:

  data frame with name, type, offset and optional array or bitfield
  layout information that specifies aggregate struct and union types.

- signature:

  character string specifying the struct/union type
  [signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).

- x:

  S3 `typeinfo` object to print.

- ...:

  additional arguments to be passed to
  [`base::print()`](https://rdrr.io/r/base/print.html) methods.

- envir:

  the environment to look for type object.

## Value

List object tagged as S3 class `typeinfo` with the following named
entries

- type:

  Type name.

- size:

  Size in bytes.

- align:

  Alignment in bytes.

- fields:

  Data frame for field information with the following columns:

  |                  |                                              |
  |------------------|----------------------------------------------|
  | `name`           | field name                                   |
  | `type`           | type name                                    |
  | `offset`         | byte offset (starts counted from 0)          |
  | `array_len`      | fixed array length, or 1 for scalar fields   |
  | `bit_offset`     | bitfield offset, or `NA` for ordinary fields |
  | `bit_width`      | bitfield width, or `NA` for ordinary fields  |
  | `storage_offset` | bitfield storage-unit byte offset            |
  | `storage_size`   | bitfield storage-unit size in bytes          |

## Details

Type information objects are created at run-time to describe the
concrete layout of foreign C data types on the host machine. While [type
signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)s
give an abstract information on e.g. the field types and names of
aggregate structure types, these objects store concrete memory size,
alignment and layout information about C data types.

## See also

[`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
for details on the framework for handling foreign C data types.
