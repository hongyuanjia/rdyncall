# Getting started with rdyncall

`rdyncall` is a low-level Foreign Function Interface (FFI) for R. It
lets you load shared C libraries, resolve symbols, and call C functions
directly from R when you know the C declaration you want to bind.

It is useful for exploration, prototypes, dynamic bindings, and small
direct interfaces. For stable high-level R packages, a compiled `.Call`
wrapper may still be the better long-term interface.

## A first direct call

The basic workflow has three steps:

1.  Find or load a shared library.
2.  Resolve a function symbol.
3.  Call the address with a signature that matches the C function type.

The C math function is declared as:

``` c
double sqrt(double x);
```

The corresponding rdyncall call signature is `"d)d"`: one `double`
argument, then `)`, then a `double` return value.

``` r
math_names <- c("msvcrt", "m", "m.so.6")
mathlib <- dynfind(math_names)
sqrt_addr <- dynsym(mathlib, "sqrt")
dyncall(sqrt_addr, "d)d", 144)
#> [1] 12
```

If the signature does not match the real C function type, the process
can crash. Keep the C declaration beside the R binding while you
develop.

## Wrap the same idea

[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
creates thin R wrappers for one or more functions in a library. The
wrapper still uses the same signature internally, but the call site
becomes ordinary R code.

``` r
math <- new.env(parent = globalenv())
info <- dynbind(math_names, "sqrt(d)d;", envir = math)
article_expect_symbols(info, "math library")

math$sqrt(625)
#> [1] 25
```

## Call an R function through a C callback pointer

[`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
turns an R function into a C function pointer. The signature describes
the callback function type.

``` r
add <- ccallback("ii)i", function(x, y) x + y)
dyncall(add, "ii)i", 20L, 3L)
#> [1] 23
```

Keep an R reference to callback objects for as long as foreign code may
call them. If a callback is garbage-collected while C still holds its
pointer, the next C call can crash R.

## Describe and use a C struct

C aggregate types are registered with compact structure signatures. This
C type:

``` c
struct Rect {
  short x;
  short y;
  unsigned short w;
  unsigned short h;
};
```

can be registered and used from R:

``` r
cstruct("ArticleRect{ssSS}x y w h;")

rect <- cdata(ArticleRect)
rect$x <- 40L
rect$y <- 60L
rect$w <- 10L
rect$h <- 15L

rect$w * rect$h
#> [1] 150
```

[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
returns a raw-backed object with struct metadata. Field access reads and
writes the raw bytes according to the registered layout.

## What to learn next

- Use
  [signatures](https://hongyuanjia.github.io/rdyncall/articles/signatures.md)
  to translate C declarations into rdyncall signatures.
- Use [structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.md)
  for aggregate layouts and raw memory access.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  when a C API stores and later calls an R function pointer.
- Use [dynbind and
  dynport](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.md)
  for larger bindings.
