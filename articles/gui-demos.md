# GUI demos

`rdyncall` can call real C GUI and graphics libraries directly from R,
including interactive SDL3 windows, audio/visual examples, OpenGL
rendering, and raylib drawing loops.

## SDL3 Snake

The SDL3 Snake demo opens a window, polls keyboard input, updates game
state in R, and renders each frame through wrappers generated from
`SDL3.dynport`.

``` r
demo("SDL", package = "rdyncall", ask = FALSE)
```

The demo generates a temporary DynPort package for SDL3, uses the
generated `SDL_FRect` aggregate type, passes a raw buffer to
`SDL_PollEvent()`, and reads keyboard state from
`SDL_GetKeyboardState()`.

## SDL3 audio

The SDL3 audio demo combines a small visual window with planar audio
buffers. It prepares low-level audio structs and feeds sample data into
an SDL3 audio stream from R.

``` r
demo("SDL_audio", package = "rdyncall", ask = FALSE)
```

This example shows how rdyncall can pass aggregate pointers, raw sample
buffers, and runtime-managed native resources through a C API that owns
audio playback.

## SDL3/OpenGL raster

The SDL3/OpenGL raster demo opens an SDL3 window with an OpenGL context
and renders a Mandelbrot raster. It is a compact example of using
rdyncall for a graphics pipeline rather than only individual scalar
function calls.

``` r
demo("SDL_raster", package = "rdyncall", ask = FALSE)
```

The raster demo exercises SDL3 window creation, OpenGL context setup,
native buffer uploads, and a timed render loop controlled from R.

## raylib recursive tree

The raylib recursive tree demo draws animated branch geometry with
raylib. The R side generates branch endpoints and passes raylib
aggregate values such as `Vector2` and `Color` by value.

``` r
demo("raylib", package = "rdyncall", ask = FALSE)
```

This demo highlights aggregate-by-value calls, generated geometry in R,
and a foreign drawing loop managed through raylib.

## raylib Rtinycc recursive tree

The raylib Rtinycc recursive tree demo keeps the same control-panel
shape but compiles the recursive tree renderer with `Rtinycc`. R owns
the window loop and slider state, while the compiled renderer calls
raylib drawing functions through function pointers resolved by rdyncall.

``` r
demo("raylib_tinycc", package = "rdyncall", ask = FALSE)
```

This variant shows how a demo can combine three layers in one loop: R
for UI state, rdyncall for native symbol binding, and Rtinycc for a
small compiled renderer that still draws through the same raylib API.

## What these demos exercise

| Demo                          | Native library           | rdyncall features                                                                                                                                   |
|:------------------------------|:-------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------------|
| SDL3 Snake                    | SDL3 renderer and events | [`dynport()`](https://hongyuanjia.github.io/rdyncall/reference/dynport.md), generated aggregate types, raw event buffer, keyboard state, event loop |
| SDL3 audio                    | SDL3 audio and renderer  | aggregate pointers, raw audio buffers, native resource cleanup                                                                                      |
| SDL3/OpenGL raster            | SDL3 and OpenGL          | shared-library discovery, OpenGL context setup, raster buffer upload, timed rendering                                                               |
| raylib recursive tree         | raylib                   | aggregate by value, generated R geometry, drawing loop, downloaded native library                                                                   |
| raylib Rtinycc recursive tree | raylib and Rtinycc       | native function pointers, aggregate by value, compiled renderer, drawing loop                                                                       |

Together, the demos show rdyncall operating at the boundary where R code
owns the application logic while C libraries own windows, renderers,
audio streams, and graphics contexts.

## Next steps

- Use [Non-GUI
  demos](https://hongyuanjia.github.io/rdyncall/articles/non-gui-demos.md)
  for examples that run directly in non-interactive sessions.
- Use [dynbind and DynPort
  bindings](https://hongyuanjia.github.io/rdyncall/articles/dynbind-dynport.md)
  to understand the wrapper layer used by the demos.
- Use [structs, unions, and
  memory](https://hongyuanjia.github.io/rdyncall/articles/structs-unions-memory.md)
  for aggregate values such as `SDL_FRect`, `Color`, and `Vector2`.
- Use [FFI safety
  boundaries](https://hongyuanjia.github.io/rdyncall/articles/ffi-safety.md)
  before adapting these patterns to APIs that store pointers, register
  callbacks, or own native resources.
