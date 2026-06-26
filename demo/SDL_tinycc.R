# Package: rdyncall
# File: demo/SDL_tinycc.R
# Description: SDL3 Snake demo with rdyncall-managed SDL symbols and an
#              Rtinycc-compiled game/render kernel.

library(rdyncall)
source(system.file("demo-support", "sdl3.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

is_truthy_env <- function(name, default = "false") {
    value <- tolower(Sys.getenv(name, default))
    value %in% c("1", "true", "yes", "on")
}

numeric_env <- function(name, default) {
    value <- as.numeric(Sys.getenv(name, as.character(default)))
    if (!is.finite(value) || value <= 0) {
        default
    } else {
        value
    }
}

demo_duration <- function() {
    fallback <- Sys.getenv("SDL_SNAKE_DEMO_SECONDS", "20")
    value <- Sys.getenv("SDL_TINYCC_DEMO_SECONDS", fallback)
    duration <- as.numeric(value)
    if (!is.finite(duration) || duration <= 0) {
        20
    } else {
        duration
    }
}

demo_target_fps <- function() {
    fps <- numeric_env("SDL_TINYCC_DEMO_FPS", 60)
    if (fps < 1) {
        60
    } else {
        fps
    }
}

snake_kernel_source <- function() {
    paste(
        "#define GRID_W 24",
        "#define GRID_H 18",
        "#define BLOCK 24",
        "#define MAX_CELLS (GRID_W * GRID_H)",
        "#define STEP_SECONDS 0.12",
        "#define DEFAULT_SEED 0x5eed1234u",
        "#define TEXT_CAP 64",
        "#define SCANCODE_R 21",
        "#define SCANCODE_ESCAPE 41",
        "#define SCANCODE_RIGHT 79",
        "#define SCANCODE_LEFT 80",
        "#define SCANCODE_DOWN 81",
        "#define SCANCODE_UP 82",
        "",
        "typedef struct SDL_Renderer SDL_Renderer;",
        "typedef struct SDL_FRect { float x; float y; float w; float h; } SDL_FRect;",
        "typedef bool (*SDL_SetRenderDrawColor_fn)(SDL_Renderer *, uint8_t, uint8_t, uint8_t, uint8_t);",
        "typedef bool (*SDL_RenderClear_fn)(SDL_Renderer *);",
        "typedef bool (*SDL_RenderFillRects_fn)(SDL_Renderer *, const SDL_FRect *, int);",
        "typedef bool (*SDL_RenderDebugText_fn)(SDL_Renderer *, float, float, const char *);",
        "typedef bool (*SDL_RenderPresent_fn)(SDL_Renderer *);",
        "",
        "typedef struct SnakeState {",
        "    int snake_x[MAX_CELLS];",
        "    int snake_y[MAX_CELLS];",
        "    int length;",
        "    int dir_x;",
        "    int dir_y;",
        "    int pending_x;",
        "    int pending_y;",
        "    int food_x;",
        "    int food_y;",
        "    int score;",
        "    double last_step;",
        "    uint32_t rng_state;",
        "    int initialized;",
        "} SnakeState;",
        "",
        "static SnakeState g;",
        "",
        "static uint32_t next_rand(void) {",
        "    g.rng_state = g.rng_state * 1664525u + 1013904223u;",
        "    return g.rng_state;",
        "}",
        "",
        "static int occupied(int x, int y) {",
        "    int i;",
        "    for (i = 0; i < g.length; ++i) {",
        "        if (g.snake_x[i] == x && g.snake_y[i] == y) {",
        "            return 1;",
        "        }",
        "    }",
        "    return 0;",
        "}",
        "",
        "static void spawn_food(void) {",
        "    int free_count = GRID_W * GRID_H - g.length;",
        "    int target;",
        "    int seen = 0;",
        "    int x;",
        "    int y;",
        "",
        "    if (free_count <= 0) {",
        "        g.food_x = 1;",
        "        g.food_y = 1;",
        "        return;",
        "    }",
        "",
        "    target = (int)(next_rand() % (uint32_t)free_count);",
        "    for (y = 1; y <= GRID_H; ++y) {",
        "        for (x = 1; x <= GRID_W; ++x) {",
        "            if (!occupied(x, y)) {",
        "                if (seen == target) {",
        "                    g.food_x = x;",
        "                    g.food_y = y;",
        "                    return;",
        "                }",
        "                ++seen;",
        "            }",
        "        }",
        "    }",
        "",
        "    g.food_x = GRID_W;",
        "    g.food_y = GRID_H;",
        "}",
        "",
        "int32_t snake_reset(int32_t seed) {",
        "    int mid_y = GRID_H / 2;",
        "    uint32_t use_seed = (uint32_t)seed;",
        "    if (use_seed == 0u) {",
        "        use_seed = DEFAULT_SEED;",
        "    }",
        "",
        "    g.rng_state = use_seed;",
        "    g.length = 4;",
        "    g.snake_x[0] = 8;",
        "    g.snake_y[0] = mid_y;",
        "    g.snake_x[1] = 7;",
        "    g.snake_y[1] = mid_y;",
        "    g.snake_x[2] = 6;",
        "    g.snake_y[2] = mid_y;",
        "    g.snake_x[3] = 5;",
        "    g.snake_y[3] = mid_y;",
        "    g.dir_x = 1;",
        "    g.dir_y = 0;",
        "    g.pending_x = 1;",
        "    g.pending_y = 0;",
        "    g.score = 0;",
        "    g.last_step = 0.0;",
        "    g.initialized = 1;",
        "    spawn_food();",
        "    return g.length;",
        "}",
        "",
        "static void ensure_initialized(void) {",
        "    if (!g.initialized) {",
        "        snake_reset((int32_t)DEFAULT_SEED);",
        "    }",
        "}",
        "",
        "static void reset_from_current(double now) {",
        "    uint32_t seed = next_rand() ^ (uint32_t)(now * 1000.0);",
        "    if (seed == 0u) {",
        "        seed = DEFAULT_SEED;",
        "    }",
        "    snake_reset((int32_t)seed);",
        "    g.last_step = now;",
        "}",
        "",
        "static void try_set_pending(int dx, int dy) {",
        "    if (dx == -g.dir_x && dy == -g.dir_y) {",
        "        return;",
        "    }",
        "    g.pending_x = dx;",
        "    g.pending_y = dy;",
        "}",
        "",
        "static void step_game(double now) {",
        "    int next_x;",
        "    int next_y;",
        "    int ate;",
        "    int i;",
        "    int move_limit;",
        "",
        "    g.dir_x = g.pending_x;",
        "    g.dir_y = g.pending_y;",
        "    next_x = g.snake_x[0] + g.dir_x;",
        "    next_y = g.snake_y[0] + g.dir_y;",
        "",
        "    if (next_x < 1 || next_x > GRID_W || next_y < 1 || next_y > GRID_H || occupied(next_x, next_y)) {",
        "        reset_from_current(now);",
        "        return;",
        "    }",
        "",
        "    ate = (next_x == g.food_x && next_y == g.food_y);",
        "    move_limit = g.length;",
        "    if (move_limit >= MAX_CELLS) {",
        "        move_limit = MAX_CELLS - 1;",
        "    }",
        "    for (i = move_limit; i > 0; --i) {",
        "        g.snake_x[i] = g.snake_x[i - 1];",
        "        g.snake_y[i] = g.snake_y[i - 1];",
        "    }",
        "    g.snake_x[0] = next_x;",
        "    g.snake_y[0] = next_y;",
        "",
        "    if (ate) {",
        "        if (g.length < MAX_CELLS) {",
        "            ++g.length;",
        "        }",
        "        ++g.score;",
        "        spawn_food();",
        "    }",
        "}",
        "",
        "static int key_pressed(const uint8_t *keys, int scancode) {",
        "    return keys != 0 && keys[scancode] != 0;",
        "}",
        "",
        "static void set_cell_rect(SDL_FRect *rect, int x, int y) {",
        "    rect->x = (float)((x - 1) * BLOCK + 1);",
        "    rect->y = (float)((y - 1) * BLOCK + 1);",
        "    rect->w = (float)(BLOCK - 2);",
        "    rect->h = (float)(BLOCK - 2);",
        "}",
        "",
        "static int append_literal(char *text, int pos, const char *src) {",
        "    while (*src && pos < TEXT_CAP - 1) {",
        "        text[pos++] = *src++;",
        "    }",
        "    text[pos] = '\\0';",
        "    return pos;",
        "}",
        "",
        "static int append_int(char *text, int pos, int value) {",
        "    char tmp[16];",
        "    int n = 0;",
        "    int i;",
        "    if (value < 0 && pos < TEXT_CAP - 1) {",
        "        text[pos++] = '-';",
        "        value = -value;",
        "    }",
        "    if (value == 0) {",
        "        if (pos < TEXT_CAP - 1) {",
        "            text[pos++] = '0';",
        "        }",
        "        text[pos] = '\\0';",
        "        return pos;",
        "    }",
        "    while (value > 0 && n < (int)sizeof(tmp)) {",
        "        tmp[n++] = (char)('0' + (value % 10));",
        "        value /= 10;",
        "    }",
        "    for (i = n - 1; i >= 0 && pos < TEXT_CAP - 1; --i) {",
        "        text[pos++] = tmp[i];",
        "    }",
        "    text[pos] = '\\0';",
        "    return pos;",
        "}",
        "",
        "static void render_frame(",
        "    SDL_Renderer *renderer,",
        "    SDL_SetRenderDrawColor_fn set_color,",
        "    SDL_RenderClear_fn clear,",
        "    SDL_RenderFillRects_fn fill_rects,",
        "    SDL_RenderDebugText_fn debug_text,",
        "    SDL_RenderPresent_fn present,",
        "    double fps",
        ") {",
        "    SDL_FRect food_rect;",
        "    SDL_FRect head_rect;",
        "    SDL_FRect body_rects[MAX_CELLS];",
        "    char text[TEXT_CAP];",
        "    int body_count = 0;",
        "    int pos = 0;",
        "    int i;",
        "",
        "    set_color(renderer, 10u, 12u, 16u, 255u);",
        "    clear(renderer);",
        "",
        "    set_cell_rect(&food_rect, g.food_x, g.food_y);",
        "    set_color(renderer, 230u, 57u, 70u, 255u);",
        "    fill_rects(renderer, &food_rect, 1);",
        "",
        "    if (g.length > 0) {",
        "        set_cell_rect(&head_rect, g.snake_x[0], g.snake_y[0]);",
        "        set_color(renderer, 255u, 221u, 87u, 255u);",
        "        fill_rects(renderer, &head_rect, 1);",
        "    }",
        "",
        "    for (i = 1; i < g.length; ++i) {",
        "        set_cell_rect(&body_rects[body_count++], g.snake_x[i], g.snake_y[i]);",
        "    }",
        "    if (body_count > 0) {",
        "        set_color(renderer, 42u, 157u, 143u, 255u);",
        "        fill_rects(renderer, body_rects, body_count);",
        "    }",
        "",
        "    pos = append_literal(text, pos, \"FPS \");",
        "    pos = append_int(text, pos, (int)(fps + 0.5));",
        "    pos = append_literal(text, pos, \"  Score \");",
        "    append_int(text, pos, g.score);",
        "    set_color(renderer, 255u, 255u, 255u, 255u);",
        "    debug_text(renderer, 8.0f, 8.0f, text);",
        "    present(renderer);",
        "}",
        "",
        "int32_t snake_frame(",
        "    void *renderer_ptr,",
        "    void *keys_ptr,",
        "    void *fn_set_color_ptr,",
        "    void *fn_clear_ptr,",
        "    void *fn_fill_rects_ptr,",
        "    void *fn_debug_text_ptr,",
        "    void *fn_present_ptr,",
        "    double now,",
        "    double fps",
        ") {",
        "    SDL_Renderer *renderer = (SDL_Renderer *)renderer_ptr;",
        "    const uint8_t *keys = (const uint8_t *)keys_ptr;",
        "    SDL_SetRenderDrawColor_fn set_color = (SDL_SetRenderDrawColor_fn)fn_set_color_ptr;",
        "    SDL_RenderClear_fn clear = (SDL_RenderClear_fn)fn_clear_ptr;",
        "    SDL_RenderFillRects_fn fill_rects = (SDL_RenderFillRects_fn)fn_fill_rects_ptr;",
        "    SDL_RenderDebugText_fn debug_text = (SDL_RenderDebugText_fn)fn_debug_text_ptr;",
        "    SDL_RenderPresent_fn present = (SDL_RenderPresent_fn)fn_present_ptr;",
        "",
        "    ensure_initialized();",
        "    if (renderer == 0 || set_color == 0 || clear == 0 || fill_rects == 0 || debug_text == 0 || present == 0) {",
        "        return 1;",
        "    }",
        "    if (key_pressed(keys, SCANCODE_ESCAPE)) {",
        "        return 1;",
        "    }",
        "    if (key_pressed(keys, SCANCODE_R)) {",
        "        reset_from_current(now);",
        "    }",
        "",
        "    if (key_pressed(keys, SCANCODE_RIGHT)) {",
        "        try_set_pending(1, 0);",
        "    } else if (key_pressed(keys, SCANCODE_LEFT)) {",
        "        try_set_pending(-1, 0);",
        "    } else if (key_pressed(keys, SCANCODE_UP)) {",
        "        try_set_pending(0, -1);",
        "    } else if (key_pressed(keys, SCANCODE_DOWN)) {",
        "        try_set_pending(0, 1);",
        "    }",
        "",
        "    if (g.last_step <= 0.0) {",
        "        g.last_step = now;",
        "    }",
        "    if (now - g.last_step >= STEP_SECONDS) {",
        "        step_game(now);",
        "        g.last_step = now;",
        "    }",
        "",
        "    render_frame(renderer, set_color, clear, fill_rects, debug_text, present, fps);",
        "    return 0;",
        "}",
        sep = "\n"
    )
}

compile_snake_kernel <- function(verbose = is_truthy_env("SDL_TINYCC_DEMO_VERBOSE")) {
    rtinycc <- asNamespace("Rtinycc")
    required <- c("tcc_ffi", "tcc_source", "tcc_bind", "tcc_compile")
    missing <- required[!vapply(required, exists, logical(1), envir = rtinycc, inherits = FALSE)]
    if (length(missing)) {
        stop("Rtinycc is missing required API: ", paste(missing, collapse = ", "), call. = FALSE)
    }

    ffi <- rtinycc$tcc_ffi()
    ffi <- rtinycc$tcc_source(ffi, snake_kernel_source())
    ffi <- rtinycc$tcc_bind(
        ffi,
        snake_reset = list(args = list("i32"), returns = "i32"),
        snake_frame = list(
            args = list(
                "ptr", "ptr", "ptr", "ptr", "ptr", "ptr", "ptr", "f64", "f64"
            ),
            returns = "i32"
        )
    )
    rtinycc$tcc_compile(ffi, verbose = verbose)
}

load_sdl3 <- function() {
    candidates <- find_sdl3()
    last_error <- NULL

    for (lib in candidates) {
        handle <- tryCatch(
            {
                if (grepl("[/\\\\]", lib) || (file.exists(lib) && !dir.exists(lib))) {
                    dynload(lib)
                } else {
                    dynfind(lib)
                }
            },
            error = function(e) {
                last_error <<- conditionMessage(e)
                NULL
            }
        )
        if (!is.null(handle)) {
            return(handle)
        }
    }

    detail <- if (!is.null(last_error)) paste0(" Last error: ", last_error) else ""
    stop(
        "Unable to load SDL3. Install SDL3, set SDL3_LIB, or set SDL3_DEMO_AUTO_DOWNLOAD=true or RDYNCALL_DEMO_AUTO_DOWNLOAD=true.",
        detail,
        call. = FALSE
    )
}

bind_sdl3 <- function(libhandle) {
    sdl <- new.env(parent = globalenv())
    info <- dynbind(
        libhandle,
        paste(
            "SDL_Init(I)B",
            "SDL_Quit()v",
            "SDL_CreateWindow(ZiiL)p",
            "SDL_CreateRenderer(pZ)p",
            "SDL_DestroyRenderer(p)v",
            "SDL_DestroyWindow(p)v",
            "SDL_GetError()Z",
            "SDL_PollEvent(p)B",
            "SDL_GetKeyboardState(p)p",
            "SDL_Delay(I)v",
            "SDL_SetWindowTitle(pZ)B",
            sep = ";"
        ),
        envir = sdl
    )
    if (length(info$unresolved.symbols)) {
        stop("unresolved SDL3 symbols: ", paste(info$unresolved.symbols, collapse = ", "), call. = FALSE)
    }
    sdl
}

resolve_sdl_render_symbols <- function(libhandle) {
    names <- c(
        "SDL_SetRenderDrawColor",
        "SDL_RenderClear",
        "SDL_RenderFillRects",
        "SDL_RenderDebugText",
        "SDL_RenderPresent"
    )
    symbols <- lapply(names, function(name) dynsym(libhandle, name))
    missing <- names[vapply(symbols, is.null, logical(1))]
    if (length(missing)) {
        stop("unresolved SDL3 render symbols: ", paste(missing, collapse = ", "), call. = FALSE)
    }
    names(symbols) <- names
    symbols
}

run_sdl_window <- function(kernel) {
    libhandle <- load_sdl3()
    sdl <- bind_sdl3(libhandle)
    render_symbols <- resolve_sdl_render_symbols(libhandle)

    grid_w <- 24L
    grid_h <- 18L
    block <- 24L
    width <- grid_w * block
    height <- grid_h * block
    SDL_INIT_VIDEO <- 0x00000020L
    SDL_EVENT_QUIT <- 0x100L

    sdl_initialized <- FALSE
    window <- NULL
    renderer <- NULL
    on.exit(
        {
            if (!is.null(renderer) && !is.nullptr(renderer)) {
                try(sdl$SDL_DestroyRenderer(renderer), silent = TRUE)
            }
            if (!is.null(window) && !is.nullptr(window)) {
                try(sdl$SDL_DestroyWindow(window), silent = TRUE)
            }
            if (sdl_initialized) {
                try(sdl$SDL_Quit(), silent = TRUE)
            }
        },
        add = TRUE
    )

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    sdl_initialized <- TRUE

    window <- sdl$SDL_CreateWindow("rdyncall + Rtinycc SDL3 Snake", width, height, 0)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }

    renderer <- sdl$SDL_CreateRenderer(window, NULL)
    if (is.null(renderer) || is.nullptr(renderer)) {
        stop("SDL_CreateRenderer failed: ", sdl$SDL_GetError(), call. = FALSE)
    }

    seed <- as.integer(as.numeric(Sys.time()) %% .Machine$integer.max)
    kernel$snake_reset(seed)

    event <- raw(128L)
    started <- proc.time()[["elapsed"]]
    last_fps <- started
    frames <- 0L
    fps <- 0
    duration <- demo_duration()
    target_fps <- demo_target_fps()
    frame_interval <- 1 / target_fps

    cat("Use arrow keys to steer; press R to restart or Esc to exit.\n")
    repeat {
        frame_started <- proc.time()[["elapsed"]]
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }

        keys <- sdl$SDL_GetKeyboardState(NULL)
        now <- proc.time()[["elapsed"]]
        frames <- frames + 1L
        if (now - last_fps >= 0.5) {
            fps <- frames / (now - last_fps)
            frames <- 0L
            last_fps <- now
            sdl$SDL_SetWindowTitle(
                window,
                sprintf("rdyncall + Rtinycc SDL3 Snake - %.0f FPS", fps)
            )
        }

        status <- kernel$snake_frame(
            renderer,
            keys,
            render_symbols$SDL_SetRenderDrawColor,
            render_symbols$SDL_RenderClear,
            render_symbols$SDL_RenderFillRects,
            render_symbols$SDL_RenderDebugText,
            render_symbols$SDL_RenderPresent,
            now,
            fps
        )
        if (status != 0L) {
            return(invisible(TRUE))
        }

        if (now - started >= duration) {
            return(invisible(TRUE))
        }

        remaining <- frame_interval - (proc.time()[["elapsed"]] - frame_started)
        if (remaining > 0) {
            delay_ms <- as.integer(floor(remaining * 1000))
            if (delay_ms > 0L) {
                sdl$SDL_Delay(delay_ms)
            }
        }
    }
}

run_sdl_tinycc_demo <- function() {
    if (!requireNamespace("Rtinycc", quietly = TRUE)) {
        stop(
            "demo/SDL_tinycc.R requires the optional Rtinycc package.",
            call. = FALSE
        )
    }

    kernel <- compile_snake_kernel()
    run_sdl_window(kernel)
}

run_sdl_tinycc_demo()
