# Package: rdyncall
# File: demo/SDL_raster.R
# Description: SDL3 raster texture demo with illustrative base R timing.

library(rdyncall)

sdl3_libs <- c(Sys.getenv("SDL3_LIB", unset = ""), "SDL3", "SDL3-0", "SDL3-3")
sdl3_libs <- sdl3_libs[nzchar(sdl3_libs)]

sdl <- new.env(parent = globalenv())
sdl_info <- tryCatch(
    dynbind(
        sdl3_libs,
        paste(
            "SDL_Init(I)B",
            "SDL_Quit()v",
            "SDL_CreateWindow(ZiiL)p",
            "SDL_CreateRenderer(pZ)p",
            "SDL_DestroyRenderer(p)v",
            "SDL_DestroyWindow(p)v",
            "SDL_GetError()Z",
            "SDL_SetRenderDrawColor(pCCCC)B",
            "SDL_CreateTexture(pIiii)p",
            "SDL_DestroyTexture(p)v",
            "SDL_UpdateTexture(pppi)B",
            "SDL_RenderClear(p)B",
            "SDL_RenderTexture(pppp)B",
            "SDL_RenderPresent(p)B",
            "SDL_PollEvent(p)B",
            "SDL_Delay(I)v",
            sep = ";"
        ),
        envir = sdl
    ),
    error = function(e) {
        stop(
            conditionMessage(e),
            " Install SDL3 with a common package manager or set SDL3_LIB to the shared library path.",
            call. = FALSE
        )
    }
)
rm(sdl3_libs)

if (length(sdl_info$unresolved.symbols)) {
    stop("unresolved SDL3 symbols: ", paste(sdl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(sdl_info)

SDL_INIT_VIDEO <- 0x00000020L
SDL_EVENT_QUIT <- 0x100L
SDL_TEXTUREACCESS_STATIC <- 0L
SDL_PIXELFORMAT_RGBA32 <- if (identical(.Platform$endian, "big")) 0x16462004L else 0x16762004L

demo_iterations <- function() {
    iterations <- as.integer(Sys.getenv("SDL_RASTER_DEMO_ITER", "100"))
    if (is.na(iterations) || iterations < 1L) {
        iterations <- 100L
    }
    iterations
}

demo_duration <- function() {
    duration <- as.numeric(Sys.getenv("SDL_RASTER_DEMO_SECONDS", "8"))
    if (!is.finite(duration) || duration <= 0) {
        duration <- 8
    }
    duration
}

is_probe_only <- function() {
    tolower(Sys.getenv("SDL_RASTER_DEMO_PROBE_ONLY", "false")) %in% c("1", "true", "yes")
}

make_field <- function(width, height) {
    x <- seq(-2.2, 1.0, length.out = width)
    y <- seq(-1.2, 1.2, length.out = height)
    field <- outer(y, x, function(yy, xx) {
        rings <- sin(12 * sqrt((xx + 0.55)^2 + (yy - 0.08)^2))
        waves <- cos(9 * xx - 5 * yy) + sin(7 * yy)
        ridge <- exp(-4 * ((xx + 0.7)^2 + (yy + 0.25)^2))
        rings + 0.55 * waves + 2.2 * ridge
    })
    field <- field - min(field)
    field / max(field)
}

demo_palette <- function(n = 256L) {
    grDevices::colorRampPalette(c(
        "#06101f", "#173b6c", "#326f8f", "#6bb78e", "#f5d061", "#f07f3c", "#b21f35"
    ))(n)
}

field_index <- function(field, n) {
    idx <- as.integer(field * (n - 1L)) + 1L
    pmax.int(1L, pmin.int(n, idx))
}

base_raster <- function(field, palette) {
    colors <- palette[field_index(field, length(palette))]
    dim(colors) <- dim(field)
    grDevices::as.raster(colors)
}

rgba_buffer <- function(field, palette) {
    idx <- as.vector(t(field_index(field, length(palette))))
    rgba <- grDevices::col2rgb(palette[idx], alpha = TRUE)
    as.raw(as.vector(rgba))
}

time_value <- function(expr) {
    system.time(expr)[["elapsed"]]
}

draw_base_raster <- function(image) {
    graphics::par(mar = c(0, 0, 0, 0))
    graphics::plot.new()
    graphics::plot.window(c(0, 1), c(0, 1), xaxs = "i", yaxs = "i")
    graphics::rasterImage(image, 0, 0, 1, 1, interpolate = FALSE)
    try(grDevices::dev.flush(), silent = TRUE)
    invisible(TRUE)
}

time_base_display <- function(image, iterations) {
    if (grDevices::dev.cur() == 1L && !interactive()) {
        return(NA_real_)
    }

    opened <- FALSE
    if (grDevices::dev.cur() == 1L) {
        opened <- tryCatch({
            grDevices::dev.new(width = 6.4, height = 4.8)
            TRUE
        }, error = function(e) {
            cat("base R display skipped: ", conditionMessage(e), "\n", sep = "")
            FALSE
        })
    }
    if (!opened && grDevices::dev.cur() == 1L) {
        return(NA_real_)
    }
    old_par <- graphics::par(no.readonly = TRUE)
    on.exit({
        graphics::par(old_par)
        if (opened && grDevices::dev.cur() != 1L) {
            grDevices::dev.off()
        }
    }, add = TRUE)

    time_value({
        for (i in seq_len(iterations)) {
            draw_base_raster(image)
        }
    })
}

print_timing <- function(label, value) {
    if (is.na(value)) {
        cat("  ", label, ": skipped\n", sep = "")
    } else {
        cat("  ", label, ": ", sprintf("%.3f", value), " sec\n", sep = "")
    }
}

render_sdl_raster <- function(renderer, texture, buffer, pitch) {
    if (!isTRUE(sdl$SDL_UpdateTexture(texture, NULL, buffer, pitch))) {
        stop("SDL_UpdateTexture failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    sdl$SDL_SetRenderDrawColor(renderer, 0L, 0L, 0L, 255L)
    if (!isTRUE(sdl$SDL_RenderClear(renderer))) {
        stop("SDL_RenderClear failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    if (!isTRUE(sdl$SDL_RenderTexture(renderer, texture, NULL, NULL))) {
        stop("SDL_RenderTexture failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    if (!isTRUE(sdl$SDL_RenderPresent(renderer))) {
        stop("SDL_RenderPresent failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    invisible(TRUE)
}

run_sdl_raster_demo <- function() {
    width <- 640L
    height <- 480L
    palette <- demo_palette()
    field <- make_field(width, height)
    iterations <- demo_iterations()

    image <- base_raster(field, palette)
    buffer <- rgba_buffer(field, palette)
    stopifnot(length(buffer) == width * height * 4L)

    base_prepare_time <- time_value({
        for (i in seq_len(iterations)) {
            base_raster(field, palette)
        }
    })
    buffer_prepare_time <- time_value({
        for (i in seq_len(iterations)) {
            rgba_buffer(field, palette)
        }
    })

    if (is_probe_only()) {
        cat("SDL3 raster probe ok: symbols resolved and raster buffers prepared.\n")
        cat("illustrative preparation timing over ", iterations, " iterations:\n", sep = "")
        print_timing("base R as.raster", base_prepare_time)
        print_timing("rdyncall RGBA buffer", buffer_prepare_time)
        return(invisible(TRUE))
    }

    base_display_time <- time_base_display(image, iterations)

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3 raster texture", width, height, 0)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)

    renderer <- sdl$SDL_CreateRenderer(window, NULL)
    if (is.null(renderer) || is.nullptr(renderer)) {
        stop("SDL_CreateRenderer failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyRenderer(renderer), add = TRUE)

    texture <- sdl$SDL_CreateTexture(renderer, SDL_PIXELFORMAT_RGBA32, SDL_TEXTUREACCESS_STATIC, width, height)
    if (is.null(texture) || is.nullptr(texture)) {
        stop("SDL_CreateTexture failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyTexture(texture), add = TRUE)

    pitch <- width * 4L
    sdl_display_time <- time_value({
        for (i in seq_len(iterations)) {
            render_sdl_raster(renderer, texture, buffer, pitch)
        }
    })

    cat("illustrative demo timing over ", iterations, " iterations:\n", sep = "")
    print_timing("base R as.raster", base_prepare_time)
    print_timing("rdyncall RGBA buffer", buffer_prepare_time)
    print_timing("base graphics draw", base_display_time)
    print_timing("SDL3 update/render/present", sdl_display_time)

    event <- raw(128L)
    started <- proc.time()[["elapsed"]]
    duration <- demo_duration()
    repeat {
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }
        render_sdl_raster(renderer, texture, buffer, pitch)
        if (proc.time()[["elapsed"]] - started >= duration) {
            return(invisible(TRUE))
        }
        sdl$SDL_Delay(16L)
    }
}

run_sdl_raster_demo()
