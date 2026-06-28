# Package: rdyncall
# File: demo/raylib_tinycc.R
# Description: raylib recursive tree demo with an Rtinycc-compiled tree renderer.
# Reference: https://github.com/raysan5/raylib/blob/master/examples/shapes/shapes_recursive_tree.c

library(rdyncall)
source(system.file("demo-support", "raylib.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

is_truthy_env <- function(name, default = "false") {
    value <- tolower(Sys.getenv(name, default))
    value %in% c("1", "true", "yes", "on")
}

demo_duration <- function() {
    fallback <- Sys.getenv("RAYLIB_DEMO_SECONDS", unset = "")
    value <- Sys.getenv("RAYLIB_TINYCC_DEMO_SECONDS", fallback)
    if (!nzchar(value)) {
        return(Inf)
    }
    duration <- as.numeric(value)
    if (!is.finite(duration) || duration <= 0) {
        Inf
    } else {
        duration
    }
}

demo_target_fps <- function() {
    fps <- as.numeric(Sys.getenv("RAYLIB_TINYCC_DEMO_FPS", "60"))
    if (!is.finite(fps) || fps <= 0) {
        60L
    } else {
        as.integer(round(fps))
    }
}

# raylib aggregate types used by value in R-side calls.
cstruct("Color{CCCC}r g b a;")
cstruct("Vector2{ff}x y;")

color <- function(r, g, b, a = 255L) {
    x <- cdata(Color)
    x$r <- as.integer(r)
    x$g <- as.integer(g)
    x$b <- as.integer(b)
    x$a <- as.integer(a)
    x
}

raylib_kernel_source <- function() {
    paste(
        "#define TREE_CAPACITY 1030",
        "#define PI 3.14159265358979323846",
        "",
        "typedef struct Color { uint8_t r; uint8_t g; uint8_t b; uint8_t a; } Color;",
        "typedef struct Vector2 { float x; float y; } Vector2;",
        "typedef void (*ClearBackground_fn)(Color);",
        "typedef void (*DrawLine_fn)(int, int, int, int, Color);",
        "typedef void (*DrawLineEx_fn)(Vector2, Vector2, float, Color);",
        "typedef void (*DrawLineBezier_fn)(Vector2, Vector2, float, Color);",
        "",
        "static double starts_x[TREE_CAPACITY];",
        "static double starts_y[TREE_CAPACITY];",
        "static double ends_x[TREE_CAPACITY];",
        "static double ends_y[TREE_CAPACITY];",
        "static double angles[TREE_CAPACITY];",
        "static double lengths[TREE_CAPACITY];",
        "",
        "static Color make_color(int r, int g, int b, int a) {",
        "    Color c;",
        "    c.r = (uint8_t)r;",
        "    c.g = (uint8_t)g;",
        "    c.b = (uint8_t)b;",
        "    c.a = (uint8_t)a;",
        "    return c;",
        "}",
        "",
        "static Vector2 make_vector2(double x, double y) {",
        "    Vector2 v;",
        "    v.x = (float)x;",
        "    v.y = (float)y;",
        "    return v;",
        "}",
        "",
        "static int round_to_int(double x) {",
        "    if (x >= 0.0) {",
        "        return (int)(x + 0.5);",
        "    }",
        "    return (int)(x - 0.5);",
        "}",
        "",
        "static int max_branch_count(double depth) {",
        "    int d = (int)floor(depth);",
        "    int max_branches;",
        "    if (d < 1) {",
        "        d = 1;",
        "    }",
        "    if (d > 10) {",
        "        d = 10;",
        "    }",
        "    max_branches = 1 << d;",
        "    if (max_branches > TREE_CAPACITY - 1) {",
        "        max_branches = TREE_CAPACITY - 1;",
        "    }",
        "    return max_branches;",
        "}",
        "",
        "static int build_tree(double angle_degrees, double depth, double branch_length, double decay) {",
        "    double theta = angle_degrees * PI / 180.0;",
        "    int max_branches = max_branch_count(depth);",
        "    int count = 1;",
        "    int i = 0;",
        "",
        "    if (branch_length < 1.0) {",
        "        branch_length = 1.0;",
        "    }",
        "    if (decay < 0.01) {",
        "        decay = 0.01;",
        "    }",
        "",
        "    starts_x[0] = 275.0;",
        "    starts_y[0] = 450.0;",
        "    ends_x[0] = starts_x[0];",
        "    ends_y[0] = starts_y[0] - branch_length;",
        "    angles[0] = 0.0;",
        "    lengths[0] = branch_length;",
        "",
        "    while (i < count && count < max_branches) {",
        "        double next_length = lengths[i] * decay;",
        "        if (lengths[i] >= 2.0 && next_length >= 2.0) {",
        "            int child;",
        "            for (child = 0; child < 2 && count < TREE_CAPACITY && count < max_branches; ++child) {",
        "                double delta = child == 0 ? theta : -theta;",
        "                double a = angles[i] + delta;",
        "                starts_x[count] = ends_x[i];",
        "                starts_y[count] = ends_y[i];",
        "                ends_x[count] = ends_x[i] + next_length * sin(a);",
        "                ends_y[count] = ends_y[i] - next_length * cos(a);",
        "                angles[count] = a;",
        "                lengths[count] = next_length;",
        "                ++count;",
        "            }",
        "        }",
        "        ++i;",
        "    }",
        "",
        "    return count;",
        "}",
        "",
        "int32_t ray_tree_render(",
        "    void *fn_clear_ptr,",
        "    void *fn_line_ptr,",
        "    void *fn_line_ex_ptr,",
        "    void *fn_line_bezier_ptr,",
        "    double angle_degrees,",
        "    double depth,",
        "    double branch_length,",
        "    double decay,",
        "    double thick,",
        "    int32_t use_bezier",
        ") {",
        "    ClearBackground_fn clear_background = (ClearBackground_fn)fn_clear_ptr;",
        "    DrawLine_fn draw_line = (DrawLine_fn)fn_line_ptr;",
        "    DrawLineEx_fn draw_line_ex = (DrawLineEx_fn)fn_line_ex_ptr;",
        "    DrawLineBezier_fn draw_line_bezier = (DrawLineBezier_fn)fn_line_bezier_ptr;",
        "    Color background = make_color(245, 245, 245, 255);",
        "    Color branch_color = make_color(230, 41, 55, 255);",
        "    int count;",
        "    int plain_line;",
        "    int drawn = 0;",
        "    int i;",
        "",
        "    if (clear_background == 0 || draw_line == 0 || draw_line_ex == 0 || draw_line_bezier == 0) {",
        "        return -1;",
        "    }",
        "",
        "    count = build_tree(angle_degrees, depth, branch_length, decay);",
        "    plain_line = (!use_bezier && thick <= 1.05);",
        "    clear_background(background);",
        "",
        "    for (i = 0; i < count; ++i) {",
        "        if (lengths[i] >= 2.0) {",
        "            if (plain_line) {",
        "                draw_line(",
        "                    round_to_int(starts_x[i]),",
        "                    round_to_int(starts_y[i]),",
        "                    round_to_int(ends_x[i]),",
        "                    round_to_int(ends_y[i]),",
        "                    branch_color",
        "                );",
        "            } else if (use_bezier) {",
        "                draw_line_bezier(",
        "                    make_vector2(starts_x[i], starts_y[i]),",
        "                    make_vector2(ends_x[i], ends_y[i]),",
        "                    (float)thick,",
        "                    branch_color",
        "                );",
        "            } else {",
        "                draw_line_ex(",
        "                    make_vector2(starts_x[i], starts_y[i]),",
        "                    make_vector2(ends_x[i], ends_y[i]),",
        "                    (float)thick,",
        "                    branch_color",
        "                );",
        "            }",
        "            ++drawn;",
        "        }",
        "    }",
        "",
        "    return drawn;",
        "}",
        sep = "\n"
    )
}

compile_raylib_kernel <- function(
    verbose = is_truthy_env("RAYLIB_TINYCC_DEMO_VERBOSE")
) {
    rtinycc <- asNamespace("Rtinycc")
    required <- c("tcc_ffi", "tcc_source", "tcc_bind", "tcc_compile")
    missing <- required[
        !vapply(required, exists, logical(1), envir = rtinycc, inherits = FALSE)
    ]
    if (length(missing)) {
        stop(
            "Rtinycc is missing required API: ",
            paste(missing, collapse = ", "),
            call. = FALSE
        )
    }

    ffi <- rtinycc$tcc_ffi()
    ffi <- rtinycc$tcc_source(ffi, raylib_kernel_source())
    ffi <- rtinycc$tcc_bind(
        ffi,
        ray_tree_render = list(
            args = list(
                "ptr",
                "ptr",
                "ptr",
                "ptr",
                "f64",
                "f64",
                "f64",
                "f64",
                "f64",
                "i32"
            ),
            returns = "i32"
        )
    )
    rtinycc$tcc_compile(ffi, verbose = verbose)
}

resolve_raylib_symbols <- function(libhandle) {
    names <- c("ClearBackground", "DrawLine", "DrawLineEx", "DrawLineBezier")
    symbols <- lapply(names, function(name) dynsym(libhandle, name))
    missing <- names[vapply(symbols, is.null, logical(1))]
    if (length(missing)) {
        stop(
            "unresolved raylib render symbols: ",
            paste(missing, collapse = ", "),
            call. = FALSE
        )
    }
    names(symbols) <- names
    symbols
}

clamp <- function(x, lower, upper) {
    pmax(lower, pmin(upper, x))
}

slider_bar <- function(
    ray,
    label,
    value,
    min,
    max,
    x,
    y,
    width,
    height,
    mouse_x,
    mouse_y,
    mouse_down,
    colors,
    digits = 0L,
    draw = TRUE
) {
    active <- mouse_down &&
        mouse_x >= x &&
        mouse_x <= x + width &&
        mouse_y >= y &&
        mouse_y <= y + height

    if (active) {
        value <- min + clamp((mouse_x - x) / width, 0, 1) * (max - min)
    }

    knob_x <- as.integer(round(x + (value - min) / (max - min) * width))
    track_y <- y + height %/% 2L - 2L
    label_text <- if (digits == 0L) {
        sprintf("%.0f", value)
    } else {
        sprintf(paste0("%.", digits, "f"), value)
    }

    if (draw) {
        ray$DrawText(label, x - 52L, y + 4L, 10L, colors$text)
        ray$DrawText(label_text, x + width + 10L, y + 4L, 10L, colors$text)
        ray$DrawRectangle(x, track_y, width, 4L, colors$track)
        ray$DrawRectangle(x, track_y, knob_x - x, 4L, colors$fill)
        ray$DrawRectangle(knob_x - 5L, y, 10L, height, colors$knob)
    }

    value
}

check_box <- function(
    ray,
    label,
    value,
    x,
    y,
    size,
    mouse_x,
    mouse_y,
    mouse_down,
    previous_mouse_down,
    colors,
    draw = TRUE
) {
    active <- mouse_down &&
        !previous_mouse_down &&
        mouse_x >= x &&
        mouse_x <= x + size &&
        mouse_y >= y &&
        mouse_y <= y + size

    if (active) {
        value <- !value
    }

    if (draw) {
        ray$DrawLine(x, y, x + size, y, colors$knob)
        ray$DrawLine(x + size, y, x + size, y + size, colors$knob)
        ray$DrawLine(x + size, y + size, x, y + size, colors$knob)
        ray$DrawLine(x, y + size, x, y, colors$knob)
        if (value) {
            ray$DrawRectangle(x + 4L, y + 4L, size - 8L, size - 8L, colors$fill)
        }
        ray$DrawText(label, x + size + 8L, y + 4L, 10L, colors$text)
    }

    value
}

bind_raylib <- function(raylib_path) {
    ray <- new.env(parent = globalenv())
    info <- dynbind(
        raylib_path,
        paste(
            "InitWindow(iiZ)v",
            "CloseWindow()v",
            "WindowShouldClose()B",
            "BeginDrawing()v",
            "EndDrawing()v",
            "ClearBackground(<Color>)v",
            "DrawLineBezier(<Vector2><Vector2>f<Color>)v",
            "DrawLineEx(<Vector2><Vector2>f<Color>)v",
            "DrawLine(iiii<Color>)v",
            "DrawRectangle(iiii<Color>)v",
            "DrawText(Ziii<Color>)v",
            "DrawFPS(ii)v",
            "SetTargetFPS(i)v",
            "GetTime()d",
            "GetMouseX()i",
            "GetMouseY()i",
            "IsMouseButtonDown(i)B",
            sep = ";"
        ),
        envir = ray
    )
    if (length(info$unresolved.symbols)) {
        stop(
            "unresolved raylib symbols: ",
            paste(info$unresolved.symbols, collapse = ", "),
            call. = FALSE
        )
    }
    list(ray = ray, libhandle = info$libhandle)
}

run_raylib_tinycc_window <- function(kernel) {
    raylib_path <- find_raylib()
    bound <- bind_raylib(raylib_path)
    ray <- bound$ray
    render_symbols <- resolve_raylib_symbols(bound$libhandle)

    ray$InitWindow(800L, 450L, "rdyncall + Rtinycc raylib recursive tree")
    on.exit(ray$CloseWindow(), add = TRUE)
    ray$SetTargetFPS(demo_target_fps())

    panel_line <- color(218L, 218L, 218L, 255L)
    panel_bg <- color(232L, 232L, 232L, 255L)
    text_color <- color(70L, 70L, 70L, 255L)
    track_color <- color(188L, 188L, 188L, 255L)
    fill_color <- color(230L, 41L, 55L, 255L)
    knob_color <- color(60L, 60L, 60L, 255L)
    colors <- list(
        text = text_color,
        track = track_color,
        fill = fill_color,
        knob = knob_color
    )

    angle <- 40
    thick <- 1
    tree_depth <- 10
    decay <- 0.66
    branch_length <- 120
    bezier <- FALSE
    previous_mouse_down <- FALSE
    branch_count <- 0L
    started <- ray$GetTime()
    duration <- demo_duration()

    while (
        !isTRUE(ray$WindowShouldClose()) && ray$GetTime() - started < duration
    ) {
        now <- ray$GetTime()
        mouse_x <- ray$GetMouseX()
        mouse_y <- ray$GetMouseY()
        mouse_down <- isTRUE(ray$IsMouseButtonDown(0L))

        next_angle <- slider_bar(
            ray,
            "Angle",
            angle,
            0,
            180,
            640L,
            40L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            colors,
            draw = FALSE
        )
        next_length <- slider_bar(
            ray,
            "Length",
            branch_length,
            12,
            240,
            640L,
            70L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            colors,
            draw = FALSE
        )
        next_decay <- slider_bar(
            ray,
            "Decay",
            decay,
            0.1,
            0.78,
            640L,
            100L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            colors,
            digits = 2L,
            draw = FALSE
        )
        next_depth <- slider_bar(
            ray,
            "Depth",
            tree_depth,
            1,
            10,
            640L,
            130L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            colors,
            draw = FALSE
        )
        next_thick <- slider_bar(
            ray,
            "Thick",
            thick,
            1,
            8,
            640L,
            160L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            colors,
            draw = FALSE
        )
        next_bezier <- check_box(
            ray,
            "Bezier",
            bezier,
            640L,
            190L,
            20L,
            mouse_x,
            mouse_y,
            mouse_down,
            previous_mouse_down,
            colors,
            draw = FALSE
        )

        angle <- next_angle
        branch_length <- next_length
        decay <- next_decay
        tree_depth <- next_depth
        thick <- next_thick
        bezier <- next_bezier

        ray$BeginDrawing()
        branch_count <- kernel$ray_tree_render(
            render_symbols$ClearBackground,
            render_symbols$DrawLine,
            render_symbols$DrawLineEx,
            render_symbols$DrawLineBezier,
            angle,
            tree_depth,
            branch_length,
            decay,
            thick,
            as.integer(bezier)
        )
        if (branch_count < 0L) {
            stop(
                "raylib_tinycc tree renderer failed to resolve draw callbacks",
                call. = FALSE
            )
        }
        ray$DrawLine(580L, 0L, 580L, 450L, panel_line)
        ray$DrawRectangle(580L, 0L, 220L, 450L, panel_bg)

        slider_bar(
            ray,
            "Angle",
            angle,
            0,
            180,
            640L,
            40L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            colors
        )
        slider_bar(
            ray,
            "Length",
            branch_length,
            12,
            240,
            640L,
            70L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            colors
        )
        slider_bar(
            ray,
            "Decay",
            decay,
            0.1,
            0.78,
            640L,
            100L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            colors,
            digits = 2L
        )
        slider_bar(
            ray,
            "Depth",
            tree_depth,
            1,
            10,
            640L,
            130L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            colors
        )
        slider_bar(
            ray,
            "Thick",
            thick,
            1,
            8,
            640L,
            160L,
            120L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            colors
        )
        check_box(
            ray,
            "Bezier",
            bezier,
            640L,
            190L,
            20L,
            mouse_x,
            mouse_y,
            FALSE,
            previous_mouse_down,
            colors
        )

        ray$DrawText(
            sprintf("TinyCC tree: %d", branch_count),
            640L,
            230L,
            10L,
            text_color
        )
        ray$DrawFPS(10L, 10L)
        previous_mouse_down <- mouse_down
        ray$EndDrawing()
    }

    cat(
        "raylib_tinycc recursive tree closed after ",
        round(ray$GetTime() - started, 2),
        " seconds.\n",
        sep = ""
    )
}

run_raylib_tinycc_demo <- function() {
    if (!requireNamespace("Rtinycc", quietly = TRUE)) {
        stop(
            "demo/raylib_tinycc.R requires the optional Rtinycc package.",
            call. = FALSE
        )
    }

    kernel <- compile_raylib_kernel()
    run_raylib_tinycc_window(kernel)
}

run_raylib_tinycc_demo()
