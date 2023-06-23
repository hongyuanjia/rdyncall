# rdyncall

<!-- badges: start -->
[![R-CMD-check](https://github.com/hongyuanjia/rdyncall/actions/workflows/R-CMD-
check.yaml/badge.svg)](https://github.com/hongyuanjia/rdyncall/actions/workflows/R
-CMD-check.yaml)
<!-- badges: end -->

rdyncall is the R bindings to the [DynCall](https://dyncall.org) libries for
flexible Foreign Function Interface (FFI) between R and C.

Unfortunately, the rdyncall package has been archived by CRAN since Sep. 2014
and hasn't updated since then.

This repo is an ongoing effort to make it on CRAN again. The original source
of rdyncall is hosted at [dyncall.org](https://dyncall.org/pub/dyncall/bindings/file/tip/R/rdyncall/).
Hopefully updates in this repo can be eventually merged into the upstream in the
future.

Currently, you can try rdyncall by installing it from GitHub.

```r
remotes::install_github("hongyuanjia/rdyncall")
```

**Below is the original introduction of rdyncall:**

## Short Introduction

rdyncall facilities dynamic R bindings to the C interface of some common
shared libraries and a flexible Foreign Function Interface for the
interoperability between R and C.

Since the initial presentation of the package at Use!R 2009, a number of
improvements have been done to rdyncall, the low-level DynCall libraries
and the build system for an official release on CRAN.

## Overview

The package comprises a toolkit to work with C interfaces to native code from
within the dynamic R interpreter without the need for C wrapper compilation:

  - Dynamic R bindings to some common C shared libraries, across platforms.
  - Foreign Function Interface that supports almost all C arg/return types
    and has built-in type-checking facility.
  - Portable naming and loading of shared libraries across platforms.
  - Handling of aggregate C struct and union data types.
  - Wrapping of R functions as C callbacks.
  - Binding of C functions to R in batches.

The intended audience for this package are developers experienced with C, that

  - need complete R bindings of C libraries.
  - want to write cross-platform portable system-level code in R.
  - need a FFI that supports almost all C fundamental types for arguments
  - and return types and thus does not need compilation of wrapper C code
  - want to work with C struct/union types directly in R
  - are interested in dynamic binding techniques between static and dynamic
    languages and cross-platform binding strategies.


Brief Tour 1/2: Dynamic R Bindings to C Libraries
-------------------------------------------------

The dynamic binding interface consists of a single function, similar to
'library' or 'require':

```r
dynport(portname)
```

portname refers to a 'DynPort' file name that represents an R binding to a
common C interface and library.
The function the above has the side effect of attaching a newly created R name
space, populated with thin R helper objects to C entities of the underlying
C library:

  - call wrapper to C functions
  - symbolic constants of C macros and enums,
  - type information objects for C struct and union data types.

The package contains a repository of the following DynPort files:

  | Port Name   | Description of C Shared Library/API              |
  | ------------|------------------------------------------------- |
  | expat       | Expat XML Parser Library                         |
  | GL          | OpenGL 1.1 API                                   |
  | GLU         | OpenGL Utility Library                           |
  | SDL         | Simple DirectMedia Layer library                 |
  | SDL_image   | Loading of image files (png,jpeg..)              |
  | SDL_mixer   | Loading/Playing of ogg/mp3/mod music files.      |
  | SDL_ttf     | Loading/Rendering of True Type Fonts.            |
  | glew        | OpenGL Extension Wrangler (includes OpenGL 3.0)  |
  | gl3         | strict OpenGL 3 (untested)                       |
  | R           | R shared library                                 |
  | ode         | Open Dynamics (Physics-) Engine (untested)       |
  | cuda        | NVIDIA Cuda (untested)                           |
  | opencl      | OpenCL (untested)                                |
  | stdio       | C Standard Library I/O Functions                 |

In order to use a DynPort on a host system, the shared C libraries
need to be installed first.

See manual page on 'rdyncall-demos' (type ?'rdyncall-demos') for a detailed
description of the installation notes for several libraries the above,
collected for a large range of operating-systems and OS distributions.

Since the rdyncall package is alredy ported across major R platforms, code
that uses a DynPort can run cross-platform without compilation.

Here is a small example for using the SDL and OpenGL for multimedia/3D:

```r
# load SDL and OpenGL bindings
dynport(SDL)
dynport(GL)

# initialize video sub-system
SDL_Init(SDL_INIT_VIDEO)

# open double-buffered OpenGL window surface
surface <- SDL_SetVideoMode(640,480,32,SDL_OPENGL+SDL_DOUBLEBUF)

# print dimension by accessing fields external C pointer to struct SDL_Surface
print( paste("dimenstion:", surface$w, "x", surface$h ))

# clear buffer
glClearColor(0.3,0.6,0.8,0)
glClear(GL_COLOR_BUFFER_BIT)

# update display
SDL_GL_SwapBuffers()
```

A more detailed version including user-interface handling is available
in `demo(SDL)`.

## Brief Tour 2/2: Alternative FFI via 'dyncall'

The alternative foreign function interface offered by 'dyncall' has a similar
intend such as '.C'. It allows to call shared library functions directly from R,
but without additional wrapper C code needed, because it supports almost all
fundamental C data types and uses a function type signature text specification
for type-checking and flexible conversions between R and C values.

The interface is as following:

```r
dyncall(address, signature, ...)
```

'signature' is a character string that encodes the arguments and return-type of
a C function.
Here is an example of C function from the OpenGL API:

```c
void glClearColor(float red, float green, float blue, float alpha);
```

one would specify the function type via "ffff)v" as type signature and
pass additional arguments for '...':

```r
dyncall(addressOf_glClearColor, "ffff)v", 0.3,0.7,1,0)
```

Support for pointers (low-level void and typed pointers to struct/union) and
wrapping of R functions to first-level C function pointers is also available.

```r
# load C math library across major platforms (Windows,Mac OS X,Linux)
mathlib <- dynfind(c("msvcrt","m","m.so.6"))

# resolve symbol 'sqrt'
x <- dynsym(mathlib,"sqrt")

# C function call 'double sqrt(double x)' with x=144
dyncall(x, "d)d", 144)

# dyncall uses complex mapping of types, same works with 'integer' argument:
dyncall(x, "d)d", 144L)
```

## Implementation Details

This package contains low-level services related to the generic invocation
of machine-code functions using official calling convention specifications
as the binary interface. A similar service exists for the oppositve direction
in order to write R functions and wrap them as first-level C function callback
pointers.

The implementation is based on libraries from the DynCall Project that
implement a small amount of code in Assembly and have to play closely
together with the calling conventions of various processor-architectures and
platforms.
The implementation can be tricky has to be done on a calling-convention
basis. The efforts legitimate this non-portsble approach due to a
very small code size and a generic machine-call solution designed for
dynamic interpreters. (total size of shared lib object in rdyncall is ~60kb )


## Portability and Platforms

A large set of platforms and calling conventions are already supported and a
suite of testing tools ensure a stable implementation at low-level.

Processor-Architectures:
- Intel i386 32-bit and AMD 64-bit Platforms
- PowerPC 32-bit (support for callbacks on System V systems not yet implemented)
- ARM 32-bit (with support for Thumb)
- MIPS 32- and 64-bit (support for callbacks not yet implemented)
- SPARC 32-bit and 64-bit (support for callbacks not yet implemented)

The DynCall libraries are tested on Linux, Mac OS X, Windows, BSD derivates,
Solaris and more exotic platforms such as game consoles, Plan9, Haiku and Minix.
The R Package has been tested on several major 32- and 64-bit R platforms
including Windows 32/64-bit, Linux (i386,amd64,ppc,arm), NetBSD (i386,amd64),
Solaris (i386,amd64).

As of this release, no support for callbacks is available on MIPS or SPARC.
Callbacks on PowerPC 32-bit for Mac OS X work fine, for other
ELF/System V-based PowerPC systems, callbacks are not yet implemented.


## More Information

More demos and examples are in the package.
A 20-page vignette with the title "Foreign Library Interface" is available via
`vignette("FLI")`.

A cross-platform audio/visual OpenGL-based demo-scene production
written in 100% pure R is available here:

  https://dyncall.org/demos/soulsalicious/index.html

A video of demo is also at the website.

The website of the DynCall Project is at

  https://dyncall.org/
