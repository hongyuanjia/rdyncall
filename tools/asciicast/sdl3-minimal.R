#' Title: rdyncall SDL3 minimal window
#' Rows: 30
#' Cols: 88
#' End_wait: 20
#' Timeout: 30

library(rdyncall)

dynport(SDL3, package = "SDL3", rebuild = TRUE, quiet = FALSE)
SDL3::SDL_Init(SDL3::SDL_INIT_VIDEO)

window <- SDL3::SDL_CreateWindow("rdyncall SDL3 window", 640L, 360L, 0)
renderer <- SDL3::SDL_CreateRenderer(window, "software")

SDL3::SDL_SetRenderDrawColor(renderer, 24L, 28L, 36L, 255L)
SDL3::SDL_RenderClear(renderer)
SDL3::SDL_SetRenderDrawColor(renderer, 255L, 255L, 255L, 255L)
SDL3::SDL_RenderDebugText(renderer, 40, 40, "Hello from rdyncall!")
SDL3::SDL_RenderPresent(renderer)

SDL3::SDL_Delay(as.integer(1000 * as.numeric(Sys.getenv("RDYNCALL_RECORD_SDL3_SECONDS", "2"))))
SDL3::SDL_DestroyRenderer(renderer)
SDL3::SDL_DestroyWindow(window)
SDL3::SDL_Quit()
