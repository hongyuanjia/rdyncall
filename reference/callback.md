# Dynamic wrapping of R functions as C callbacks

Function to wrap R functions as C function pointers.

## Usage

``` r
ccallback(signature, fun, envir = new.env())
```

## Arguments

- signature:

  character string specifying the [call
  signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
  of the C function callback type.

- fun:

  R function to be wrapped as a C function pointer.

- envir:

  the environment in which to evaluate the call to `fun`.

## Value

An external pointer to a synthetically generated C function.

## Details

Callbacks are user-defined functions that are registered in a foreign
library and that are executed at a later time from within that library.
Examples include user-interface event handlers that are registered in
GUI toolkits, and, comparison functions for custom data types to be
passed to generic sort algorithm.

The function `ccallback()` wraps an R function `fun` as a C function
pointer and returns an external pointer. The foreign C function type of
the wrapped R function is specified by a [call
signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
given by `signature`.

When the C function pointer is called, a global callback handler
(implemented in C) is executed first, that dynamically creates an R call
expression to `fun` using the arguments, passed from C and converted to
R, according to the argument types signature within the [call
signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
specified. See
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for details on the format.

Finally, the handler evaluates the R call expression within the
environment given by `envir`. On return, the R return value of `fun` is
coerced to the C value, according to the return type signature specified
in `signature` .

Aggregate by-value callback arguments and returns use the same `<Type>`
signature syntax as
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
An aggregate argument is passed to the R callback as a raw-backed
`cdata` object with `struct` and `typeinfo` attributes. An aggregate
return value must be a raw-backed object for the same aggregate type and
size. Type or storage mismatches disable the callback and emit a
warning.

Aggregate callbacks are supported on the implemented 64-bit x86 and
ARM64 dyncallback backends. On unsupported backends, creating a callback
whose signature contains `<Type>` fails early.

If an error occurs during the evaluation, the callback will be disabled
for further invocations. (This behaviour might change in the future.)

## Note

The call signature **MUST** match the foreign C callback function type,
otherwise an activated callback call from C can lead to a **fatal R,
process crash**.

A small amount of memory is allocated with each wrapper. A finalizer
function that frees the allocated memory is registered at the external
pointer. If the external callback function pointer is registered in a C
library, a reference should also be held in R as long as the callback
can be activated from a foreign C run-time context, otherwise the
garbage collector might call the finalizer and the next invocation of
the callback could lead to a **fatal R process crash** as well.

## References

Adler, D. (2012) "Foreign Library Interface", *The R Journal*, **4(1)**
, 30–40, June 2012.
<https://journal.r-project.org/articles/RJ-2012-004/>

Adler, D., Philipp, T. (2008) *DynCall Project*. <https://dyncall.org>

## See also

See [call
signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for details on call signatures,
[`reg.finalizer()`](https://rdrr.io/r/base/reg.finalizer.html) for
details on finalizers.

## Examples

``` r
# Create a function, wrap it to a callback and call it via dyncall:
f <- function(x, y) x + y
cb <- ccallback("ii)i", f)
r <- dyncall(cb, "ii)i", 20, 3)

# Sort vectors directly via 'qsort' C library function using an R callback:
dynbind(c("msvcrt","c","c.so.6"), "qsort(piip)v;")
#> dynbind report
#>   library: libc.so.6
#>   unresolved symbols: 0
cb <- ccallback("pp)i", function(px, py) {
    x <- unpack(px, 0, "d")
    y <- unpack(py, 0, "d")
    if (x >  y) return(1) else if (x == y) return(0) else return(-1)
})
x <- rnorm(100)
qsort(x, length(x), 8, cb)
#> NULL
x
#>   [1] -2.612334333 -2.437263611 -2.274114857 -1.911720491 -1.910087468
#>   [6] -1.863011492 -1.821817661 -1.699450568 -1.630989402 -1.512399651
#>  [11] -1.470736306 -1.400043517 -1.304543545 -1.177563309 -0.975850616
#>  [16] -0.935847354 -0.914074827 -0.826788954 -0.665088249 -0.639123324
#>  [21] -0.553699384 -0.548257264 -0.522012515 -0.381951112 -0.361221255
#>  [26] -0.354361164 -0.313445978 -0.296640025 -0.282705449 -0.279237242
#>  [31] -0.251483443 -0.247325302 -0.245896412 -0.244199607 -0.243236740
#>  [36] -0.206087195 -0.155693776 -0.133997013 -0.109935672 -0.097445104
#>  [41] -0.090327287 -0.052601910 -0.049964899 -0.038102895 -0.015950311
#>  [46] -0.005571287  0.019177592  0.029560754  0.046531380  0.070034850
#>  [51]  0.112038083  0.118194874  0.131670635  0.172181715  0.176488611
#>  [56]  0.213355750  0.236696283  0.243685465  0.255317055  0.284150344
#>  [61]  0.362951256  0.424187575  0.433889790  0.444797116  0.468154420
#>  [66]  0.486148920  0.488628809  0.512426950  0.523909788  0.542996343
#>  [71]  0.549827542  0.556224329  0.577709069  0.606748047  0.621552721
#>  [76]  0.628982042  0.737776321  0.748791268  0.862086482  0.935363190
#>  [81]  0.946347886  1.048712620  1.063101996  1.065057320  1.067307879
#>  [86]  1.074345882  1.110534893  1.113952419  1.148411606  1.298392759
#>  [91]  1.316826356  1.318293384  1.337320413  1.623548883  1.672882611
#>  [96]  1.888504929  1.924343341  2.065024895  2.682557184  2.755417575
```
