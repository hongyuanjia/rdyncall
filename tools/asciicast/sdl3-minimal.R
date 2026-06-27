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
event <- cdata(SDL3::SDL_Event)

duration <- as.numeric(Sys.getenv("RDYNCALL_RECORD_SDL3_SECONDS", "3"))
started <- proc.time()[["elapsed"]]
done <- FALSE

while (!done && proc.time()[["elapsed"]] - started < duration) {
    while (isTRUE(SDL3::SDL_PollEvent(event))) {
        if (event$type %in% c(SDL3::SDL_EVENT_QUIT, SDL3::SDL_EVENT_WINDOW_CLOSE_REQUESTED)) {
            done <- TRUE
        }
    }

    now <- proc.time()[["elapsed"]] - started
    x <- 40 + 320 * (0.5 + 0.5 * sin(now * 2.5))
    y <- 150 + 50 * sin(now * 4)

    SDL3::SDL_SetRenderDrawColor(renderer, 24L, 28L, 36L, 255L)
    SDL3::SDL_RenderClear(renderer)
    SDL3::SDL_SetRenderDrawColor(renderer, 255L, 255L, 255L, 255L)
    SDL3::SDL_RenderDebugText(renderer, x, y, "Hello from rdyncall!")
    SDL3::SDL_RenderPresent(renderer)
    SDL3::SDL_Delay(16L)
}

SDL3::SDL_DestroyRenderer(renderer)
SDL3::SDL_DestroyWindow(window)
SDL3::SDL_Quit()
