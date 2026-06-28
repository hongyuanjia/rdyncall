# Utility functions for working with foreign C data types

Functions for low-level operations on C pointers as well as helper
functions and objects to handle C `float` arrays and strings.

## Usage

``` r
is.nullptr(x)

as.externalptr(x)

offset_ptr(x, offset)

is.externalptr(x)

as.floatraw(x)

floatraw2numeric(x)

floatraw(n)

# S3 method for class 'floatraw'
print(x, ...)

ptr2str(x)

strarrayptr(x)

strptr(x)
```

## Arguments

- x:

  object to test, convert, or pass to a pointer/string helper.

- offset:

  integer specifying *byte offset* starting at 0.

- n:

  integer specifying the number of single-precision C `float` values to
  allocate.

- ...:

  additional arguments to be passed to
  [`base::print()`](https://rdrr.io/r/base/print.html) methods.

## Value

A logical value is returned by `is.nullptr()` and `is.externalptr()`.
`as.externalptr()` and `offset_ptr()` returns an external pointer value.
`floatraw()` and `as.floatraw()` return an atomic vector of type `raw`
tagged with class `floatraw`. `floatraw2numeric` returns a `numeric`
atomic vector.

## Details

`is.nullptr()` tests if the external pointer given by `x` represents a C
`NULL` pointer.

`as.externalptr()` returns an external pointer to the data area of
atomic vector given by `x`. The external pointer holds an additional
reference to the `x` R object to prevent it from garbage collection. `x`
must have length greater than zero.

`is.externalptr()` tests if the object given by `x` is an external
pointer.

`floatraw()` creates an array with a capacity to store `n`
single-precision C `float` values. The array is implemented via a
[`base::raw()`](https://rdrr.io/r/base/raw.html) vector.

`as.floatraw()` coerces a numeric vector into a single-precision C
`float` vector. Values given by `x` are converted to C `float` values
and stored in the R raw vector via
[`pack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md).
This function is useful when calling foreign functions that expect a C
`float` pointer via
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).

`floatraw2numeric()` coerces a C `float` (raw) vector to a numeric
vector.

`ptr2str()`, `strarrayptr()`, `strptr()` are currently experimental.

`offset_ptr()` creates a new external pointer pointing to `x` plus the
non-negative byte `offset`. If `x` is given as an external pointer, the
address is increased by the `offset`, or, if `x` is given as a atomic
vector, the address of the data (pointing to offset zero) is taken as
basis and increased by the `offset`. Atomic vector offsets are checked
against the vector byte size. The returned external pointer is protected
(as offered by the C function `R_MakeExternalPtr`) by the external
pointer `x`.

## Examples

``` r
is.nullptr(NULL)
#> [1] FALSE

one <- as.externalptr(1)
is.externalptr(one)
#> [1] TRUE

floatraw(1)
#> floatraw[1]: 0

floats <- as.floatraw(1:10)
all.equal(floatraw2numeric(floats), 1:10)
#> [1] TRUE
```
