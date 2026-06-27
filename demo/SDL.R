# Package: rdyncall
# File: demo/SDL.R
# Description: SDL3 Snake game demo inspired by examples/demo/01-snake.
# Reference: https://examples.libsdl.org/SDL3/demo/01-snake/

library(rdyncall)
source(system.file("demo-support", "sdl3.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

# Run an SDL3 snake game through wrappers generated from SDL3.dynport.
run_sdl_demo <- function() {
    # Generate dyn.SDL3 in a temporary library so this demo leaves no generated
    # package behind after it exits.
    dynport_lib <- tempfile("rdyncall-sdl3-demo-lib-")
    dir.create(dynport_lib, recursive = TRUE)
    dynport_file <- NULL
    old_libpaths <- .libPaths()
    dyn_sdl3_was_attached <- "package:dyn.SDL3" %in% search()
    dyn_sdl3_was_loaded <- "dyn.SDL3" %in% loadedNamespaces()

    sdl_initialized <- FALSE
    window <- NULL
    renderer <- NULL
    on.exit(
        {
            if (!is.null(renderer) && !is.nullptr(renderer)) {
                try(dyn.SDL3::SDL_DestroyRenderer(renderer), silent = TRUE)
            }
            if (!is.null(window) && !is.nullptr(window)) {
                try(dyn.SDL3::SDL_DestroyWindow(window), silent = TRUE)
            }
            if (sdl_initialized) {
                try(dyn.SDL3::SDL_Quit(), silent = TRUE)
            }
            if (!dyn_sdl3_was_attached && "package:dyn.SDL3" %in% search()) {
                try(
                    detach("package:dyn.SDL3", character.only = TRUE),
                    silent = TRUE
                )
            }
            if (!dyn_sdl3_was_loaded && "dyn.SDL3" %in% loadedNamespaces()) {
                try(unloadNamespace("dyn.SDL3"), silent = TRUE)
            }
            .libPaths(old_libpaths)
            if (!is.null(dynport_file)) {
                unlink(dynport_file, force = TRUE)
            }
            unlink(dynport_lib, recursive = TRUE, force = TRUE)
        },
        add = TRUE
    )

    dynport_file <- sdl3_demo_dynport()
    tryCatch(
        dynport(SDL3, portfile = dynport_file, lib = dynport_lib, rebuild = TRUE, quiet = FALSE),
        error = function(e) {
            stop(
                conditionMessage(e),
                " Install SDL3, set SDL3_LIB, or set SDL3_DEMO_AUTO_DOWNLOAD=true or RDYNCALL_DEMO_AUTO_DOWNLOAD=true.",
                call. = FALSE
            )
        }
    )

    grid_w <- 24L
    grid_h <- 18L
    block <- 24L
    width <- grid_w * block
    height <- grid_h * block
    # SDL_INIT_VIDEO is the SDL3 subsystem bit for video/window support.
    # It is an SDL preprocessor macro, so keep the numeric value local to the demo.
    SDL_INIT_VIDEO <- 0x00000020L

    # Initialize SDL and use on.exit() to keep native resources paired.
    if (!isTRUE(dyn.SDL3::SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", dyn.SDL3::SDL_GetError(), call. = FALSE)
    }
    sdl_initialized <- TRUE

    window <- dyn.SDL3::SDL_CreateWindow(
        "rdyncall SDL3 Snake",
        width,
        height,
        0
    )
    if (is.null(window) || is.nullptr(window)) {
        stop(
            "SDL_CreateWindow failed: ",
            dyn.SDL3::SDL_GetError(),
            call. = FALSE
        )
    }

    renderer <- dyn.SDL3::SDL_CreateRenderer(window, NULL)
    if (is.null(renderer) || is.nullptr(renderer)) {
        stop(
            "SDL_CreateRenderer failed: ",
            dyn.SDL3::SDL_GetError(),
            call. = FALSE
        )
    }

    # Construct an SDL_FRect value for one grid cell.
    make_rect <- function(x, y, w = block - 2L, h = block - 2L) {
        rect <- cdata(dyn.SDL3::SDL_FRect)
        rect$x <- as.numeric(x)
        rect$y <- as.numeric(y)
        rect$w <- as.numeric(w)
        rect$h <- as.numeric(h)
        rect
    }

    # Set the current renderer color. SDL expects unsigned byte RGBA channels.
    set_color <- function(r, g, b, a = 255L) {
        dyn.SDL3::SDL_SetRenderDrawColor(
            renderer,
            as.integer(r),
            as.integer(g),
            as.integer(b),
            as.integer(a)
        )
    }

    # Draw one logical snake-grid cell as a filled SDL_FRect.
    draw_cell <- function(x, y, color) {
        do.call(set_color, as.list(color))
        rect <- make_rect((x - 1L) * block + 1L, (y - 1L) * block + 1L)
        dyn.SDL3::SDL_RenderFillRect(renderer, rect)
    }

    # Pick a random empty grid cell for food.
    spawn_food <- function(snake) {
        cells <- expand.grid(x = seq_len(grid_w), y = seq_len(grid_h))
        occupied <- paste(snake$x, snake$y)
        free <- cells[!paste(cells$x, cells$y) %in% occupied, , drop = FALSE]
        free[sample.int(nrow(free), 1L), , drop = FALSE]
    }

    # Create the starting snake state.
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

    # Read one SDL keyboard state byte at a scancode offset.
    pressed <- function(keys, scancode) {
        !is.null(keys) && !is.nullptr(keys) && unpack(keys, scancode, "C") != 0L
    }

    # Queue a direction change while preventing an immediate 180-degree turn.
    change_direction <- function(game, direction) {
        if (!identical(as.integer(direction), -as.integer(game$direction))) {
            game$pending <- direction
        }
        game
    }

    # Advance the snake by one grid step, handling wall/self collision and food.
    step_game <- function(game) {
        game$direction <- game$pending
        head <- game$snake[1L, , drop = FALSE]
        next_head <- data.frame(
            x = head$x + game$direction[[1L]],
            y = head$y + game$direction[[2L]]
        )

        hit_wall <- next_head$x < 1L ||
            next_head$x > grid_w ||
            next_head$y < 1L ||
            next_head$y > grid_h
        hit_self <- paste(next_head$x, next_head$y) %in%
            paste(game$snake$x, game$snake$y)
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

    # Render one frame and show FPS/score text through SDL_RenderDebugText.
    render_game <- function(game, fps) {
        set_color(10L, 12L, 16L)
        dyn.SDL3::SDL_RenderClear(renderer)

        draw_cell(game$food$x, game$food$y, c(230L, 57L, 70L, 255L))
        for (i in seq_len(nrow(game$snake))) {
            color <- if (i == 1L) {
                c(255L, 221L, 87L, 255L)
            } else {
                c(42L, 157L, 143L, 255L)
            }
            draw_cell(game$snake$x[[i]], game$snake$y[[i]], color)
        }

        set_color(255L, 255L, 255L)
        dyn.SDL3::SDL_RenderDebugText(
            renderer,
            8,
            8,
            sprintf("FPS %.0f  Score %d", fps, game$score)
        )
        dyn.SDL3::SDL_RenderPresent(renderer)
    }

    # Main loop: poll events, read keyboard state, update game logic at a fixed
    # cadence, and render as often as the loop allows.
    game <- reset_game()
    event <- cdata(dyn.SDL3::SDL_Event)
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
        while (isTRUE(dyn.SDL3::SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == dyn.SDL3::SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }

        keys <- dyn.SDL3::SDL_GetKeyboardState(NULL)
        if (pressed(keys, dyn.SDL3::SDL_SCANCODE_ESCAPE)) {
            return(invisible(TRUE))
        }
        if (pressed(keys, dyn.SDL3::SDL_SCANCODE_R)) {
            game <- reset_game()
        }
        if (pressed(keys, dyn.SDL3::SDL_SCANCODE_RIGHT)) {
            game <- change_direction(game, c(1L, 0L))
        } else if (pressed(keys, dyn.SDL3::SDL_SCANCODE_LEFT)) {
            game <- change_direction(game, c(-1L, 0L))
        } else if (pressed(keys, dyn.SDL3::SDL_SCANCODE_UP)) {
            game <- change_direction(game, c(0L, -1L))
        } else if (pressed(keys, dyn.SDL3::SDL_SCANCODE_DOWN)) {
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
            dyn.SDL3::SDL_SetWindowTitle(
                window,
                sprintf("rdyncall SDL3 Snake - %.0f FPS", fps)
            )
        }
        render_game(game, fps)

        if (now - started >= duration) {
            return(invisible(TRUE))
        }
        dyn.SDL3::SDL_Delay(16L)
    }
}

run_sdl_demo()
