# Package: rdyncall
# File: demo/SDL.R
# Description: SDL3 Snake game demo inspired by examples/demo/01-snake.
# Reference: https://examples.libsdl.org/SDL3/demo/01-snake/

library(rdyncall)

cstruct("SDL_FRect{ffff}x y w h;")

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
            "SDL_GetKeyboardState(p)p",
            "SDL_PollEvent(p)B",
            "SDL_Delay(I)v",
            "SDL_SetWindowTitle(pZ)B",
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

SDL_INIT_VIDEO <- 0x00000020L
SDL_EVENT_QUIT <- 0x100L

SDL_SCANCODE_ESCAPE <- 41L
SDL_SCANCODE_R <- 21L
SDL_SCANCODE_RIGHT <- 79L
SDL_SCANCODE_LEFT <- 80L
SDL_SCANCODE_DOWN <- 81L
SDL_SCANCODE_UP <- 82L

run_sdl_demo <- function() {
    if (tolower(Sys.getenv("SDL_SNAKE_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")) {
        rect <- cdata(SDL_FRect)
        rect$x <- 0
        rect$y <- 0
        rect$w <- 24
        rect$h <- 24
        cat("SDL3 snake probe ok: symbols resolved and SDL_FRect constructed.\n")
        return(invisible(TRUE))
    }

    grid_w <- 24L
    grid_h <- 18L
    block <- 24L
    width <- grid_w * block
    height <- grid_h * block

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3 Snake", width, height, 0)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)

    renderer <- sdl$SDL_CreateRenderer(window, NULL)
    if (is.null(renderer) || is.nullptr(renderer)) {
        stop("SDL_CreateRenderer failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyRenderer(renderer), add = TRUE)

    make_rect <- function(x, y, w = block - 2L, h = block - 2L) {
        rect <- cdata(SDL_FRect)
        rect$x <- as.numeric(x)
        rect$y <- as.numeric(y)
        rect$w <- as.numeric(w)
        rect$h <- as.numeric(h)
        rect
    }

    set_color <- function(r, g, b, a = 255L) {
        sdl$SDL_SetRenderDrawColor(renderer, as.integer(r), as.integer(g), as.integer(b), as.integer(a))
    }

    draw_cell <- function(x, y, color) {
        do.call(set_color, as.list(color))
        rect <- make_rect((x - 1L) * block + 1L, (y - 1L) * block + 1L)
        sdl$SDL_RenderFillRect(renderer, rect)
    }

    spawn_food <- function(snake) {
        cells <- expand.grid(x = seq_len(grid_w), y = seq_len(grid_h))
        occupied <- paste(snake$x, snake$y)
        free <- cells[!paste(cells$x, cells$y) %in% occupied, , drop = FALSE]
        free[sample.int(nrow(free), 1L), , drop = FALSE]
    }

    reset_game <- function() {
        snake <- data.frame(
            x = c(8L, 7L, 6L, 5L),
            y = rep(grid_h %/% 2L, 4L)
        )
        list(
            snake = snake,
            food = spawn_food(snake),
            direction = c(1L, 0L),
            pending = c(1L, 0L),
            score = 0L
        )
    }

    pressed <- function(keys, scancode) {
        !is.null(keys) && !is.nullptr(keys) && unpack(keys, scancode, "C") != 0L
    }

    change_direction <- function(game, direction) {
        if (!identical(as.integer(direction), -as.integer(game$direction))) {
            game$pending <- direction
        }
        game
    }

    step_game <- function(game) {
        game$direction <- game$pending
        head <- game$snake[1L, , drop = FALSE]
        next_head <- data.frame(
            x = head$x + game$direction[[1L]],
            y = head$y + game$direction[[2L]]
        )

        hit_wall <- next_head$x < 1L || next_head$x > grid_w || next_head$y < 1L || next_head$y > grid_h
        hit_self <- paste(next_head$x, next_head$y) %in% paste(game$snake$x, game$snake$y)
        if (hit_wall || hit_self) {
            return(reset_game())
        }

        ate <- next_head$x == game$food$x && next_head$y == game$food$y
        game$snake <- rbind(next_head, game$snake)
        if (ate) {
            game$score <- game$score + 1L
            game$food <- spawn_food(game$snake)
        } else {
            game$snake <- game$snake[-nrow(game$snake), , drop = FALSE]
        }
        game
    }

    render_game <- function(game, fps) {
        set_color(10L, 12L, 16L)
        sdl$SDL_RenderClear(renderer)

        draw_cell(game$food$x, game$food$y, c(230L, 57L, 70L, 255L))
        for (i in seq_len(nrow(game$snake))) {
            color <- if (i == 1L) c(255L, 221L, 87L, 255L) else c(42L, 157L, 143L, 255L)
            draw_cell(game$snake$x[[i]], game$snake$y[[i]], color)
        }

        set_color(255L, 255L, 255L)
        sdl$SDL_RenderDebugText(renderer, 8, 8, sprintf("FPS %.0f  Score %d", fps, game$score))
        sdl$SDL_RenderPresent(renderer)
    }

    game <- reset_game()
    event <- raw(128L)
    last_step <- proc.time()[["elapsed"]]
    started <- last_step
    last_fps <- last_step
    frames <- 0L
    fps <- 0
    duration <- as.numeric(Sys.getenv("SDL_SNAKE_DEMO_SECONDS", "20"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 20
    }

    cat("Use arrow keys to steer; press R to restart or Esc to exit.\n")
    repeat {
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }

        keys <- sdl$SDL_GetKeyboardState(NULL)
        if (pressed(keys, SDL_SCANCODE_ESCAPE)) {
            return(invisible(TRUE))
        }
        if (pressed(keys, SDL_SCANCODE_R)) {
            game <- reset_game()
        }
        if (pressed(keys, SDL_SCANCODE_RIGHT)) {
            game <- change_direction(game, c(1L, 0L))
        } else if (pressed(keys, SDL_SCANCODE_LEFT)) {
            game <- change_direction(game, c(-1L, 0L))
        } else if (pressed(keys, SDL_SCANCODE_UP)) {
            game <- change_direction(game, c(0L, -1L))
        } else if (pressed(keys, SDL_SCANCODE_DOWN)) {
            game <- change_direction(game, c(0L, 1L))
        }

        now <- proc.time()[["elapsed"]]
        if (now - last_step >= 0.12) {
            game <- step_game(game)
            last_step <- now
        }
        frames <- frames + 1L
        if (now - last_fps >= 0.5) {
            fps <- frames / (now - last_fps)
            frames <- 0L
            last_fps <- now
            sdl$SDL_SetWindowTitle(window, sprintf("rdyncall SDL3 Snake - %.0f FPS", fps))
        }
        render_game(game, fps)

        if (now - started >= duration) {
            return(invisible(TRUE))
        }
        sdl$SDL_Delay(16L)
    }
}

run_sdl_demo()
