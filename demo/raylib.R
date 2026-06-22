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
    starts_x <- 275
    starts_y <- 430
    ends_x <- starts_x
    ends_y <- starts_y - branch_length
    angles <- 0
    lengths <- branch_length

    i <- 1L
    while (i <= length(starts_x)) {
        if (lengths[[i]] >= 2 && length(starts_x) < 2^depth) {
            next_length <- lengths[[i]] * decay
            if (next_length >= 2) {
                for (delta in c(theta, -theta)) {
                    a <- angles[[i]] + delta
                    starts_x <- c(starts_x, ends_x[[i]])
                    starts_y <- c(starts_y, ends_y[[i]])
                    ends_x <- c(ends_x, ends_x[[i]] + next_length * sin(a))
                    ends_y <- c(ends_y, ends_y[[i]] - next_length * cos(a))
                    angles <- c(angles, a)
                    lengths <- c(lengths, next_length)
                }
            }
        }
        i <- i + 1L
    }

    data.frame(starts_x, starts_y, ends_x, ends_y, lengths)
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
        cat("raylib probe ok: loaded ", raylib_path, " and generated ", nrow(tree), " branches.\n", sep = "")
        return(invisible(TRUE))
    }

    duration <- as.numeric(Sys.getenv("RAYLIB_DEMO_SECONDS", "4"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 4
    }

    ray$InitWindow(800L, 450L, "rdyncall raylib recursive tree")
    on.exit(ray$CloseWindow(), add = TRUE)
    ray$SetTargetFPS(60L)

    background <- color(245L, 245L, 245L, 255L)
    branch_color <- color(230L, 41L, 55L, 255L)
    panel_line <- color(218L, 218L, 218L, 255L)
    panel_bg <- color(232L, 232L, 232L, 255L)
    text_color <- color(70L, 70L, 70L, 255L)
    started <- ray$GetTime()

    while (!isTRUE(ray$WindowShouldClose()) && ray$GetTime() - started < duration) {
        elapsed <- ray$GetTime() - started
        angle <- 35 + 18 * sin(elapsed * 1.2)
        decay <- 0.64 + 0.04 * sin(elapsed * 0.9)
        tree <- branches(angle = angle, depth = 9L, branch_length = 120, decay = decay)

        ray$BeginDrawing()
        ray$ClearBackground(background)

        for (i in seq_len(nrow(tree))) {
            if (tree$lengths[[i]] >= 2) {
                ray$DrawLineEx(
                    vector2(tree$starts_x[[i]], tree$starts_y[[i]]),
                    vector2(tree$ends_x[[i]], tree$ends_y[[i]]),
                    2,
                    branch_color
                )
            }
        }

        ray$DrawLine(580L, 0L, 580L, 450L, panel_line)
        ray$DrawRectangle(580L, 0L, 220L, 450L, panel_bg)
        ray$DrawText("recursive tree", 615L, 45L, 22L, text_color)
        ray$DrawText(sprintf("angle %.0f", angle), 635L, 90L, 18L, text_color)
        ray$DrawText(sprintf("decay %.2f", decay), 635L, 120L, 18L, text_color)
        ray$DrawText("DrawLineEx(Vector2,", 610L, 180L, 16L, text_color)
        ray$DrawText("           Color)", 610L, 204L, 16L, text_color)
        ray$DrawFPS(10L, 10L)

        ray$EndDrawing()
    }

    cat("raylib recursive tree closed after ", round(ray$GetTime() - started, 2), " seconds.\n", sep = "")
}

run_raylib_demo()
