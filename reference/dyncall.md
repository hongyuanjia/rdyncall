# Foreign Function Interface with support for almost all C types

Functions to call pre-compiled code with support for most C argument and
return types.

## Usage

``` r
dyncall(address, signature, ..., callmode = "default")

dyncall_variadic(
  address,
  signature,
  varargs = "",
  ...,
  callmode = c("default", "cdecl")
)

dyncall.cdecl(address, signature, ...)

dyncall.default(address, signature, ...)

dyncall.stdcall(address, signature, ...)

dyncall.thiscall.gcc(address, signature, ...)

dyncall.thiscall.msvc(address, signature, ...)

dyncall.fastcall.gcc(address, signature, ...)

dyncall.fastcall.msvc(address, signature, ...)

dyncall.thiscall(address, signature, ...)

dyncall.fastcall(address, signature, ...)
```

## Arguments

- address:

  external pointer to foreign function.

- signature:

  character string specifying the *call signature* that describes the
  foreign function type. See details.

- ...:

  arguments to be passed to the foreign function. Arguments are
  converted from R to C values according to the *call signature*. See
  details.

- callmode:

  character string specifying the *calling convention*. This argument
  has no effect on most platforms, but on Microsoft Windows 32-Bit
  Intel/x86 platforms. See details.

- varargs:

  character string specifying the type signatures for the arguments
  passed through the C `...` portion of a variadic function. This string
  contains argument types only, without `)` and without a return type.

## Value

Functions return the received C return value converted to an R value.
See section "Call Signature" below for details.

## Details

`dyncall()` offers a flexible Foreign Function Interface (FFI) for the C
language with support for calls to arbitrary pre-compiled C function
types at run-time. Almost all C fundamental argument- and return types
are supported including extended support for pointers. No limitations is
given for arity as well. In addition, on the Microsoft Windows 32-Bit
Intel/x86 platform, it supports multiple calling conventions to
interoperate with System DLLs. Foreign C function types are specified
via plain text *type signatures*. The foreign C function type of the
target function is known to the FFI in advance, before preparation of
the foreign call via plain text *type signature* information. This has
several advantages: R arguments do not need to match exactly. Although R
lacks some fundamental C value types, they are supported via coercion at
this interface (e.g. C `float` and 64-bit integer). Arity and argument
type checks help make this interface type-safe to a certain degree and
encourage end-users to use interface from the interpreter prompt for
rapid application development.

The foreign function to be called is specified by `address`, which is an
external pointer that is obtained from
[`dynsym()`](https://hongyuanjia.github.io/rdyncall/reference/dynload.md)
or
[`getNativeSymbolInfo()`](https://rdrr.io/r/base/getNativeSymbolInfo.html).

`signature` is a character string that specifies the formal
argument-and-return types of the foreign function using a *call
signature* string. It should match the function type of the foreign
function given by `address`, otherwise this can lead to a **fatal R
process crash**.

The calling convention is specified *explicitly* via function
`dyncall()` using the `callmode` argument or *implicitly* by using
`dyncall.*` functions. See details below.

The package option `rdyncall.callvm.size` controls the byte size of the
internal dyncall CallVM argument stack. The default is `4096`. Set this
option before loading rdyncall; changing it after package load does not
resize already-created CallVM objects.

Arguments passed via `...` are converted to C according to `signature`;
see below for details.

`dyncall_variadic()` calls C functions declared with `...`. The
`signature` argument describes the fixed parameter prefix and return
type, while `varargs` describes the actual argument types passed through
`...` at this specific call site. C default promotions are the caller's
responsibility; for example, pass promoted variadic `float` values as
`double` (`"d"`).

Given that the `signature` matches the foreign function type, the FFI
provides a certain level of type-safety to users, when exposing foreign
functions via call wrappers such as done in
[`dynbind()`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md)
and
[`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md).
Several basic argument type-safety checks are done during preparation of
the foreign function call: The arity of formals and actual arguments
must match and they must be compatible as well. Otherwise, the foreign
function call is aborted with an error before risking a fatal system
crash.

## Note

The target address, calling convention and call signature **MUST** match
foreign function type, otherwise the invocation could lead to a **fatal
R process crash**.

## Type Signature

Type signatures are used by almost all other signature formats (call,
library, structure and union signature) and also by the low-level
(un)-[packing](https://hongyuanjia.github.io/rdyncall/reference/packing.md)
functions.

The following table gives a list of valid type signatures for all
supported C types.

|                         |                      |                                                                                           |                   |
|-------------------------|----------------------|-------------------------------------------------------------------------------------------|-------------------|
| **Type Signature**      | **C type**           | **Valid R argument types**                                                                | **R returntype**  |
| '`B`'                   | bool                 | raw,logical,integer,double                                                                | logical           |
| '`c`'                   | char                 | raw,logical,integer,double                                                                | integer           |
| '`C`'                   | unsigned char        | raw,logical,integer,double                                                                | integer           |
| '`s`'                   | short                | raw,logical,integer,double                                                                | integer           |
| '`S`'                   | unsigned short       | raw,logical,integer,double                                                                | integer           |
| '`i`'                   | int                  | raw,logical,integer,double                                                                | integer           |
| '`I`'                   | unsigned int         | raw,logical,integer,double                                                                | double            |
| '`j`'                   | long                 | raw,logical,integer,double                                                                | double            |
| '`J`'                   | unsigned long        | raw,logical,integer,double                                                                | double            |
| '`l`'                   | long long            | raw,logical,integer,double                                                                | double            |
| '`L`'                   | unsigned long long   | raw,logical,integer,double                                                                | double            |
| '`f`'                   | float                | raw,logical,integer,double                                                                | double            |
| '`d`'                   | double               | raw,logical,integer,double                                                                | double            |
| '`p`'                   | C pointer            | any vector,externalptr,NULL                                                               | externalptr       |
| '`Z`'                   | char\*               | character,NULL                                                                            | character or NULL |
| '`x`'                   | SEXP                 | any                                                                                       | any               |
| '`v`'                   | void                 | invalid                                                                                   | NULL              |
| '`*`' ...               | C type\* (pointer)   | any vector,externalptr,NULL                                                               | externalptr       |
| '`*<`' *typename* '`>`' | typename\* (pointer) | raw,externalptr                                                                           | externalptr       |
| '`<`' *typename* '`>`'  | typename (by value)  | raw `struct` from [`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md) | raw `struct`      |

Aggregate by-value signatures support `struct` and `union` type
information registered with
[`cstruct()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
or
[`cunion()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md).
Aggregate arguments and returns are passed through dyncall aggregate
descriptors, including nested aggregate and fixed-size array fields that
are already represented in the registered typeinfo.

The last typed pointer rows of the table above refer to *typed pointer*
signatures. If they appear as a return type signature, the external
pointer returned is a S3 `struct` object. See
[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
for details.

## Call Signature

Call Signatures are used by `dyncall()` and
[`ccallback()`](https://hongyuanjia.github.io/rdyncall/reference/callback.md)
to describe foreign C function types. The general form of a call
signature is as following:

    (argument-type)* ) return-type

The calling sequence given by the **argument types signature** is
specified in direct *left-to-right* order of the formal argument types
defined in C. The type signatures are put in sequence without any white
space in between. A closing bracket character '`)`' marks the end of
argument types, followed by a single **return type signature**.

Derived pointer types can be specified as untyped pointers via `'p'` or
via prefix `'*'` following the underlying base type (e.g. `'*d'` for
`double *`) which is more type-safe. For example, this can prevent users
from passing a `numeric` R atomic as `int*` if using `'*i'` instead of
`'p'`.

Derived pointer types to aggregate `union` or `struct` types are
supported in combination with the framework for handling foreign data
types. See
[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
for details. Once a C type is registered, the signature
`*<`*typename*`>` can be used to refer to a pointer to an aggregate C
object *type*`*`, and `<`*typename*`>` can be used to pass a raw
[`cdata()`](https://hongyuanjia.github.io/rdyncall/reference/struct.md)
aggregate object by value. If typed pointers to aggregate objects are
used as a return type and the corresponding type information exists, the
returned value can be printed and accessed symbolically.

Here are some examples of C function prototypes and corresponding call
signatures:

|                |                                      |                                       |
|----------------|--------------------------------------|---------------------------------------|
|                | **C Function Prototype**             | **Call Signature**                    |
| `double`       | `sqrt(double);`                      | `"d)d"`                               |
| `double`       | `dnorm(double,double,double,int);`   | `"dddi)d"`                            |
| `void`         | `R_isort(int*,int);`                 | `"pi)v"` or `"*ii)v"`                 |
| `void`         | `revsort(double*,int*,int);`         | `"ppi)v"` or `"*d*ii)v"`              |
| `int`          | `SDL_PollEvents(SDL_Event *);`       | `"p)i"` or `"*<SDL_Event>)i"`         |
| `SDL_Surface*` | `SDL_SetVideoMode(int,int,int,int);` | `"iiii)p"` or `"iiii)*<SDL_Surface>"` |

## Calling Convention

Calling Conventions specify *how* sub-routine calls are performed, and,
*how* arguments and results are passed, on machine-level. They differ
significantly among families of CPU Architectures as well as OS and
Compiler implementations.

On most platforms, a single `"default"` C Calling Convention is used. As
an exception, on the Microsoft Windows 32-Bit Intel/x86 platform several
calling conventions are common. Most of the C libraries still use a
`"default"` C (also known as `"cdecl"`) calling convention, but when
working with Microsoft System APIs and DLLs, the `"stdcall"` calling
convention must be used.

It follows a description of supported Win32 Calling Conventions:

- `"cdecl"`:

  Dummy alias to *default*

- `"stdcall"`:

  C functions with *stdcall* calling convention. Useful for all
  Microsoft Windows System Libraries (e.g. KERNEL32.DLL, USER32.DLL,
  OPENGL32.DLL ...). Third-party libraries usually prefer the default C
  *cdecl* calling convention.

- `"fastcall.msvc"`:

  C functions with *fastcall* calling convention compiled with Microsoft
  Visual C++ Compiler. Very rare usage.

- `"fastcall.gcc"`:

  C functions with *fastcall* calling convention compiled with GNU C
  Compiler. Very rare usage.

- `"thiscall"`:

  C++ member functions.

- `"thiscall.gcc"`:

  C++ member functions compiled with GNU C Compiler.

- `"thiscall.msvc"`:

  C++ member functions compiled with Microsoft Visual C++ Compiler.

As of the current version of this package and for practical reasons, the
`callmode` argument does not have an effect on almost all platforms,
except that if R is running on Microsoft Windows 32-Bit Intel/x86
platform, `dyncall` uses the specified calling convention. For example,
when loading OpenGL across platforms, `"stdcall"` should be used instead
of `"default"`, because on Windows, OpenGL is a System DLL. This is very
exceptional, as in most other cases, `"default"` (or `"cdecl"`, the
alias) need to be used for normal C shared libraries on Windows.

At this stage of development, support for C++ calls should be considered
experimental. Support for Fortran is planed but not yet implemented in
dyncall.

## Portability

The implementation is based on the *dyncall* library (part of the
DynCall project).

The following processor architectures are supported: X86 32- and 64-bit,
ARM v4t-v7 oabi/eabi (aapcs) and armhf including support for Thumb ISA,
PowerPC 32-bit, MIPS 32- and 64-Bit, SPARC 32- and 64-bit. The library
has been built and tested to work on various OSs: Linux, Mac OS X,
Windows 32/64-bit, BSDs, Haiku, Nexenta/Open Solaris, Solaris, Minix and
Plan9, as well as embedded platforms such as Linux/ARM (OpenMoko,
Beagleboard, Gumstix, Efika MX, Raspberry Pi), Nintendo DS (ARM), Sony
Playstation Portable (MIPS 32-bit/eabi) and iOS (ARM - armv6 mode ok,
armv7 unstable). In the context of R, dyncall has currently no support
for PowerPC 64-Bit.

## References

Adler, D. (2012) "Foreign Library Interface", *The R Journal*, **4(1)**
, 30–40, June 2012.
<https://journal.r-project.org/articles/RJ-2012-004/>

Adler, D., Philipp, T. (2008) *DynCall Project*. <https://dyncall.org>

## Examples

``` r
# \donttest{
libm <- dynfind(c("msvcrt", "m", "m.so.6"))
c_sqrt <- dynsym(libm, "sqrt")
dyncall(c_sqrt, "d)d", 144)
#> [1] 12
# }
```
