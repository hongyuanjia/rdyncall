#' Title: rdyncall SDL3 minimal window
#' Rows: 32
#' Cols: 88
#' End_wait: 20
#' Timeout: 30

library(rdyncall)

dynport(SDL3, package = "SDL3", rebuild = TRUE, quiet = FALSE)

seconds <- as.numeric(Sys.getenv("RDYNCALL_RECORD_SDL3_SECONDS", "2"))
if (!is.finite(seconds) || seconds <= 0) {
    seconds <- 2
}

window <- NULL
renderer <- NULL
on.exit({
    if (!is.null(renderer) && !is.nullptr(renderer)) {
        SDL3::SDL_DestroyRenderer(renderer)
    }
    if (!is.null(window) && !is.nullptr(window)) {
        SDL3::SDL_DestroyWindow(window)
    }
    SDL3::SDL_Quit()
}, add = TRUE)

if (!SDL3::SDL_Init(SDL3::SDL_INIT_VIDEO)) {
    stop("SDL_Init failed: ", SDL3::SDL_GetError(), call. = FALSE)
}

window <- SDL3::SDL_CreateWindow(
    "rdyncall SDL3 minimal window",
    640L,
    360L,
    0
)
if (is.null(window) || is.nullptr(window)) {
    stop("SDL_CreateWindow failed: ", SDL3::SDL_GetError(), call. = FALSE)
}

renderer <- SDL3::SDL_CreateRenderer(window, "software")
if (is.null(renderer) || is.nullptr(renderer)) {
    stop("SDL_CreateRenderer failed: ", SDL3::SDL_GetError(), call. = FALSE)
}

SDL3::SDL_ShowWindow(window)
SDL3::SDL_RaiseWindow(window)

stopifnot(SDL3::SDL_SetRenderDrawColor(renderer, 24L, 28L, 36L, 255L))
stopifnot(SDL3::SDL_RenderClear(renderer))
stopifnot(SDL3::SDL_SetRenderDrawColor(renderer, 255L, 255L, 255L, 255L))
stopifnot(SDL3::SDL_RenderDebugText(renderer, 40, 40, "Hello from rdyncall!"))
stopifnot(SDL3::SDL_RenderPresent(renderer))

cat("SDL3 window created with text through SDL3::.\n")

until <- Sys.time() + seconds
while (Sys.time() < until) {
    SDL3::SDL_PumpEvents()
    SDL3::SDL_Delay(16L)
}
