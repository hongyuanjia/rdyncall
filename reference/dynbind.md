# Binding C library functions via thin call wrappers

Function to bind several foreign functions of a C library via
installation of thin R call wrappers.

## Usage

``` r
dynbind(
  libnames,
  signature,
  envir = parent.frame(),
  callmode = "default",
  pattern = NULL,
  replace = NULL,
  funcptr = FALSE,
  variadic = FALSE
)

# S3 method for class 'dynbind.report'
print(x, ...)
```

## Arguments

- libnames:

  character vector or external pointer handle specifying the shared
  library. Character values that contain a path separator, or name an
  existing file, are passed directly to
  [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md).
  Other character values are treated as short library names and loaded
  using
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).
  External pointer handles returned by
  [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
  or
  [`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
  are used directly.

- signature:

  character string specifying the *library signature* that determines
  the set of foreign function names and types. See details.

- envir:

  the environment to use for installation of call wrappers.

- callmode:

  character string specifying the calling convention, see details.

- pattern:

  `NULL` or regular expression character string applied to symbolic
  names.

- replace:

  `NULL` or replacement character string applied to `pattern` part of
  symbolic names.

- funcptr:

  logical, that indicates whether foreign objects refer to functions
  (`FALSE`, default) or to function pointer variables (`TRUE` rarely
  needed).

- variadic:

  logical, that indicates whether wrappers should call C variadic
  functions using
  [`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
  Cannot be combined with `funcptr = TRUE`.

- x:

  S3 `dynbind.report` object to print.

- ...:

  additional arguments to be passed to
  [`base::print()`](https://rdrr.io/r/base/print.html) methods.

## Value

The function returns a list with two fields:

- libhandle:

  External pointer returned by
  [`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md).

- unresolved.symbols:

  vector of character strings, the names of unresolved symbols.

As a side effect, for each wrapper, `dynbind()` assigns the
`function-name` to the corresponding call wrapper function in the
environment given by `envir`.

If no shared library is found, an error is reported.

## Details

`dynbind()` makes a set of C functions available to R through
installation of thin call wrappers. The set of functions, including the
symbolic name and function type, is specified by `signature`; a
character string that encodes a library signature:

The **library signature** is a compact plain-text format to specify a
set of function bindings. It consists of function names and
corresponding [call
signature](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).
Function bindings are separated by ";" (semicolon); white spaces
(including tab and new line) are allowed before and after semicolon.

    function-name ( call-signature ; ...

Here is an example that specifies three function bindings to the OpenGL
library:

    `"glAccum(If)v ; glClear(I)v ; glClearColor(ffff)v ;"`

Symbolic names are resolved using the library specified by `libnames`.
Character short library names are loaded using
[`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md),
character paths are loaded directly using
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md),
and external pointer handles returned by
[`dynload()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
or
[`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
are used as-is. For each function, a thin call wrapper function is
created using the following template:

    function(...) .dyncall.<MODE> ( <TARGET>, <SIGNATURE>, ... )

`<MODE>` is replaced by `callmode` argument, see
[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for details on calling conventions. `<TARGET>` is replaced by the
external pointer, resolved by the `function-name`. `<SIGNATURE>` is
replaced by the call signature string contained in `signature`.

The call wrapper is installed in the environment given by `envir`. The
assignment name is obtained from the function signature. If `pattern`
and `replace` is given, a text replacement is applied to the name before
assignment, useful for basic C name space mangling such as exchanging
the prefix.

As a special case, `dynbind()` supports binding of pointer-to-function
variables, indicated by setting `funcptr` to `TRUE`, in which case
`<TARGET>` is replaced with the expression `unpack(<TARGET>,"p",0)` in
order to dereference `<TARGET>` as a pointer-to-function variable at
call-time.

`variadic = TRUE` creates wrappers for C functions declared with `...`.
Generated wrappers accept normal call arguments through `...` and a
named `.varargs` argument that describes the run-time vararg signature
passed to
[`dyncall_variadic()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md).

## See also

[`dyncall()`](https://hongyuanjia.github.io/rdyncall/reference/dyncall.md)
for details on call signatures and calling conventions,
[`dynfind()`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
for details on short library names,
[`unpack()`](https://hongyuanjia.github.io/rdyncall/reference/packing.md)
for details on reading low-level memory (e.g. dereferencing of
(function) pointer variables).

## Examples

``` r
# \donttest{
info <- dynbind("R", "R_ShowMessage(Z)v; R_rsort(pi)v;")
R_ShowMessage("hello")
#> NULL
# }
```
