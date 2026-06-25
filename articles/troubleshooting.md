# Troubleshooting rdyncall bindings

Foreign-function bugs usually fail at one of five boundaries: library
discovery, symbol lookup, signature translation, memory layout, or
callback lifetime. Work from the outside in and prove each boundary
before adding the next one.

## Library discovery

Start by proving that rdyncall can find and load the shared library. Use
several candidate names for cross-platform code.

``` r
math_names <- c("msvcrt", "m", "m.so.6")
mathlib <- dynfind(math_names)
is.nullptr(mathlib)
#> [1] FALSE
```

When this returns `TRUE`, inspect the exact candidates rdyncall tried:

``` r
dynfind_explain(math_names)
#> First loadable dynfind candidate:
#>  libname source candidate exists loaded                       resolved_path
#>   m.so.6 loader libm.so.6  FALSE   TRUE /usr/lib/x86_64-linux-gnu/libm.so.6
#> 
#> All candidates:
#>  libname source    candidate exists loaded                       resolved_path
#>   msvcrt loader libmsvcrt.so  FALSE  FALSE                                <NA>
#>   msvcrt loader    libmsvcrt  FALSE  FALSE                                <NA>
#>   msvcrt loader       msvcrt  FALSE  FALSE                                <NA>
#>        m loader      libm.so  FALSE  FALSE                                <NA>
#>        m loader         libm  FALSE  FALSE                                <NA>
#>        m loader            m  FALSE  FALSE                                <NA>
#>   m.so.6 loader libm.so.6.so  FALSE  FALSE                                <NA>
#>   m.so.6 loader    libm.so.6  FALSE   TRUE /usr/lib/x86_64-linux-gnu/libm.so.6
#>   m.so.6 loader       m.so.6  FALSE     NA                                <NA>
```

If no candidate loads, try a full path with
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md),
check whether the library is installed for the current architecture, and
remember that names differ by platform and package manager.

## Windows DLL discovery

Windows failures are often caused by a DLL existing on disk while one of
its transitive DLL dependencies is missing from the loader search path.
A direct `dynload("C:/path/to/foo.dll")` can still fail when `foo.dll`
depends on another DLL that Windows cannot find.

Use
[`dynfind_explain()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
first. It reports package-manager candidates from the R runtime, Scoop,
MSYS2, vcpkg, and conda, whether the file exists, and whether it
actually loaded.

``` r
dynfind_explain("SDL3")
```

The common fixes are:

| Installation source | Directory rdyncall checks                                                 |
|:--------------------|:--------------------------------------------------------------------------|
| Scoop               | `SCOOP/apps/<name>/current/bin` and related app directories               |
| MSYS2               | `MINGW_PREFIX/bin`, `MSYSTEM_PREFIX/bin`, and common `C:/msys64` prefixes |
| vcpkg               | `VCPKG_ROOT/installed/<triplet>/bin`                                      |
| conda               | `CONDA_PREFIX/Library/bin` and `CONDA_PREFIX/bin`                         |

For transitive DLL failures, put the dependency DLLs beside the primary
DLL or add their directory to `PATH` before starting R. After changing
`PATH`, restart R so the process has the updated loader environment.

## Symbol lookup

Once the library is loaded, resolve a known function and check the
pointer.

``` r
sqrt_addr <- dynsym(mathlib, "sqrt")
is.nullptr(sqrt_addr)
#> [1] FALSE
```

If a library loads but a symbol is missing, verify the exact exported
symbol name with platform tools such as `nm`, `otool`, `dumpbin`, or
`objdump`. C++ APIs may export mangled names unless the header uses
`extern "C"`.

## Signature symptoms

Wrong signatures are the most dangerous class of error. They can return
nonsense, corrupt memory, or crash the R session.

| Symptom                               | First place to check                                        |
|:--------------------------------------|:------------------------------------------------------------|
| Correct function, wrong numeric value | scalar type width or signedness                             |
| Crash on return                       | return type or calling convention                           |
| Crash after several arguments         | missing argument, wrong pointer type, or variadic promotion |
| String is truncated or invalid        | `Z` used for data that is not a nul-terminated string       |
| Vector changes unexpectedly           | a pointer argument lets C mutate R memory                   |

Keep the C prototype beside the R signature and test with the smallest
input that exercises the binding.

## Pointer and memory issues

Treat pointers as borrowed memory unless the C API explicitly says
otherwise. Before reading or writing memory by offset, inspect the
aggregate layout or write a small raw-buffer test.

``` r
buf <- raw(8)
pack(buf, 0, "d", 12.5)
#> NULL
unpack(buf, 0, "d")
#> [1] 12.5
```

For structs and unions, inspect size, alignment, and field offsets:

``` r
cstruct("TroubleRect{ssSS}x y w h;")

c(
    size = TroubleRect$size,
    align = TroubleRect$align
)
#>  size align 
#>     8     2

TroubleRect$fields[, c("name", "type", "offset")]
#>   name type offset
#> 1    x    s      0
#> 2    y    s      2
#> 3    w    S      4
#> 4    h    S      6
```

If a field value appears in the wrong place, compare these offsets with
the C compiler’s layout and check packing, alignment, bitfields, and
platform-specific type sizes.

## Callback failures

Callback problems are usually lifetime or error-boundary problems.

| Symptom                                    | Likely cause                                          |
|:-------------------------------------------|:------------------------------------------------------|
| Callback works once and then crashes later | the R callback object was garbage-collected           |
| Callback is called after cleanup           | C still holds a pointer after R dropped state         |
| Foreign event loop becomes unstable        | an R error crossed the callback boundary              |
| Callback receives strange values           | callback signature does not match the C callback type |

Keep the
[`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
object reachable for as long as C may call it. For stored callbacks,
pair the registration with the C API’s unregister function and clear the
R reference only after the foreign registration is gone.

## A debugging order

1.  Load the library with
    [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
    or
    [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md).
2.  Inspect failed library loads with
    [`dynfind_explain()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
3.  Resolve one required symbol with
    [`dynsym()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md).
4.  Call the smallest scalar function first.
5.  Add pointer or aggregate arguments only after the scalar call works.
6.  Add callbacks only after their standalone signature has been tested.
7.  Move from
    [`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
    to
    [`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
    or
    [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
    after the signature is proven.

## Next steps

- Use
  [signatures](https://hongyuanjia.github.io/rdyncall/articles/signatures.md)
  to translate the C prototype you are debugging.
- Use [structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.md)
  to inspect layout-sensitive data.
- Use
  [callbacks](https://hongyuanjia.github.io/rdyncall/articles/callbacks.md)
  for lifetime and error-boundary patterns.
