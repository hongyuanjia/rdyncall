# Package: rdyncall
# File: demo/raylib.R
# Description: raylib recursive tree demo using aggregate Color and Vector2 arguments.
# Reference: https://github.com/raysan5/raylib/blob/master/examples/shapes/shapes_recursive_tree.c

library(rdyncall)
source(system.file("demo-support", "raylib.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

# raylib aggregate types used by value in C calls.
# Color: four unsigned-byte RGBA channels.
cstruct("Color{CCCC}r g b a;")
# Vector2: two float coordinates.
cstruct("Vector2{ff}x y;")
# Rectangle: float x/y origin and float width/height.
cstruct("Rectangle{ffff}x y width height;")
# Texture2D: raylib texture id and image metadata.
cstruct("Texture2D{Iiiii}id width height mipmaps format;")
# RenderTexture2D: framebuffer id plus color/depth textures.
cstruct("RenderTexture2D{I<Texture2D><Texture2D>}id texture depth;")

# Build a raylib Color struct for by-value arguments.
color <- function(r, g, b, a = 255L) {
    x <- cdata(Color)
    x$r <- as.integer(r)
    x$g <- as.integer(g)
    x$b <- as.integer(b)
    x$a <- as.integer(a)
    x
}

# Build a raylib Vector2 struct for by-value arguments.
vector2 <- function(x, y) {
    v <- cdata(Vector2)
    v$x <- as.numeric(x)
    v$y <- as.numeric(y)
    v
}

# Build a raylib Rectangle struct for texture source rectangles.
rectangle <- function(x, y, width, height) {
    r <- cdata(Rectangle)
    r$x <- as.numeric(x)
    r$y <- as.numeric(y)
    r$width <- as.numeric(width)
    r$height <- as.numeric(height)
    r
}

# Generate the recursive tree geometry in R before drawing it through raylib.
branches <- function(angle = 40, depth = 10, branch_length = 120, decay = 0.66,
                     start_x = 275, start_y = 450) {
    # Convert degrees to radians because the branch update uses sin/cos.
    theta <- angle * pi / 180
    # Keep the demo responsive by capping the number of branch segments.
    capacity <- 1030L
    max_branches <- min(2^floor(depth), capacity - 1L)
    starts_x <- numeric(capacity)
    starts_y <- numeric(capacity)
    ends_x <- numeric(capacity)
    ends_y <- numeric(capacity)
    angles <- numeric(capacity)
    lengths <- numeric(capacity)

    starts_x[[1L]] <- start_x
    starts_y[[1L]] <- start_y
    ends_x[[1L]] <- starts_x[[1L]]
    ends_y[[1L]] <- starts_y[[1L]] - branch_length
    lengths[[1L]] <- branch_length

    count <- 1L
    i <- 1L
    while (i <= count && count < max_branches) {
        next_length <- lengths[[i]] * decay
        if (lengths[[i]] >= 2 && next_length >= 2 && count < max_branches) {
            # Add left and right child branches from the current endpoint.
            for (delta in c(theta, -theta)) {
                if (count >= capacity) {
                    break
                }
                count <- count + 1L
                a <- angles[[i]] + delta
                starts_x[[count]] <- ends_x[[i]]
                starts_y[[count]] <- ends_y[[i]]
                ends_x[[count]] <- ends_x[[i]] + next_length * sin(a)
                ends_y[[count]] <- ends_y[[i]] - next_length * cos(a)
                angles[[count]] <- a
                lengths[[count]] <- next_length
            }
        }
        i <- i + 1L
    }

    seq <- seq_len(count)
    list(
        starts_x = starts_x[seq],
        starts_y = starts_y[seq],
        ends_x = ends_x[seq],
        ends_y = ends_y[seq],
        lengths = lengths[seq],
        n = count
    )
}

# Cache tree coordinates and, when needed, prebuilt Vector2 structs for raylib.
branch_cache <- function(angle, depth, branch_length, decay, needs_vector2 = TRUE) {
    tree <- branches(angle = angle, depth = depth, branch_length = branch_length, decay = decay)
    draw <- tree$lengths >= 2
    if (needs_vector2) {
        starts <- vector("list", tree$n)
        ends <- vector("list", tree$n)
        for (i in seq_len(tree$n)) {
            starts[[i]] <- vector2(tree$starts_x[[i]], tree$starts_y[[i]])
            ends[[i]] <- vector2(tree$ends_x[[i]], tree$ends_y[[i]])
        }
        tree$starts <- starts
        tree$ends <- ends
    }
    tree$draw <- draw
    tree
}

# Draw the cached branch list using the selected raylib line primitive.
draw_tree <- function(ray, tree, thick, bezier, branch_color) {
    plain_line <- !bezier && thick <= 1.05
    for (i in seq_len(tree$n)) {
        if (tree$draw[[i]]) {
            if (plain_line) {
                ray$DrawLine(
                    as.integer(round(tree$starts_x[[i]])), as.integer(round(tree$starts_y[[i]])),
                    as.integer(round(tree$ends_x[[i]])), as.integer(round(tree$ends_y[[i]])),
                    branch_color
                )
            } else if (bezier) {
                ray$DrawLineBezier(tree$starts[[i]], tree$ends[[i]], thick, branch_color)
            } else {
                ray$DrawLineEx(tree$starts[[i]], tree$ends[[i]], thick, branch_color)
            }
        }
    }
    invisible(TRUE)
}

# Estimate how many segments a full binary tree depth would produce.
estimated_branch_count <- function(depth) {
    min(2^floor(depth), 1029L)
}

# Reduce preview depth while dragging expensive settings so UI interaction stays smooth.
interactive_depth <- function(depth, decay, thick, bezier) {
    if (estimated_branch_count(depth) <= 512L || decay < 0.7) {
        return(depth)
    }

    if (bezier || thick > 1.05) {
        return(min(depth, 7.99))
    }

    min(depth, 8.99)
}

# Clamp a numeric value to a closed interval.
clamp <- function(x, lower, upper) {
    pmax(lower, pmin(upper, x))
}

# Draw and update a horizontal slider; returns the possibly changed value.
slider_bar <- function(ray, label, value, min, max, x, y, width, height,
                       mouse_x, mouse_y, mouse_down, colors, digits = 0L,
                       draw = TRUE) {
    active <- mouse_down &&
        mouse_x >= x && mouse_x <= x + width &&
        mouse_y >= y && mouse_y <= y + height

    if (active) {
        # Map the mouse position back to the slider's numeric range.
        value <- min + clamp((mouse_x - x) / width, 0, 1) * (max - min)
    }

    knob_x <- as.integer(round(x + (value - min) / (max - min) * width))
    track_y <- y + height %/% 2L - 2L
    label_text <- if (digits == 0L) sprintf("%.0f", value) else sprintf(paste0("%.", digits, "f"), value)

    if (draw) {
        ray$DrawText(label, x - 52L, y + 4L, 10L, colors$text)
        ray$DrawText(label_text, x + width + 10L, y + 4L, 10L, colors$text)
        ray$DrawRectangle(x, track_y, width, 4L, colors$track)
        ray$DrawRectangle(x, track_y, knob_x - x, 4L, colors$fill)
        ray$DrawRectangle(knob_x - 5L, y, 10L, height, colors$knob)
    }

    value
}

# Draw and update a checkbox; toggles only on a fresh mouse press.
check_box <- function(ray, label, value, x, y, size, mouse_x, mouse_y,
                      mouse_down, previous_mouse_down, colors, draw = TRUE) {
    active <- mouse_down &&
        !previous_mouse_down &&
        mouse_x >= x && mouse_x <= x + size &&
        mouse_y >= y && mouse_y <= y + size

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

# Run the interactive recursive-tree demo.
run_raylib_demo <- function() {
    raylib_path <- find_raylib()
    ray <- new.env(parent = globalenv())
    # Bind only the raylib functions used by this demo.
    ray_info <- dynbind(
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
            "DrawTextureRec(<Texture2D><Rectangle><Vector2><Color>)v",
            "DrawText(Ziii<Color>)v",
            "DrawFPS(ii)v",
            "LoadRenderTexture(ii)<RenderTexture2D>",
            "UnloadRenderTexture(<RenderTexture2D>)v",
            "BeginTextureMode(<RenderTexture2D>)v",
            "EndTextureMode()v",
            "SetTargetFPS(i)v",
            "GetTime()d",
            "GetMouseX()i",
            "GetMouseY()i",
            "IsMouseButtonDown(i)B",
            sep = ";"
        ),
        envir = ray
    )

    if (length(ray_info$unresolved.symbols)) {
        stop("unresolved raylib symbols: ", paste(ray_info$unresolved.symbols, collapse = ", "), call. = FALSE)
    }

    # Probe mode validates library loading and aggregate construction without a window.
    probe_only <- tolower(Sys.getenv("RAYLIB_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")
    if (probe_only) {
        tree <- branch_cache(40, 10, 120, 0.66)
        invisible(vector2(tree$starts_x[[1L]], tree$starts_y[[1L]]))
        invisible(color(230L, 41L, 55L, 255L))
        cat("raylib probe ok: loaded ", raylib_path, " and generated ", tree$n, " branches.\n", sep = "")
        return(invisible(TRUE))
    }

    duration_env <- Sys.getenv("RAYLIB_DEMO_SECONDS", unset = "")
    duration <- if (nzchar(duration_env)) as.numeric(duration_env) else Inf
    if (is.na(duration) || duration <= 0) {
        duration <- Inf
    }

    ray$InitWindow(800L, 450L, "rdyncall raylib recursive tree")
    tree_target <- NULL
    on.exit({
        if (!is.null(tree_target)) {
            ray$UnloadRenderTexture(tree_target)
        }
        ray$CloseWindow()
    }, add = TRUE)
    ray$SetTargetFPS(60L)

    # Canvas background color.
    background <- color(245L, 245L, 245L, 255L)
    # Recursive tree branch color.
    branch_color <- color(230L, 41L, 55L, 255L)
    # Divider line between the drawing area and the control panel.
    panel_line <- color(218L, 218L, 218L, 255L)
    # Control panel background color.
    panel_bg <- color(232L, 232L, 232L, 255L)
    # Control label/value text color.
    text_color <- color(70L, 70L, 70L, 255L)
    # Slider track color.
    track_color <- color(188L, 188L, 188L, 255L)
    # Slider fill color.
    fill_color <- color(230L, 41L, 55L, 255L)
    # Slider knob and checkbox outline color.
    knob_color <- color(60L, 60L, 60L, 255L)
    # Texture tint color; white keeps the rendered texture unchanged.
    white <- color(255L, 255L, 255L, 255L)
    colors <- list(text = text_color, track = track_color, fill = fill_color, knob = knob_color)

    # Render the tree once into an offscreen texture, then blit that texture
    # every frame while the controls are being drawn.
    tree_target <- ray$LoadRenderTexture(580L, 450L)
    tree_texture <- tree_target$texture
    tree_source <- rectangle(0, 0, 580, -450)
    tree_position <- vector2(0, 0)

    # Initial branch angle in degrees.
    angle <- 40
    # Initial line thickness in pixels.
    thick <- 1
    # Initial recursion depth.
    tree_depth <- 10
    # Initial length multiplier between a parent and child branch.
    decay <- 0.66
    # Initial trunk length in pixels.
    branch_length <- 120
    # Initial line style; FALSE uses straight segments.
    bezier <- FALSE
    previous_mouse_down <- FALSE
    last_tree_draw <- -Inf
    tree_dirty <- TRUE
    tree_cache <- NULL
    rendered_preview <- FALSE
    started <- ray$GetTime()

    while (!isTRUE(ray$WindowShouldClose()) && ray$GetTime() - started < duration) {
        now <- ray$GetTime()
        mouse_x <- ray$GetMouseX()
        mouse_y <- ray$GetMouseY()
        mouse_down <- isTRUE(ray$IsMouseButtonDown(0L))

        # First pass updates control values without drawing. This keeps input
        # handling separate from visual rendering.
        next_angle <- slider_bar(ray, "Angle", angle, 0, 180, 640L, 40L, 120L, 20L,
            mouse_x, mouse_y, mouse_down, colors, draw = FALSE)
        next_length <- slider_bar(ray, "Length", branch_length, 12, 240, 640L, 70L, 120L, 20L,
            mouse_x, mouse_y, mouse_down, colors, draw = FALSE)
        next_decay <- slider_bar(ray, "Decay", decay, 0.1, 0.78, 640L, 100L, 120L, 20L,
            mouse_x, mouse_y, mouse_down, colors, digits = 2L, draw = FALSE)
        next_depth <- slider_bar(ray, "Depth", tree_depth, 1, 10, 640L, 130L, 120L, 20L,
            mouse_x, mouse_y, mouse_down, colors, draw = FALSE)
        next_thick <- slider_bar(ray, "Thick", thick, 1, 8, 640L, 160L, 120L, 20L,
            mouse_x, mouse_y, mouse_down, colors, draw = FALSE)
        next_bezier <- check_box(ray, "Bezier", bezier, 640L, 190L, 20L,
            mouse_x, mouse_y, mouse_down, previous_mouse_down, colors, draw = FALSE)

        if (!identical(angle, next_angle) || !identical(branch_length, next_length) ||
            !identical(decay, next_decay) || !identical(tree_depth, next_depth) ||
            !identical(thick, next_thick) || !identical(bezier, next_bezier)) {
            angle <- next_angle
            branch_length <- next_length
            decay <- next_decay
            tree_depth <- next_depth
            thick <- next_thick
            bezier <- next_bezier
            tree_dirty <- TRUE
        }

        # While dragging high-cost controls, render a shallower preview. When
        # the mouse is released, redraw the full requested tree.
        preview_depth <- if (mouse_down) {
            interactive_depth(tree_depth, decay, thick, bezier)
        } else {
            tree_depth
        }
        preview <- floor(preview_depth) != floor(tree_depth)
        rebuild_interval <- if (mouse_down && preview) 1 / 12 else if (mouse_down) 1 / 8 else 0
        needs_full_redraw <- !mouse_down && rendered_preview
        needs_vector2 <- bezier || thick > 1.05
        rebuild_tree <- (tree_dirty || needs_full_redraw) &&
            (!mouse_down || now - last_tree_draw >= rebuild_interval)
        if (rebuild_tree || is.null(tree_cache)) {
            # Rebuild geometry in R and redraw the offscreen texture through raylib.
            tree_cache <- branch_cache(angle, preview_depth, branch_length, decay,
                needs_vector2 = needs_vector2)
            ray$BeginTextureMode(tree_target)
            ray$ClearBackground(background)
            draw_tree(ray, tree_cache, thick, bezier, branch_color)
            ray$EndTextureMode()
            last_tree_draw <- now
            tree_dirty <- FALSE
            rendered_preview <- preview
        }

        ray$BeginDrawing()

        # Compose the cached tree texture and the live control panel.
        ray$ClearBackground(background)
        ray$DrawTextureRec(tree_texture, tree_source, tree_position, white)
        ray$DrawLine(580L, 0L, 580L, 450L, panel_line)
        ray$DrawRectangle(580L, 0L, 220L, 450L, panel_bg)

        slider_bar(ray, "Angle", angle, 0, 180, 640L, 40L, 120L, 20L,
            mouse_x, mouse_y, FALSE, colors)
        slider_bar(ray, "Length", branch_length, 12, 240, 640L, 70L, 120L, 20L,
            mouse_x, mouse_y, FALSE, colors)
        slider_bar(ray, "Decay", decay, 0.1, 0.78, 640L, 100L, 120L, 20L,
            mouse_x, mouse_y, FALSE, colors, digits = 2L)
        slider_bar(ray, "Depth", tree_depth, 1, 10, 640L, 130L, 120L, 20L,
            mouse_x, mouse_y, FALSE, colors)
        slider_bar(ray, "Thick", thick, 1, 8, 640L, 160L, 120L, 20L,
            mouse_x, mouse_y, FALSE, colors)
        check_box(ray, "Bezier", bezier, 640L, 190L, 20L,
            mouse_x, mouse_y, FALSE, previous_mouse_down, colors)

        ray$DrawFPS(10L, 10L)
        previous_mouse_down <- mouse_down

        ray$EndDrawing()
    }

    cat("raylib recursive tree closed after ", round(ray$GetTime() - started, 2), " seconds.\n", sep = "")
}

run_raylib_demo()
