# Package: rdyncall
# File: demo/SDL_audio.R
# Description: SDL3 planar audio demo inspired by examples/audio/05-planar-data.
# Reference: https://examples.libsdl.org/SDL3/audio/05-planar-data/

library(rdyncall)

cstruct("SDL_FRect{ffff}x y w h;")
cstruct("SDL_AudioSpec{Sii}format channels freq;")
cstruct("SDL_AudioPlanes{pp}left right;")

sdl <- new.env(parent = globalenv())
sdl_info <- tryCatch(
    dynbind(
        c("SDL3", "SDL3-0", "SDL3-3"),
        paste(
            "SDL_Init(I)B",
            "SDL_Quit()v",
            "SDL_CreateWindow(ZiiL)p",
            "SDL_CreateRenderer(pZ)p",
            "SDL_DestroyRenderer(p)v",
            "SDL_DestroyWindow(p)v",
            "SDL_GetError()Z",
            "SDL_SetRenderDrawColor(pCCCC)B",
            "SDL_RenderClear(p)B",
            "SDL_RenderFillRect(p*<SDL_FRect>)B",
            "SDL_RenderDebugText(pffZ)B",
            "SDL_RenderPresent(p)B",
            "SDL_PollEvent(p)B",
            "SDL_GetMouseState(pp)I",
            "SDL_Delay(I)v",
            "SDL_OpenAudioDeviceStream(i*<SDL_AudioSpec>pp)p",
            "SDL_ResumeAudioStreamDevice(p)B",
            "SDL_DestroyAudioStream(p)v",
            "SDL_PutAudioStreamPlanarData(ppii)B",
            "SDL_FlushAudioStream(p)B",
            "SDL_GetAudioStreamQueued(p)i",
            sep = ";"
        ),
        envir = sdl
    ),
    error = function(e) {
        stop(
            conditionMessage(e),
            " Install SDL3 or make it visible through the system library search path.",
            call. = FALSE
        )
    }
)

if (length(sdl_info$unresolved.symbols)) {
    stop("unresolved SDL3 symbols: ", paste(sdl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(sdl_info)

SDL_INIT_AUDIO <- 0x00000010L
SDL_INIT_VIDEO <- 0x00000020L
SDL_EVENT_QUIT <- 0x100L
SDL_AUDIO_U8 <- 0x0008L
SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK <- -1L
SDL_BUTTON_LMASK <- 1L

run_sdl_audio_demo <- function() {
    sample_rate <- 4000L
    tone <- local({
        seconds <- 0.35
        n <- as.integer(sample_rate * seconds)
        t <- seq(0, n - 1L) / sample_rate
        as.raw(pmax(0L, pmin(255L, round(128 + 72 * sin(2 * pi * 440 * t)))))
    })

    if (tolower(Sys.getenv("SDL_AUDIO_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")) {
        planes <- cdata(SDL_AudioPlanes)
        planes$left <- tone
        planes$right <- NULL
        cat("SDL3 audio probe ok: symbols resolved and planar buffers prepared.\n")
        return(invisible(TRUE))
    }

    if (!isTRUE(sdl$SDL_Init(bitwOr(SDL_INIT_VIDEO, SDL_INIT_AUDIO)))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3 planar audio", 640L, 480L, 0)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)

    renderer <- sdl$SDL_CreateRenderer(window, NULL)
    if (is.null(renderer) || is.nullptr(renderer)) {
        stop("SDL_CreateRenderer failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyRenderer(renderer), add = TRUE)

    spec <- cdata(SDL_AudioSpec)
    spec$format <- SDL_AUDIO_U8
    spec$channels <- 2L
    spec$freq <- sample_rate

    stream <- sdl$SDL_OpenAudioDeviceStream(SDL_AUDIO_DEVICE_DEFAULT_PLAYBACK, spec, NULL, NULL)
    if (is.null(stream) || is.nullptr(stream)) {
        stop("SDL_OpenAudioDeviceStream failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyAudioStream(stream), add = TRUE)
    sdl$SDL_ResumeAudioStreamDevice(stream)

    make_rect <- function(x, y, w, h) {
        rect <- cdata(SDL_FRect)
        rect$x <- as.numeric(x)
        rect$y <- as.numeric(y)
        rect$w <- as.numeric(w)
        rect$h <- as.numeric(h)
        rect
    }

    left_button <- make_rect(100, 170, 120, 100)
    right_button <- make_rect(420, 170, 120, 100)

    set_color <- function(r, g, b, a = 255L) {
        sdl$SDL_SetRenderDrawColor(renderer, as.integer(r), as.integer(g), as.integer(b), as.integer(a))
    }

    point_in_rect <- function(x, y, rect) {
        x >= rect$x && x <= rect$x + rect$w && y >= rect$y && y <= rect$y + rect$h
    }

    play_side <- function(side) {
        planes <- cdata(SDL_AudioPlanes)
        if (identical(side, "left")) {
            planes$left <- tone
            planes$right <- NULL
        } else {
            planes$left <- NULL
            planes$right <- tone
        }
        if (!isTRUE(sdl$SDL_PutAudioStreamPlanarData(stream, planes, -1L, length(tone)))) {
            stop("SDL_PutAudioStreamPlanarData failed: ", sdl$SDL_GetError(), call. = FALSE)
        }
        sdl$SDL_FlushAudioStream(stream)
        side
    }

    render_button <- function(rect, label, active) {
        if (active) {
            set_color(45L, 170L, 80L)
        } else {
            set_color(45L, 95L, 210L)
        }
        sdl$SDL_RenderFillRect(renderer, rect)
        set_color(255L, 255L, 255L)
        sdl$SDL_RenderDebugText(renderer, rect$x + 36, rect$y + 42, label)
    }

    current <- play_side("left")
    last_mouse <- FALSE
    xbuf <- raw(4L)
    ybuf <- raw(4L)
    event <- raw(128L)
    started <- proc.time()[["elapsed"]]
    duration <- as.numeric(Sys.getenv("SDL_AUDIO_DEMO_SECONDS", "6"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 6
    }

    cat("Click the left or right button to play the tone in that channel.\n")
    repeat {
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }

        queued <- sdl$SDL_GetAudioStreamQueued(stream)
        if (queued == 0L) {
            current <- ""
        }

        mask <- sdl$SDL_GetMouseState(xbuf, ybuf)
        mouse_down <- bitwAnd(mask, SDL_BUTTON_LMASK) != 0L
        if (mouse_down && !last_mouse && queued == 0L) {
            mx <- unpack(xbuf, 0L, "f")
            my <- unpack(ybuf, 0L, "f")
            if (point_in_rect(mx, my, left_button)) {
                current <- play_side("left")
            } else if (point_in_rect(mx, my, right_button)) {
                current <- play_side("right")
            }
        }
        last_mouse <- mouse_down

        set_color(12L, 12L, 16L)
        sdl$SDL_RenderClear(renderer)
        render_button(left_button, "LEFT", identical(current, "left"))
        render_button(right_button, "RIGHT", identical(current, "right"))
        set_color(220L, 220L, 220L)
        sdl$SDL_RenderDebugText(renderer, 130, 320, "Planar Uint8 buffers: tone + NULL silence")
        sdl$SDL_RenderPresent(renderer)

        if (proc.time()[["elapsed"]] - started >= duration) {
            return(invisible(TRUE))
        }
        sdl$SDL_Delay(16L)
    }
}

run_sdl_audio_demo()
