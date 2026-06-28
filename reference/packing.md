# Handling of foreign C fundamental data types

Functions to unpack/pack (read/write) foreign C data types from/to R
atomic vectors and C data objects such as arrays and pointers to
structures.

## Usage

``` r
pack(x, offset, sigchar, value)

unpack(x, offset, sigchar)
```

## Arguments

- x:

  atomic vector (logical, raw, integer or double) or external pointer.

- offset:

  integer specifying *byte offset* starting at 0.

- sigchar:

  character string specifying the C data type by a [type
  signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).

- value:

  R object value to be coerced and packed to a foreign C data type.

## Value

`unpack()` returns a read C data type coerced to an R value.

## Details

The function `pack()` converts an R `value` into a C data type specified
by the
[signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
`sigchar` and it writes the raw C foreign data value at byte position
`offset` into the object `x`.

The function `unpack()` extracts a C data type according to the
[signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
`sigchar` at byte position `offset` from the object `x` and converts the
C value to an R value and returns it.

Byte `offset` calculations start at 0 relative to the first byte in an
atomic vectors data area. Offsets must be non-missing, non-negative
integer scalars.

If `x` is an atomic vector, a bound check is carried out before
read/write access. Otherwise, if `x` is an external pointer, there is
only a C NULL pointer check. Values read from R vectors must have length
greater than zero.

## See also

[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for details on type signatures.

## Examples

``` r
# transfer double to array of floats and back, compare precision:
n <- 6
input <- rnorm(n)
buf <- raw(n*4)
for (i in 1:n) {
    pack(buf, 4 * (i - 1), "f", input[i])
}

output <- numeric(n)
for (i in 1:n) {
    output[i] <- unpack(buf, 4 * (i - 1), "f")
}
# difference between double and float
difference <- output - input
print(cbind(input, output, difference))
#>           input     output    difference
#> [1,] -0.3872136 -0.3872136 -1.251252e-08
#> [2,] -0.7854327 -0.7854326  1.904251e-08
#> [3,] -1.0567369 -1.0567368  4.009650e-08
#> [4,] -0.7955414 -0.7955414  2.387001e-08
#> [5,] -1.7562754 -1.7562754  1.275035e-08
#> [6,] -0.6905379 -0.6905379  2.689148e-08
```
