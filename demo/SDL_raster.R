# Package: rdyncall
# File: demo/SDL_raster.R
# Description: SDL3/OpenGL Mandelbrot raster demo with illustrative base R timing.

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
            "SDL_DestroyWindow(p)v",
            "SDL_GetError()Z",
            "SDL_GL_SetAttribute(ii)B",
            "SDL_GL_CreateContext(p)p",
            "SDL_GL_DestroyContext(p)v",
            "SDL_GL_SetSwapInterval(i)B",
            "SDL_GL_SwapWindow(p)B",
            "SDL_SetWindowPosition(pii)B",
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

gl_libs <- c(
    Sys.getenv("OPENGL_LIB", unset = ""),
    "/System/Library/Frameworks/OpenGL.framework/OpenGL",
    "OPENGL32", "OpenGL", "GL", "GL.so.1"
)
gl_libs <- gl_libs[nzchar(gl_libs)]

gl <- new.env(parent = globalenv())
gl_info <- tryCatch(
    dynbind(
        gl_libs,
        paste(
            "glBegin(I)v",
            "glBindTexture(II)v",
            "glClear(I)v",
            "glDeleteTextures(i*I)v",
            "glDisable(I)v",
            "glEnable(I)v",
            "glEnd()v",
            "glGenTextures(i*I)v",
            "glLoadIdentity()v",
            "glMatrixMode(I)v",
            "glOrtho(dddddd)v",
            "glPixelStorei(Ii)v",
            "glTexCoord2f(ff)v",
            "glTexImage2D(IiiiiiII*v)v",
            "glTexParameteri(IIi)v",
            "glVertex2f(ff)v",
            "glViewport(iiii)v",
            sep = ";"
        ),
        callmode = "stdcall",
        envir = gl
    ),
    error = function(e) {
        stop(
            conditionMessage(e),
            " Install OpenGL or set OPENGL_LIB to the shared library path.",
            call. = FALSE
        )
    }
)
rm(gl_libs)

if (length(gl_info$unresolved.symbols)) {
    stop("unresolved OpenGL symbols: ", paste(gl_info$unresolved.symbols, collapse = ", "), call. = FALSE)
}
rm(gl_info)

SDL_INIT_VIDEO <- 0x00000020L
SDL_EVENT_QUIT <- 0x100L
SDL_WINDOW_OPENGL <- 0x0000000000000002

SDL_GL_RED_SIZE <- 0L
SDL_GL_GREEN_SIZE <- 1L
SDL_GL_BLUE_SIZE <- 2L
SDL_GL_ALPHA_SIZE <- 3L
SDL_GL_DOUBLEBUFFER <- 5L
SDL_GL_CONTEXT_MAJOR_VERSION <- 17L
SDL_GL_CONTEXT_MINOR_VERSION <- 18L

GL_COLOR_BUFFER_BIT <- 0x00004000L
GL_MODELVIEW <- 0x1700L
GL_PROJECTION <- 0x1701L
GL_QUADS <- 0x0007L
GL_NEAREST <- 0x2600L
GL_RGBA <- 0x1908L
GL_TEXTURE_2D <- 0x0DE1L
GL_TEXTURE_MAG_FILTER <- 0x2800L
GL_TEXTURE_MIN_FILTER <- 0x2801L
GL_UNPACK_ALIGNMENT <- 0x0CF5L
GL_UNSIGNED_BYTE <- 0x1401L

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

time_value <- function(expr) {
    system.time(expr)[["elapsed"]]
}

issue_mandelbrot_parameters <- function() {
    xlims <- c(-0.74877, -0.74872)
    ylims <- c(0.065053, 0.065103)
    width <- 640L
    height <- 480L
    nb_iter <- as.integer(min(round(500 + log10(4 / abs(diff(xlims)))^5), 1E4))

    list(
        xlims = xlims,
        ylims = ylims,
        width = width,
        height = height,
        nb_iter = nb_iter
    )
}

issue_palette <- function() {
    rdylbu <- c(
        "#A50026", "#D73027", "#F46D43", "#FDAE61", "#FEE090", "#FFFFBF",
        "#E0F3F8", "#ABD9E9", "#74ADD1", "#4575B4", "#313695"
    )
    palette <- grDevices::colorRampPalette(rev(rdylbu))(1000L)
    c(palette, rev(palette), "black")
}

scale01 <- function(x) {
    rng <- range(x)
    (x - rng[[1L]]) / (rng[[2L]] - rng[[1L]])
}

equalize_values <- function(values, rng = c(0, 0.95), levels = 10000L) {
    levels <- as.integer(levels)
    breaks <- seq(rng[[1L]], rng[[2L]], length.out = levels + 1L)
    cdf <- cumsum(tabulate(findInterval(values, vec = breaks)))
    cdf_min <- min(cdf[cdf > 0L])
    mapped <- ((cdf - cdf_min) / (length(values) - cdf_min) * diff(rng)) + rng[[1L]]
    bins <- round((values - rng[[1L]]) / diff(rng) * (levels - 1L)) + 1L
    mapped[bins]
}

equalize_mandelbrot <- function(counts, nb_iter, rng = c(0, 0.95), levels = 10000L) {
    dims <- dim(counts)
    values <- as.vector(counts)
    in_set <- values == nb_iter
    outside <- scale01(values[!in_set]) * rng[[2L]]
    if (diff(range(outside)) != 0) {
        outside <- equalize_values(outside, rng = rng, levels = levels)
        outside <- scale01(outside) * rng[[2L]]
    }
    values[!in_set] <- outside
    values[in_set] <- 1
    dim(values) <- dims
    values
}

generate_mandelbrot_counts <- function(params) {
    width <- params$width
    height <- params$height
    nb_iter <- params$nb_iter
    x <- params$xlims[[1L]] + seq.int(0L, width - 1L) * diff(params$xlims) / width
    y <- params$ylims[[1L]] + seq.int(0L, height - 1L) * diff(params$ylims) / height
    c_real <- rep(x, times = height)
    c_imag <- rep(y, each = width)
    z_real <- numeric(length(c_real))
    z_imag <- numeric(length(c_real))
    counts <- integer(length(c_real))
    active <- seq_along(c_real)

    for (iter in seq_len(nb_iter)) {
        current <- active
        zr <- z_real[current]
        zi <- z_imag[current]
        zr_new <- zr * zr - zi * zi + c_real[current]
        zi_new <- 2 * zr * zi + c_imag[current]
        z_real[current] <- zr_new
        z_imag[current] <- zi_new

        escaped <- zr_new * zr_new + zi_new * zi_new >= 4
        if (any(escaped)) {
            escaped_index <- current[escaped]
            counts[escaped_index] <- iter
            active <- current[!escaped]
            if (!length(active)) {
                break
            }
        }
    }

    counts[counts == 0L] <- nb_iter
    matrix(counts, nrow = width, ncol = height)
}

make_issue_mandelbrot <- function() {
    params <- issue_mandelbrot_parameters()
    counts <- NULL
    generation_time <- time_value({
        counts <- generate_mandelbrot_counts(params)
    })
    m <- equalize_mandelbrot(counts, params$nb_iter, rng = c(0, 0.95), levels = 10000L)^(1 / 8)

    list(
        x_res = params$width,
        y_res = params$height,
        m = m,
        palette = issue_palette(),
        generation_time = generation_time
    )
}

issue_colors <- function(m, palette) {
    idx <- findInterval(m, seq(0, 1, length.out = length(palette)))
    colors <- palette[idx]
    dim(colors) <- dim(m)
    colors
}

issue_rgba_buffer <- function(m, palette, width, height) {
    idx <- findInterval(m, seq(0, 1, length.out = length(palette)))
    colors <- palette[idx]
    colors_matrix <- matrix(colors, nrow = height, ncol = width, byrow = TRUE)
    rgba <- grDevices::col2rgb(as.vector(colors_matrix), alpha = TRUE)
    as.raw(as.vector(rgba))
}

draw_base_image <- function(m, palette, asp) {
    graphics::image(m, col = palette, asp = asp, axes = FALSE, useRaster = TRUE)
    try(grDevices::dev.flush(), silent = TRUE)
    invisible(TRUE)
}

open_base_graphics_device <- function(width, height) {
    device_width <- width / 96
    device_height <- height / 96

    if (isTRUE(capabilities("aqua"))) {
        opened <- tryCatch({
            grDevices::quartz(
                title = "base R image() Mandelbrot raster",
                width = device_width,
                height = device_height
            )
            TRUE
        }, error = function(e) FALSE)
        if (opened) {
            return(TRUE)
        }
    }

    if (isTRUE(capabilities("X11"))) {
        opened <- tryCatch({
            grDevices::x11(
                width = device_width,
                height = device_height,
                xpos = 40L,
                ypos = 80L,
                title = "base R image() Mandelbrot raster"
            )
            TRUE
        }, error = function(e) FALSE)
        if (opened) {
            return(TRUE)
        }
    }

    tryCatch({
        grDevices::dev.new(width = device_width, height = device_height)
        TRUE
    }, error = function(e) FALSE)
}

device_exists <- function(device) {
    devices <- grDevices::dev.list()
    !is.null(devices) && device %in% unname(devices)
}

close_base_display <- function(state) {
    if (is.null(state$device) || !device_exists(state$device)) {
        return(invisible(FALSE))
    }

    old_device <- grDevices::dev.cur()
    if (device_exists(old_device) && old_device != state$device) {
        on.exit(grDevices::dev.set(old_device), add = TRUE)
    }

    grDevices::dev.set(state$device)
    if (!is.null(state$par)) {
        try(graphics::par(state$par), silent = TRUE)
    }
    if (isTRUE(state$opened)) {
        grDevices::dev.off()
    }

    invisible(TRUE)
}

time_base_image <- function(m, palette, asp, iterations, width, height) {
    if (grDevices::dev.cur() == 1L && !interactive()) {
        return(list(elapsed = NA_real_, device = NULL, opened = FALSE, par = NULL))
    }

    opened <- FALSE
    if (grDevices::dev.cur() == 1L) {
        opened <- open_base_graphics_device(width, height)
    }
    if (!opened && grDevices::dev.cur() == 1L) {
        cat("base R image() timing skipped: no graphics device could be opened\n")
        return(list(elapsed = NA_real_, device = NULL, opened = FALSE, par = NULL))
    }

    old_par <- graphics::par(no.readonly = TRUE)
    graphics::par(mar = c(0, 0, 0, 0))

    elapsed <- time_value({
        for (i in seq_len(iterations)) {
            draw_base_image(m, palette, asp)
        }
    })

    draw_base_image(m, palette, asp)
    list(elapsed = elapsed, device = grDevices::dev.cur(), opened = opened, par = old_par)
}

print_timing <- function(label, value) {
    if (is.na(value)) {
        cat("  ", label, ": skipped\n", sep = "")
    } else {
        cat("  ", label, ": ", sprintf("%.3f", value), " sec\n", sep = "")
    }
}

set_gl_attribute <- function(attr, value) {
    if (!isTRUE(sdl$SDL_GL_SetAttribute(as.integer(attr), as.integer(value)))) {
        stop("SDL_GL_SetAttribute failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
}

place_sdl_window <- function(window, width) {
    ok <- sdl$SDL_SetWindowPosition(window, as.integer(width + 80L), 80L)
    if (!isTRUE(ok)) {
        cat("SDL_SetWindowPosition skipped: ", sdl$SDL_GetError(), "\n", sep = "")
    }
    invisible(ok)
}

prepare_gl_texture <- function(width, height) {
    gl$glViewport(0L, 0L, width, height)
    gl$glMatrixMode(GL_PROJECTION)
    gl$glLoadIdentity()
    gl$glOrtho(0, width, height, 0, -1, 1)
    gl$glMatrixMode(GL_MODELVIEW)
    gl$glLoadIdentity()

    tex_id <- integer(1L)
    gl$glGenTextures(1L, tex_id)
    if (tex_id[[1L]] == 0L) {
        stop("glGenTextures failed", call. = FALSE)
    }
    gl$glBindTexture(GL_TEXTURE_2D, tex_id)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST)
    gl$glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST)
    gl$glPixelStorei(GL_UNPACK_ALIGNMENT, 1L)
    tex_id
}

render_gl_raster <- function(window, texture, buffer, width, height) {
    gl$glBindTexture(GL_TEXTURE_2D, texture)
    gl$glTexImage2D(
        GL_TEXTURE_2D, 0L, 4L,
        width, height, 0L, GL_RGBA, GL_UNSIGNED_BYTE, buffer
    )
    gl$glClear(GL_COLOR_BUFFER_BIT)
    gl$glEnable(GL_TEXTURE_2D)
    gl$glBegin(GL_QUADS)
    gl$glTexCoord2f(0, 1)
    gl$glVertex2f(0, 0)
    gl$glTexCoord2f(1, 1)
    gl$glVertex2f(width, 0)
    gl$glTexCoord2f(1, 0)
    gl$glVertex2f(width, height)
    gl$glTexCoord2f(0, 0)
    gl$glVertex2f(0, height)
    gl$glEnd()
    gl$glDisable(GL_TEXTURE_2D)
    if (!isTRUE(sdl$SDL_GL_SwapWindow(window))) {
        stop("SDL_GL_SwapWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    invisible(TRUE)
}

run_sdl_raster_demo <- function() {
    asset <- make_issue_mandelbrot()
    width <- asset$x_res
    height <- asset$y_res
    m <- asset$m
    palette <- asset$palette
    asp <- height / width
    iterations <- demo_iterations()

    buffer <- issue_rgba_buffer(m, palette, width, height)
    stopifnot(length(buffer) == width * height * 4L)

    rgba_prepare_time <- time_value({
        for (i in seq_len(iterations)) {
            issue_rgba_buffer(m, palette, width, height)
        }
    })

    if (is_probe_only()) {
        invisible(issue_colors(m, palette))
        cat("SDL3/OpenGL raster probe ok: symbols resolved and issue Mandelbrot generated.\n")
        print_timing("Mandelbrot generation setup", asset$generation_time)
        cat("illustrative preparation timing over ", iterations, " iterations:\n", sep = "")
        print_timing("Mandelbrot RGBA buffer", rgba_prepare_time)
        return(invisible(TRUE))
    }

    base_display <- time_base_image(m, palette, asp, iterations, width, height)
    on.exit(close_base_display(base_display), add = TRUE)
    base_image_time <- base_display$elapsed

    if (!isTRUE(sdl$SDL_Init(SDL_INIT_VIDEO))) {
        stop("SDL_Init failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_Quit(), add = TRUE)

    set_gl_attribute(SDL_GL_RED_SIZE, 8L)
    set_gl_attribute(SDL_GL_GREEN_SIZE, 8L)
    set_gl_attribute(SDL_GL_BLUE_SIZE, 8L)
    set_gl_attribute(SDL_GL_ALPHA_SIZE, 8L)
    set_gl_attribute(SDL_GL_DOUBLEBUFFER, 1L)
    set_gl_attribute(SDL_GL_CONTEXT_MAJOR_VERSION, 2L)
    set_gl_attribute(SDL_GL_CONTEXT_MINOR_VERSION, 1L)

    window <- sdl$SDL_CreateWindow("rdyncall SDL3/OpenGL Mandelbrot raster", width, height, SDL_WINDOW_OPENGL)
    if (is.null(window) || is.nullptr(window)) {
        stop("SDL_CreateWindow failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_DestroyWindow(window), add = TRUE)
    place_sdl_window(window, width)

    context <- sdl$SDL_GL_CreateContext(window)
    if (is.null(context) || is.nullptr(context)) {
        stop("SDL_GL_CreateContext failed: ", sdl$SDL_GetError(), call. = FALSE)
    }
    on.exit(sdl$SDL_GL_DestroyContext(context), add = TRUE)
    sdl$SDL_GL_SetSwapInterval(0L)

    texture <- prepare_gl_texture(width, height)
    on.exit(gl$glDeleteTextures(1L, texture), add = TRUE)

    gl_display_time <- time_value({
        for (i in seq_len(iterations)) {
            render_gl_raster(window, texture, buffer, width, height)
        }
    })

    cat("illustrative demo timing over ", iterations, " iterations:\n", sep = "")
    print_timing("Mandelbrot generation setup", asset$generation_time)
    print_timing("base R image()", base_image_time)
    print_timing("Mandelbrot RGBA buffer", rgba_prepare_time)
    print_timing("SDL3/OpenGL glTexImage2D + quad + swap", gl_display_time)

    event <- raw(128L)
    started <- proc.time()[["elapsed"]]
    duration <- demo_duration()
    repeat {
        while (isTRUE(sdl$SDL_PollEvent(event))) {
            if (unpack(event, 0L, "I") == SDL_EVENT_QUIT) {
                return(invisible(TRUE))
            }
        }
        render_gl_raster(window, texture, buffer, width, height)
        if (proc.time()[["elapsed"]] - started >= duration) {
            return(invisible(TRUE))
        }
        sdl$SDL_Delay(16L)
    }
}

run_sdl_raster_demo()
