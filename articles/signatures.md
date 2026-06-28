# Signatures for C calls

`rdyncall` uses compact signatures to describe C values and C function
types. The signature is the contract between R and the foreign function.
It must match the C declaration.

Use this article when you have a C prototype, header declaration, or
manual page and need to turn it into an rdyncall type, call, callback,
or library signature. Most binding bugs start as translation bugs, so
this is the article to keep open while writing wrappers.

## Type signatures

Type signatures describe individual C values. The most common ones are:

| Signature | C type                            | R-side value      |
|:----------|:----------------------------------|:------------------|
| `B`       | `bool`                            | logical           |
| `c`, `C`  | `char`, `unsigned char`           | integer           |
| `s`, `S`  | `short`, `unsigned short`         | integer           |
| `i`, `I`  | `int`, `unsigned int`             | integer or double |
| `j`, `J`  | `long`, `unsigned long`           | double            |
| `l`, `L`  | `long long`, `unsigned long long` | double            |
| `f`, `d`  | `float`, `double`                 | double            |
| `p`       | pointer                           | external pointer  |
| `Z`       | nul-terminated C string           | character         |
| `x`       | `SEXP`                            | any R object      |
| `v`       | `void` return                     | `NULL`            |

Pointer types are written with `*`, such as `*i` for `int *`. Typed
aggregate pointers are written as `*<TypeName>`. Registered aggregate
values passed by value are written as `<TypeName>`.

## Call signatures

A call signature has the form:

``` text
argument-types ) return-type
```

For example:

``` c
double sqrt(double x);
```

becomes:

``` text
d)d
```

The part before `)` lists fixed arguments in order. The part after `)`
is the return value. Functions with no arguments start with `)`, such as
`)i` for `int f(void)`.

## Common prototype patterns

Start from the C prototype and classify each piece before writing the
compact signature.

| C pattern                                | rdyncall pattern                                                                        | What to check                                                                                                               |
|:-----------------------------------------|:----------------------------------------------------------------------------------------|:----------------------------------------------------------------------------------------------------------------------------|
| `double x`                               | `d`                                                                                     | scalar value, copied into C                                                                                                 |
| `const char *s`                          | `Z`                                                                                     | nul-terminated input string                                                                                                 |
| `char *buf`                              | `p`                                                                                     | output or mutable buffer, not an R string                                                                                   |
| `double *x`                              | `p`                                                                                     | pointer to mutable numeric memory                                                                                           |
| `void *userdata`                         | `p`                                                                                     | opaque pointer, interpret only if the API documents it                                                                      |
| `SEXP x`                                 | `x`                                                                                     | R object passed to R API code                                                                                               |
| `struct Rect *r`                         | `p` or `*<Rect>`                                                                        | use a typed pointer only when an aggregate type is registered                                                               |
| `int (*cmp)(const void *, const void *)` | `p`                                                                                     | pass a [`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md) pointer with callback signature `pp)i` |
| `void f(...)`                            | use [`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md) | fixed and vararg types are handled separately                                                                               |

Do not use `Z` for every `char *`. It is right for nul-terminated
strings. It is not enough for writable buffers, byte arrays, or strings
whose lifetime is owned by a foreign library.

## Callback signatures

Callback signatures use the same `argument-types ) return-type` shape,
but they describe the function pointer that C will call.

| C callback type                       | rdyncall callback signature |
|:--------------------------------------|:----------------------------|
| `int (*)(int, int)`                   | `ii)i`                      |
| `void (*)(int, void *)`               | `ip)v`                      |
| `int (*)(const void *, const void *)` | `pp)i`                      |
| `SEXP (*)(SEXP)`                      | `x)x`                       |

The C function that receives the callback still sees a pointer argument,
so its own call signature uses `p` at that argument position.

## Translation examples

The table below shows the same translation pattern for several APIs used
in the articles and demos.

| C declaration                                                                                   | rdyncall form                  | Notes                            |
|:------------------------------------------------------------------------------------------------|:-------------------------------|:---------------------------------|
| `int puts(const char *s);`                                                                      | `puts(Z)i`                     | string input and integer status  |
| `double sqrt(double x);`                                                                        | `sqrt(d)d`                     | one `double` argument and return |
| `size_t strlen(const char *s);`                                                                 | `strlen(Z)L`                   | `Z` passes a C string            |
| `void R_rsort(double *x, int n);`                                                               | `R_rsort(pi)v`                 | pointer to mutable `double` data |
| `double R_pow(double x, double y);`                                                             | `R_pow(dd)d`                   | two scalar arguments             |
| `void qsort(void *base, size_t nmemb, size_t size, int (*compar)(const void *, const void *));` | `qsort(pLLp)v`                 | callback has signature `pp)i`    |
| `int visit(Point p);`                                                                           | callback signature `<Point>)i` | `Point` is passed by value       |
| `const char *SDL_GetPlatform(void);`                                                            | `SDL_GetPlatform()Z`           | no arguments, C string return    |

The following example calls C’s `strlen`, declared as:

``` c
size_t strlen(const char *s);
```

``` r
libc_names <- c("msvcrt", "c", "c.so.6")
libc <- new.env(parent = globalenv())
dynbind(libc_names, "strlen(Z)L;", envir = libc)
#> dynbind report
#>   library: libc.so.6
#>   unresolved symbols: 0

libc$strlen("rdyncall")
#> [1] 8
```

`Z` passes a C string and `L` receives the `size_t` result as an
unsigned 64-bit-compatible numeric value on R’s side.

## R API symbols

The R shared library itself can also be bound. This is useful for
examples because R is available wherever the package is loaded.

``` r
rapi <- new.env(parent = globalenv())
dynbind("R", "R_pow(dd)d; R_rsort(pi)v;", envir = rapi)
#> dynbind report
#>   library: libR.so
#>   unresolved symbols: 0

rapi$R_pow(2, 10)
#> [1] 1024

x <- c(3.5, 1.25, 8.0, -2.0)
rapi$R_rsort(x, length(x))
#> NULL
x
#> [1] -2.00  1.25  3.50  8.00
```

`R_rsort(double *x, int n)` mutates the R numeric vector in place
because the first argument is a pointer to the vector data.

## Library signatures

[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
accepts a library signature: a semicolon-separated list of function
bindings.

``` r
math_names <- c("msvcrt", "m", "m.so.6")
math <- new.env(parent = globalenv())
dynbind(
    math_names,
    paste(
        "sqrt(d)d",
        "cos(d)d",
        "sin(d)d",
        sep = ";"
    ),
    envir = math
)
#> dynbind report
#>   library: libm.so.6
#>   unresolved symbols: 0

c(
    sqrt = math$sqrt(81),
    cos = math$cos(0),
    sin = math$sin(pi / 2)
)
#> sqrt  cos  sin 
#>    9    1    1
```

Whitespace around function bindings is ignored, so longer signatures can
be formatted for readability.

## Variadic functions

C functions declared with `...` need
[`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
The fixed parameters and return type go in `signature`; the actual
vararg types for this call site go in `varargs`.

``` r
libc_names <- c("msvcrt", "c", "c.so.6")
printf_addr <- dynsym(dynfind(libc_names), "printf")
dyncall_variadic(
    printf_addr,
    "Z)i",
    varargs = "i",
    "value = %d\n",
    42L
)
```

Default C promotions are your responsibility. For example, a variadic
`float` argument should be passed as a promoted `double`.

## A practical translation checklist

- Start from the C declaration, not from a guessed R value.
- Translate every fixed argument in order.
- Put `)` before the return type.
- Use pointer signatures for output buffers and mutable arrays.
- Keep callback and struct lifetimes explicit.
- Test with tiny inputs before calling code that allocates, frees, opens
  files, or enters an event loop.

## Next steps

- Use [getting
  started](https://hongyuanjia.github.io/rdyncall/articles/rdyncall.md)
  for the shortest load-resolve-call path.
- Use [structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.md)
  when a signature includes aggregate values, raw buffers, or output
  pointers.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  when a signature contains a C function pointer.
- Use
  [troubleshooting](https://hongyuanjia.github.io/rdyncall/articles/troubleshooting.md)
  to diagnose unresolved symbols, wrong return values, crashes, and
  platform differences.
