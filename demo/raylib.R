# Package: rdyncall
# File: demo/raylib.R
# Description: raylib recursive tree demo using aggregate Color and Vector2 arguments.
# Reference: https://github.com/raysan5/raylib/blob/master/examples/shapes/shapes_recursive_tree.c

library(rdyncall)
source(system.file("demo-support", "github-release.R", package = "rdyncall", mustWork = TRUE), local = TRUE)

raylib_asset_pattern <- function() {
    sys <- Sys.info()[["sysname"]]
    arch <- tolower(paste(R.version$arch, Sys.info()[["machine"]]))

    if (identical(sys, "Darwin")) {
        "macos"
    } else if (identical(sys, "Linux")) {
        if (grepl("aarch64|arm64", arch)) {
            "linux_arm64"
        } else if (grepl("i386|i686|x86", arch) && !grepl("x86_64|amd64", arch)) {
            "linux_i386"
        } else {
            "linux_amd64"
        }
    } else if (.Platform$OS.type == "windows") {
        if (grepl("arm64|aarch64", arch)) {
            "winarm64_msvc"
        } else if (grepl("i386|i686|x86", arch) && !grepl("x86_64|amd64", arch)) {
            "win32_msvc"
        } else {
            "win64_msvc"
        }
    } else {
        stop("raylib demo does not know which release asset to use for this platform", call. = FALSE)
    }
}

find_raylib <- function() {
    env_path <- Sys.getenv("RAYLIB_LIB", unset = "")
    if (nzchar(env_path)) {
        if (!file.exists(env_path)) {
            stop("RAYLIB_LIB does not exist: ", env_path, call. = FALSE)
        }
        return(env_path)
    }

    cache_dir <- Sys.getenv("RDYNCALL_RAYLIB_CACHE", unset = "")
    if (!nzchar(cache_dir)) {
        cache_dir <- NULL
    }

    github_release_library(
        repo = "raysan5/raylib",
        asset_pattern = raylib_asset_pattern(),
        cache_name = "raylib",
        exclude_pattern = "webassembly",
        preferred_libraries = c("libraylib.dylib", "libraylib.so", "raylib.dll"),
        cache_dir = cache_dir
    )
}

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

vector2 <- function(x, y) {
    v <- cdata(Vector2)
    v$x <- as.numeric(x)
    v$y <- as.numeric(y)
    v
}

branches <- function(angle = 40, depth = 9L, branch_length = 120, decay = 0.66) {
    theta <- angle * pi / 180
    max_branches <- 2^as.integer(depth) - 1L
    starts_x <- numeric(max_branches)
    starts_y <- numeric(max_branches)
    ends_x <- numeric(max_branches)
    ends_y <- numeric(max_branches)
    angles <- numeric(max_branches)
    lengths <- numeric(max_branches)

    starts_x[[1L]] <- 275
    starts_y[[1L]] <- 430
    ends_x[[1L]] <- starts_x[[1L]]
    ends_y[[1L]] <- starts_y[[1L]] - branch_length
    lengths[[1L]] <- branch_length

    count <- 1L
    i <- 1L
    while (i <= count && count < max_branches) {
        next_length <- lengths[[i]] * decay
        if (lengths[[i]] >= 2 && next_length >= 2) {
            for (delta in c(theta, -theta)) {
                if (count >= max_branches) {
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
        starts_x = as.integer(round(starts_x[seq])),
        starts_y = as.integer(round(starts_y[seq])),
        ends_x = as.integer(round(ends_x[seq])),
        ends_y = as.integer(round(ends_y[seq])),
        lengths = lengths[seq],
        n = count
    )
}

clamp <- function(x, lower, upper) {
    pmax(lower, pmin(upper, x))
}

slider <- function(ray, label, value, min, max, x, y, width, mouse_x, mouse_y,
                   mouse_down, colors) {
    track_y <- y + 28L
    active <- mouse_down &&
        mouse_x >= x - 8L && mouse_x <= x + width + 8L &&
        mouse_y >= track_y - 12L && mouse_y <= track_y + 12L

    if (active) {
        value <- min + clamp((mouse_x - x) / width, 0, 1) * (max - min)
    }

    knob_x <- as.integer(round(x + (value - min) / (max - min) * width))
    ray$DrawText(sprintf("%s %.2f", label, value), x, y, 16L, colors$text)
    ray$DrawRectangle(x, track_y, width, 4L, colors$track)
    ray$DrawRectangle(x, track_y, knob_x - x, 4L, colors$fill)
    ray$DrawRectangle(knob_x - 5L, track_y - 8L, 10L, 20L, colors$knob)

    list(value = value, active = active)
}

run_raylib_demo <- function() {
    raylib_path <- find_raylib()
    ray <- new.env(parent = globalenv())
    ray_info <- dynbind(
        raylib_path,
        paste(
            "InitWindow(iiZ)v",
            "CloseWindow()v",
            "WindowShouldClose()B",
            "BeginDrawing()v",
            "EndDrawing()v",
            "ClearBackground(<Color>)v",
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

    if (length(ray_info$unresolved.symbols)) {
        stop("unresolved raylib symbols: ", paste(ray_info$unresolved.symbols, collapse = ", "), call. = FALSE)
    }

    probe_only <- tolower(Sys.getenv("RAYLIB_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")
    if (probe_only) {
        tree <- branches()
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
    on.exit(ray$CloseWindow(), add = TRUE)
    ray$SetTargetFPS(60L)

    background <- color(245L, 245L, 245L, 255L)
    branch_color <- color(230L, 41L, 55L, 255L)
    panel_line <- color(218L, 218L, 218L, 255L)
    panel_bg <- color(232L, 232L, 232L, 255L)
    text_color <- color(70L, 70L, 70L, 255L)
    track_color <- color(188L, 188L, 188L, 255L)
    fill_color <- color(230L, 41L, 55L, 255L)
    knob_color <- color(60L, 60L, 60L, 255L)
    colors <- list(text = text_color, track = track_color, fill = fill_color, knob = knob_color)

    angle <- 35
    decay <- 0.64
    drawn_angle <- NA_real_
    drawn_decay <- NA_real_
    last_tree_draw <- -Inf
    tree_dirty <- TRUE
    tree_cache <- NULL
    tree_redraw_frames <- 2L
    preview_start <- vector2(628, 250)
    preview_end <- vector2(628, 210)
    started <- ray$GetTime()

    while (!isTRUE(ray$WindowShouldClose()) && ray$GetTime() - started < duration) {
        now <- ray$GetTime()
        mouse_x <- ray$GetMouseX()
        mouse_y <- ray$GetMouseY()
        mouse_down <- isTRUE(ray$IsMouseButtonDown(0L))

        ray$BeginDrawing()

        ray$DrawLine(580L, 0L, 580L, 450L, panel_line)
        ray$DrawRectangle(580L, 0L, 220L, 450L, panel_bg)
        ray$DrawText("recursive tree", 615L, 45L, 22L, text_color)
        angle_slider <- slider(ray, "angle", angle, 17, 53, 615L, 92L, 145L,
            mouse_x, mouse_y, mouse_down, colors)
        decay_slider <- slider(ray, "decay", decay, 0.60, 0.68, 615L, 148L, 145L,
            mouse_x, mouse_y, mouse_down, colors)
        if (!identical(angle, angle_slider$value) || !identical(decay, decay_slider$value)) {
            angle <- angle_slider$value
            decay <- decay_slider$value
            tree_dirty <- TRUE
        }

        rebuild_tree <- tree_dirty && (!mouse_down || now - last_tree_draw >= 1 / 30)
        if (rebuild_tree || is.null(tree_cache)) {
            tree_cache <- branches(angle = angle, depth = 9L, branch_length = 120, decay = decay)
            drawn_angle <- angle
            drawn_decay <- decay
            last_tree_draw <- now
            tree_dirty <- FALSE
            tree_redraw_frames <- 2L
        }

        if (tree_redraw_frames > 0L) {
            ray$DrawRectangle(0L, 0L, 580L, 450L, background)
            for (i in seq_len(tree_cache$n)) {
                if (tree_cache$lengths[[i]] >= 2) {
                    ray$DrawLine(
                        tree_cache$starts_x[[i]], tree_cache$starts_y[[i]],
                        tree_cache$ends_x[[i]], tree_cache$ends_y[[i]],
                        branch_color
                    )
                }
            }
            tree_redraw_frames <- tree_redraw_frames - 1L
        }

        preview_end$x <- 628 + 40 * sin(angle * pi / 180)
        preview_end$y <- 250 - 40 * cos(angle * pi / 180)
        ray$DrawText("DrawLineEx(Vector2,", 610L, 226L, 16L, text_color)
        ray$DrawText("           Color)", 610L, 250L, 16L, text_color)
        ray$DrawLineEx(preview_start, preview_end, 3, branch_color)
        ray$DrawText(sprintf("tree %.0f / %.2f", drawn_angle, drawn_decay), 615L, 306L, 16L, text_color)
        ray$DrawText("drag sliders to redraw", 615L, 334L, 16L, text_color)
        ray$DrawFPS(615L, 382L)

        ray$EndDrawing()
    }

    cat("raylib recursive tree closed after ", round(ray$GetTime() - started, 2), " seconds.\n", sep = "")
}

run_raylib_demo()
