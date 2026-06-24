# rdyncall demos: shared library notes

The demos of the rdyncall package (see `demo(package = "rdyncall")`)
exercise direct calls, callbacks, generated DynPort packages and a few
real shared libraries.

Some demos only use the R runtime or the platform C runtime. Others
require external shared libraries to be installed and discoverable by
[`dynfind`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md).

## Current demos

|                 |                               |                                                  |
|-----------------|-------------------------------|--------------------------------------------------|
| **Demo**        | **Required external library** | **Notes**                                        |
| `sqrt`          | C math library                | Usually provided by the operating system         |
| `factorial`     | none                          | Calls an R callback through a C function pointer |
| `callbacks`     | none                          | Callback examples                                |
| `qsort`         | C runtime                     | Uses the platform `qsort()`                      |
| `stdio`         | C runtime                     | Uses platform standard I/O functions             |
| `R_ShowMessage` | R shared library              | Uses the loaded R runtime                        |
| `glpk`          | GLPK                          | Solves a small linear program                    |
| `libxml2`       | libxml2                       | Parses a small XML document                      |
| `SDL`           | SDL3                          | Opens an SDL3 window for the snake demo          |
| `SDL_audio`     | SDL3                          | Opens an SDL3 audio/window demo                  |
| `SDL_raster`    | SDL3 and OpenGL               | Opens an SDL3/OpenGL raster demo                 |
| `raylib`        | raylib                        | Opens a raylib window; can use `RAYLIB_LIB`      |

## Library discovery

Place shared libraries in a standard system location or update the
platform library search path so that
[`dynfind`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md)
can locate them. On Windows this usually means `PATH`; on Unix-like
systems it can mean the dynamic linker search path or a package-manager
library directory.

Several demos also honor explicit environment variables:

- `SDL3_LIB`: path to an SDL3 shared library.

- `OPENGL_LIB`: path to an OpenGL shared library.

- `RAYLIB_LIB`: path to a raylib shared library.

- `RDYNCALL_RAYLIB_CACHE`: cache directory used by the raylib demo when
  it downloads a release asset.

## Installation hints

Install the development/runtime package names used by your operating
system or package manager. Common examples are:

|                     |                                                                                                  |
|---------------------|--------------------------------------------------------------------------------------------------|
| **Platform**        | **Examples**                                                                                     |
| macOS with Homebrew | `brew install glpk libxml2 sdl3 raylib`                                                          |
| Debian/Ubuntu       | `apt install libglpk40 libxml2 libsdl3-0 libgl1 libglu1-mesa`                                    |
| Fedora              | `dnf install glpk libxml2 SDL3 mesa-libGL mesa-libGLU`                                           |
| Windows             | Install matching DLLs with MSYS2, Scoop, vcpkg or another package manager and put them on `PATH` |

The raylib demo can use a locally installed raylib through `RAYLIB_LIB`.
If `RAYLIB_LIB` is not set, it attempts to obtain a matching release
asset from the raylib GitHub releases and cache it locally.

## See also

[`dynfind`](https://hongyuanjia.github.io/rdyncall/reference/dynfind.md),
[`dynbind`](https://hongyuanjia.github.io/rdyncall/reference/dynbind.md),
[`dynport`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md)
